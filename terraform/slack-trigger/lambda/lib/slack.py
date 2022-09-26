import json
import os
from base64 import b64decode
from urllib.parse import parse_qs
from .slack_signature import SignatureVerifier as SignatureVerifierMixin
import re
import boto3


class SlashException(Exception):
    pass


class Slash(SignatureVerifierMixin):

    def __init__(self, lambda_event, signing_secret):

        try:
            self.body = b64decode(lambda_event["body"]).decode("utf-8")
            self.params = parse_qs(self.body)
        except Exception as e:
            raise SlashException("Could not decode body") from e

        self.headers = {k.lower(): v for k, v in lambda_event["headers"].items()}

        self.timestamp = self.extract_from_headers("timestamp", "x-slack-request-timestamp")
        self.signature = self.extract_from_headers("signature", "x-slack-signature")
        super().__init__(signing_secret=signing_secret)
        self.verify_signature()

        try:
            self.available_tasks = {
                task_arn.split("/")[1]: cluster_arn
                for task_arn, cluster_arn in json.loads(os.environ.get("ECS_TASKS", "{}")).items()
            }
        except json.decoder.JSONDecodeError as e:
            raise SlashException("Could not interpret available tasks") from e

        self.command, self.task, self.cluster_arn = self.process_text(self.params.get("text", [""])[0])

        self.check_channel()

        try:
            self.subnets = os.environ["ECS_SUBNETS"].split(",")
        except KeyError as e:
            raise SlashException("Could not get ECS subnets") from e

    @property
    def task_list(self):
        return list(self.available_tasks.keys())

    def run(self):
        region_name = os.environ.get("REGION_NAME", "eu-west-2")
        client = boto3.client("ecs", region_name=region_name)
        response = client.run_task(
            cluster=self.cluster_arn,
            count=1,
            launchType="FARGATE",
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": self.subnets,
                    # TODO: Consider adding SG and IP configuration
                    # "securityGroups": [],
                    # "assignPublicIp": "DISABLED",
                }
            },
            platformVersion="LATEST",
            startedBy="knimer",
            taskDefinition=self.task,
        )
        tasks = [
            task["taskArn"]
            for task in response.get("tasks", [])
        ]
        failures = [
            f"{failure['reason'] - failure['detail']}"
            for failure in response.get("failures", [])
        ]
        return tasks, failures

    def extract_from_headers(self, name, header_name):
        try:
            return self.headers[header_name.lower()]
        except KeyError as e:
            raise SlashException(f"Could not extract {name} from request") from e

    def process_text(self, text):

        run_regex = r"(?P<command>run) (?P<task>[A-z-_]+:\d)"
        list_regex = r"list"

        run_matches = re.search(run_regex, text)
        if run_matches:
            group_dict = run_matches.groupdict()
            command, task = group_dict["command"], group_dict["task"]
            try:
                cluster_arn = self.available_tasks[task]
            except KeyError as e:
                raise SlashException("Could not determine cluster for task") from e
            return command, task, cluster_arn

        list_matches = re.search(list_regex, text)
        if list_matches:
            return "list", "", ""

        raise SlashException("Command is not valid")

    def verify_signature(self):
        if not self.is_valid(self.body, self.timestamp, self.signature):
            raise SlashException("Invalid signature!")

    def check_channel(self):
        channel_restriction = os.environ.get("SLACK_CHANNEL_RESTRICTION")
        channel = self.params.get("channel_name")[0]
        if channel_restriction and channel != channel_restriction:
            raise SlashException("This slash command is not allowed in this channel!")
