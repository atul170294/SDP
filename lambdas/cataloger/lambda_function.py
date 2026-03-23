"""
Lambda 3 - Cataloger
"""
import os
import awswrangler as wr
import boto3

s3 = boto3.client("s3")

GLUE_DATABASE = os.environ["GLUE_DATABASE_NAME"]
GLUE_TABLE = os.environ.get("GLUE_TABLE_NAME", "sales")

def handler(event, context):
    bucket = event["bucket"]
    zip_key = event["zip_key"]
    csv_keys = event.get("csv_keys", [])

    data_path = f"s3://{bucket}/processed/sales/"

    print(f"Registering table {GLUE_DATABASE}.{GLUE_TABLE}")
    wr.catalog.create_parquet_table(
        database=GLUE_DATABASE,
        table=GLUE_TABLE,
        path=data_path,
        columns_types=wr.s3.read_parquet_metadata(path=data_path)[0],
        partitions_types={"Country": "string"},
        mode="overwrite",
        description="2M Sales Records partitioned by Country",
    )

    wr.s3.store_parquet_metadata(
        path=data_path,
        database=GLUE_DATABASE,
        table=GLUE_TABLE,
    )
    print("Glue table and partitions registered")

    file_name = os.path.basename(zip_key)
    archive_key = f"archive/{file_name}"
    s3.copy_object(
        Bucket=bucket,
        CopySource={"Bucket": bucket, "Key": zip_key},
        Key=archive_key,
    )
    s3.delete_object(Bucket=bucket, Key=zip_key)
    print(f"Archived {zip_key} -> {archive_key}")

    for key in csv_keys:
        s3.delete_object(Bucket=bucket, Key=key)
        print(f"Deleted {key}")

    return {
        "message": f"Cataloged {GLUE_DATABASE}.{GLUE_TABLE}, archived raw files",
    }