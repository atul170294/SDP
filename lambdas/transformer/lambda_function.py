"""
Lambda 2 - Transformer
"""
import awswrangler as wr

def handler(event, context):
    bucket = event["bucket"]
    csv_keys = event["csv_keys"]

    for csv_key in csv_keys:
        s3_path = "s3://" + bucket + "/" + csv_key
        output_path = "s3://" + bucket + "/processed/sales/"

        print("Reading " + s3_path)
        df = wr.s3.read_csv(path=s3_path)
        print(f"Loaded {len(df)} rows, {len(df.columns)} columns")

        df.columns = [col.strip().replace(" ", "_") for col in df.columns]

        print(f"Writing partitioned parquet to {output_path}")
        wr.s3.to_parquet(
            df=df,
            path=output_path,
            dataset=True,
            partition_cols=["Country"],
        )
        print("Parquet write complete")

    return {"bucket": bucket, "zip_key": event["zip_key"], "csv_keys": csv_keys}
