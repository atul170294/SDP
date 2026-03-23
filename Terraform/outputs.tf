output "bucket_name" {
  value = aws_s3_bucket.data_lake.id
}

output "glue_database" {
  value = aws_glue_catalog_database.sales_db.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.sales.name
}

output "state_machine_arn" {
  value       = aws_sfn_state_machine.pipeline.arn
  description = "Start the pipeline by executing this state machine"
}
