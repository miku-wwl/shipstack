output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "aws_region" {
  value = var.aws_region
}

output "source_object_key" {
  value = var.source_object_key
}

output "ecr_repository_name" {
  value = aws_ecr_repository.this.name
}

output "ecr_repository_uri" {
  value = local.ecr_repository_uri
}

output "batch_compute_environment_name" {
  value = local.batch_environment
}

output "batch_job_queue_name" {
  value = aws_batch_job_queue.this.name
}

output "batch_job_definition_name" {
  value = aws_batch_job_definition.this.name
}

output "batch_log_group_name" {
  value = aws_cloudwatch_log_group.batch.name
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}
