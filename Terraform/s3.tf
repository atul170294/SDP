# S3 bucket for raw, processed, and archived data
resource "aws_s3_bucket" "data_lake" {
  bucket        = local.bucket_name
  force_destroy = true # For easy cleanup during development
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Athena query results bucket
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${local.bucket_name}-athena-results"
  force_destroy = true
}
