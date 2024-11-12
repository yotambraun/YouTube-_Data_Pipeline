# S3 Buckets
resource "aws_s3_bucket" "raw_data" {
  bucket = "${var.project_name}-raw-data-${var.environment}"
}

resource "aws_s3_bucket" "processed_data" {
  bucket = "${var.project_name}-processed-data-${var.environment}"
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "youtube_db" {
  name = "${var.project_name}_db_${var.environment}"
}

# Glue Crawler
resource "aws_glue_crawler" "raw_data_crawler" {
  database_name = aws_glue_catalog_database.youtube_db.name
  name          = "${var.project_name}-crawler-${var.environment}"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.raw_data.id}/raw/videos"
  }

  schedule = "cron(0 */6 * * ? *)"
}

# Glue Job
resource "aws_glue_job" "transform_job" {
  name              = "${var.project_name}-transform-${var.environment}"
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${aws_s3_bucket.raw_data.id}/scripts/transform_data.py"
    python_version  = "3"
  }
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-pipeline-${var.environment}"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    StartAt = "CollectYouTubeData"
    States = {
      CollectYouTubeData = {
        Type     = "Task"
        Resource = aws_lambda_function.youtube_collector.arn
        Next     = "StartGlueJob"
      }
      StartGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.transform_job.name
        }
        End = true
      }
    }
  })
}

# Lambda Function
resource "aws_lambda_function" "youtube_collector" {
  filename         = ""C:\\Users\\yotam\\code_projects\\YouTube_Data_Pipeline\\src\\lambda\\youtube_collector\\lambda_function.zip"
  function_name    = "${var.project_name}-youtube-collector-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 512
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM User
resource "aws_iam_user" "pipeline_user" {
  name = "${var.project_name}-pipeline-user-${var.environment}"
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "pipeline_schedule" {
  name                = "${var.project_name}-schedule-${var.environment}"
  description         = "Trigger the YouTube pipeline"
  schedule_expression = "rate(6 hours)"
}

resource "aws_cloudwatch_event_target" "pipeline_target" {
  rule      = aws_cloudwatch_event_rule.pipeline_schedule.name
  target_id = "TriggerPipeline"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# IAM Roles (Add Glue and Step Functions roles)
resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-glue-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-stepfunctions-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-eventbridge-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}