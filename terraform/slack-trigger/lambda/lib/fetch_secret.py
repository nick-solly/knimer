import boto3
from botocore.exceptions import ClientError
import os


def fetch_secret(parameter_env_var):
    parameter_name = os.environ[parameter_env_var]
    region_name = os.environ.get("REGION_NAME", "eu-west-2")

    session = boto3.session.Session()
    client = session.client(service_name="ssm", region_name=region_name)

    try:
        get_parameter_response = client.get_parameter(Name=parameter_name, WithDecryption=True)
    except ClientError as e:
        raise e
    else:
        return get_parameter_response["Parameter"]["Value"]
