locals {
  name_prefix          = "${var.project_name}-${var.target_name}"
  artifact_bucket_name = "${local.name_prefix}-artifacts"
  ecr_repository       = "${local.name_prefix}-demo"
  batch_environment    = "${local.name_prefix}-compute"
  batch_queue          = "${local.name_prefix}-queue"
  batch_job_definition = "${local.name_prefix}-job"
  codebuild_name       = "${local.name_prefix}-build"
  codepipeline_name    = "${local.name_prefix}-pipeline"
  batch_log_group_name = "/aws/batch/${local.name_prefix}"
  codebuild_log_group  = "/aws/codebuild/${local.name_prefix}"

  # LocalStack 的 ECR API 可能返回 4566，而 Docker registry 使用另一个
  # 对外端口；真实 AWS 中这个替换不会改变 URI。
  ecr_repository_uri = replace(aws_ecr_repository.this.repository_url, ":4566/", ":${var.ecr_registry_port}/")
}
