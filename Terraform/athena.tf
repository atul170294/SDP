# Athena workgroup for querying the data
resource "aws_athena_workgroup" "sales" {
  name = "${var.project_name}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/results/"
    }
  }
}

# Example named query to verify the setup works
resource "aws_athena_named_query" "sample_query" {
  name      = "sample-sales-by-country"
  workgroup = aws_athena_workgroup.sales.name
  database  = aws_glue_catalog_database.sales_db.name
  query     = "SELECT Country, COUNT(*) as total_orders, SUM(Total_Revenue) as revenue FROM ${var.glue_table_name} GROUP BY Country ORDER BY revenue DESC LIMIT 10;"
}
