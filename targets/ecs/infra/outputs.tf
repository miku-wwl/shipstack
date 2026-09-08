output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "source_object_key" {
  value = var.source_object_key
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecr_repository_uri" {
  value = local.ecr_repository_uri
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_task_definition_family" {
  value = module.ecs.task_definition_family
}

output "codebuild_project_name" {
  value = module.codebuild.project_name
}

output "codepipeline_name" {
  value = module.codepipeline.pipeline_name
}

output "log_group_name" {
  value = module.logging.log_group_name
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "alb_endpoint" {
  value = module.alb.endpoint
}
