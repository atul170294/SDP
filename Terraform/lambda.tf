# --- Data source for AWS SDK for pandas Lambda Layer ---
# This managed layer includes pandas, pyarrow, and awswrangler
data "aws_lambda_layer_version" "awswrangler" {
  layer_name = "AWSSDKPandas-Python312"
}

# --- Package Lambda code ---
data "archive_file" "fetcher_extractor" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/fetcher_extractor"
  output_path = "${path.module}/../.build/fetcher_extractor.zip"
}

data "archive_file" "transformer" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/transformer"
  output_path = "${path.module}/../.build/transformer.zip"
}

data "archive_file" "cataloger" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/cataloger"
  output_path = "${path.module}/../.build/cataloger.zip"
}

# --- Lambda Functions ---

# Lambda 1: Fetcher & Extractor - downloads ZIP from URL, extracts CSVs, uploads to S3
resource "aws_lambda_function" "fetcher_extractor" {
  function_name    = "${var.project_name}-fetcher-extractor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 300 # 5 minutes
  memory_size      = 1024
  filename         = data.archive_file.fetcher_extractor.output_path
  source_code_hash = data.archive_file.fetcher_extractor.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_lake.id
    }
  }
}

# Lambda 2: Transformer - converts CSV to partitioned Parquet
resource "aws_lambda_function" "transformer" {
  function_name    = "${var.project_name}-transformer"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 900 # 15 minutes (max)
  memory_size      = 3072 # 3 GB for processing 2M rows
  filename         = data.archive_file.transformer.output_path
  source_code_hash = data.archive_file.transformer.output_base64sha256
  layers           = [data.aws_lambda_layer_version.awswrangler.arn]

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_lake.id
    }
  }
}

# Lambda 3: Cataloger - registers in Glue and archives raw files
resource "aws_lambda_function" "cataloger" {
  function_name    = "${var.project_name}-cataloger"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512
  filename         = data.archive_file.cataloger.output_path
  source_code_hash = data.archive_file.cataloger.output_base64sha256
  layers           = [data.aws_lambda_layer_version.awswrangler.arn]

  environment {
    variables = {
      GLUE_DATABASE_NAME = var.glue_database_name
      GLUE_TABLE_NAME    = var.glue_table_name
    }
  }
}
