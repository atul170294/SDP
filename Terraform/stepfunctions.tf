# Step Functions state machine to orchestrate the pipeline
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Sales data pipeline: fetch & extract, transform, catalog"
    StartAt = "FetcherExtractor"
    States = {
      FetcherExtractor = {
        Type     = "Task"
        Resource = aws_lambda_function.fetcher_extractor.arn
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 30
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        Next = "Transformer"
      }
      Transformer = {
        Type     = "Task"
        Resource = aws_lambda_function.transformer.arn
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 30
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        Next = "Cataloger"
      }
      Cataloger = {
        Type     = "Task"
        Resource = aws_lambda_function.cataloger.arn
        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 30
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        End = true
      }
    }
  })
}
