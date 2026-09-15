output "aws_region" {
  value = var.aws_region
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "source_object_key" {
  value = var.source_object_key
}

output "eb_application_name" {
  value = aws_elastic_beanstalk_application.this.name
}

output "eb_environment_name" {
  value = local.eb_environment_name
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}

output "codebuild_log_group_name" {
  value = aws_cloudwatch_log_group.codebuild.name
}
