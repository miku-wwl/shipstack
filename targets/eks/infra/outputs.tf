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

output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "eks_node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "k8s_namespace" {
  value = var.k8s_namespace
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
