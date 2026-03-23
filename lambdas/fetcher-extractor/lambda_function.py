"""
Lambda 1 - Fetcher & Extractor
"""
import os
import shutil
import zipfile
import urllib.request
import boto3

s3 = boto3.client("s3")
BUCKET = os.environ["BUCKET_NAME"]

def handler(event, context):
    url = event.get("source_url","https://eforexcel.com/wp/wp-content/uploads/2020/09/2m-Sales-Records.zip")

    file_name = url.split("/")[-1]
    local_path = "/tmp/" + file_name
    extract_dir = "/tmp/extracted"

    urllib.request.urlretrieve(url, local_path)

    zip_key = "raw/" + file_name
    s3.upload_file(local_path, BUCKET, zip_key)
    print(f"Uploaded to s3://{BUCKET}/{zip_key}")

    os.makedirs(extract_dir, exist_ok=True)
    with zipfile.ZipFile(local_path, "r") as zf:
        zf.extractall(extract_dir)
    print(f"Extracted files: {os.listdir(extract_dir)}")

    os.remove(local_path)

    csv_keys = []
    for name in os.listdir(extract_dir):
        if name.endswith(".csv"):
            csv_key = f"raw/{name}"
            s3.upload_file(f"{extract_dir}/{name}", BUCKET, csv_key)
            csv_keys.append(csv_key)
            print("Uploaded s3://" + BUCKET + "/" + csv_key)

    shutil.rmtree(extract_dir)
    return {"bucket": BUCKET, "zip_key": zip_key, "csv_keys": csv_keys}
