output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
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

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_task_definition_family" {
  value = aws_ecs_task_definition.this.family
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_endpoint" {
  value = "http://${aws_lb.this.dns_name}"
}
