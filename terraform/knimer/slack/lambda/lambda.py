import urllib3
import json
import boto3
from botocore.exceptions import ClientError
import os

http = urllib3.PoolManager()


def get_slack_webhook_url():
    parameter_name = os.environ["SLACK_WEBHOOK_URL_SECRET_NAME"]
    region_name = os.environ["REGION_NAME"]

    session = boto3.session.Session()
    client = session.client(service_name="ssm", region_name=region_name)

    try:
        get_parameter_response = client.get_parameter(Name=parameter_name, WithDecryption=True)
    except ClientError as e:
        raise e
    else:
        return get_parameter_response["Parameter"]["Value"]


def lambda_handler(event, context):
    url = get_slack_webhook_url()
    task, status = event["task"].split("/")[1], event["status"]
    container_exitcode = event.get("container_exitcode", "")
    exitcode_text = f" (Exit Code: {container_exitcode})" if container_exitcode != "" else ""
    msg = {
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Task*: {task}\n*Status*: {status}{exitcode_text}"
                }
            }
        ]
    }
    encoded_msg = json.dumps(msg).encode("utf-8")
    http.request("POST", url, body=encoded_msg)
