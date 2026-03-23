variable "project_name" {
  description = "Project name used for naming resources"
  default     = "sales-data-pipeline"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "eu-west-1"
}

variable "glue_database_name" {
  description = "Name of the Glue database"
  default     = "sales_db"
}

variable "glue_table_name" {
  description = "Name of the Glue table"
  default     = "sales"
}
