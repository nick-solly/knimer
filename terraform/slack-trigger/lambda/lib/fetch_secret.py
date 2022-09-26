import boto3
from botocore.exceptions import ClientError
import os


def fetch_secret(arn_env_var):
    secret_arn = os.environ[arn_env_var]
    region_name = os.environ.get("REGION_NAME", "eu-west-2")

    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
    except ClientError as e:
        raise e
    else:
        return get_secret_value_response["SecretString"]
