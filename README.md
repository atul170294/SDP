# SDP
# Sales Data Pipeline

A serverless pipeline on AWS that picks up a 2M-row sales dataset (ZIP from an external URL), converts it to Parquet, partitions it by Country, and makes it queryable through Athena. The whole thing is orchestrated with Step Functions and deployed via Terraform.

## How it works

A Step Functions state machine runs three Lambda functions in sequence:

- **Fetcher/Extractor** — grabs the ZIP file from the source URL, extracts the CSV(s), and drops everything into the raw/ prefix in S3.
- **Transformer** — reads the CSV, cleans up column names, converts to Parquet partitioned by Country, and writes it to processed/sales/ in S3. This one needs 3 GB of memory and up to 15 minutes since it's handling 2M rows.
- **Cataloger** — registers the Parquet dataset in the Glue Catalog so Athena can see it, then moves the original raw files over to archive/.

The Transformer and Cataloger both use the managed AWS SDK for pandas Lambda Layer (awswrangler).

## S3 structure

Everything lives in a single bucket:

- raw/ — where the ZIP and CSV land initially (temporary)
- processed/sales/ — partitioned Parquet files (Country=France/, Country=Germany/, etc.)
- archive/ — original files get moved here once processing is done

There's also a separate bucket for Athena query results.

## Infrastructure

All provisioned through Terraform. The main pieces:

- 3 Lambda functions 
- Step Functions state machine with retry logic (2 attempts, exponential backoff)
- S3 buckets with public access blocked
- Glue database and catalog registration
- Athena workgroup with a sample named query
- IAM roles for Lambda (S3 + Glue + CloudWatch) and Step Functions (Lambda invoke)

Region is set to eu-west-1 by default.

## Prerequisites

- AWS CLI configured with the right credentials
- Terraform >= 1.0

## Deploy

```bash
cd terraform
terraform init
terraform apply
```

## Run the pipeline

```bash
aws stepfunctions start-execution \
  --state-machine-arn $(terraform -chdir=terraform output -raw state_machine_arn) \
  --input '{}'
```

## Query with Athena

Once the pipeline finishes, you can query the data through the Athena console or CLI:

```sql
SELECT Country, COUNT(*) as total_orders, SUM(Total_Revenue) as revenue
FROM sales
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;
```

## Cleanup

```bash
cd terraform
terraform destroy
```
