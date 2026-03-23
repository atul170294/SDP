# Glue database to hold our table metadata
resource "aws_glue_catalog_database" "sales_db" {
  name = var.glue_database_name

  description = "Database for sales records data lake"
}
