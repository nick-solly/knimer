import json
import urllib3
import logging

from botocore.exceptions import ClientError
from lib.fetch_secret import fetch_secret
from lib.slack import Slash, SlashException

http = urllib3.PoolManager()
logger = logging.getLogger()
logger.setLevel(logging.INFO)
# TODO: Add more logging statements


def lambda_handler(event, context):
    try:
        slash = Slash(
            lambda_event=event,
            signing_secret=fetch_secret("SLACK_SIGNING_SECRET_NAME"),
        )
        if slash.command == "run":
            tasks, failures = slash.run()
            text = f":white_check_mark: Tasks Started: {', '.join(tasks)}"
            if failures:
                text += f"\n:x: Failures: {', '.join(failures)}"
        elif slash.command == "list":
            bulleted_tasks = '\n- '.join(slash.task_list) or "NONE"
            text = f":page_with_curl: Available Tasks: \n- {bulleted_tasks}"
    except SlashException as e:
        text = f":x: {e}"
    except ClientError as e:
        if e.response["Error"]["Code"] == "AccessDeniedException":
            text = f":x: Permission denied to run this task"
        else:
            logger.error(repr(e))
            text = f":x: AWS error"
    except Exception as e:
        logger.error(repr(e))
        text = f":x: Unknown Error"
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(
            {
                "response_type": "in_channel",
                "text": text,
            }
        )
    }
