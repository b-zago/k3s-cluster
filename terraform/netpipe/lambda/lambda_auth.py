import os
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ.get("TABLE_NAME", "NetpipeUsers"))

def lambda_handler(event, context):
    headers = event.get("headers", {})
    token = headers.get("authorization")

    if not token:
        print("denied: no token")
        return {"isAuthorized": False}

    try:
        response = table.get_item(Key={"AccessKey": token})
    except ClientError as e:
        print(f"denied: dynamodb error: {e}")
        return {"isAuthorized": False}

    if "Item" in response:
        print("allowed")
        return {"isAuthorized": True, "context": {"user": token}}

    print("denied")
    return {"isAuthorized": False}