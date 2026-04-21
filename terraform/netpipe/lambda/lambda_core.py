import boto3
import json
import os

s3 = boto3.client("s3")
BUCKET = "netpipe-bucket"

def lambda_handler(event, context):
    print(event)

    route = event["routeKey"]
    headers = event.get("headers", {})
    folder_name = headers.get("folder-name")
    file_name = headers.get("file-name")

    if not folder_name:
        return _resp(400, {"message": "Missing folder-name header"})

    folder_name = os.path.basename(folder_name)

    if route == "GET /list":
        return listFiles(folder_name)

    if not file_name:
        return _resp(400, {"message": "Missing file-name header"})

    file_name = os.path.basename(file_name)
    key = f"{folder_name}/{file_name}"
    
    if route == "PUT /send":
        return sendFile(key)
    elif route == "GET /file":
        return getFile(key)
    

    return _resp(404, {"message": "How?"})

def sendFile(key):
    upload_url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": BUCKET,
            "Key": key,
        },
        ExpiresIn=300,
    )
    return _resp(200, {"upload_url": upload_url})

def getFile(key):
    download_url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": BUCKET, "Key": key},
        ExpiresIn=300,
    )
    return _resp(200, {"download_url": download_url})

def listFiles(folder_name):
    resp = s3.list_objects_v2(
        Bucket=BUCKET,
        Prefix=f"{folder_name}/",
    )
    files = [
        {"key": obj["Key"], "size": obj["Size"], "modified": obj["LastModified"].isoformat()}
        for obj in resp.get("Contents", [])
    ]
    return _resp(200, {"files": files})

def _resp(status, body):
    return {"statusCode": status, "body": json.dumps(body)}