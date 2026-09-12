output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "aws_region" {
  value = var.aws_region
}

output "source_object_key" {
  value = var.source_object_key
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "codebuild_log_group_name" {
  value = aws_cloudwatch_log_group.codebuild.name
}
