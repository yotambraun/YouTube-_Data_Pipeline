output "raw_bucket_name" {
  value = aws_s3_bucket.raw_data.id
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed_data.id
}

output "lambda_function_name" {
  value = aws_lambda_function.youtube_collector.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.youtube_collector.arn
}

output "iam_user_arn" {
  value = aws_iam_user.pipeline_user.arn
}

output "iam_user_name" {
  value = aws_iam_user.pipeline_user.name
}