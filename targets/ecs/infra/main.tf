module "network" {
  source = "./modules/network"

  name_prefix        = local.name_prefix
  availability_zones = var.availability_zones
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix     = local.name_prefix
  repository_name = local.ecr_repository
}

module "logging" {
  source = "./modules/logging"

  log_group_name = local.log_group_name
}

module "iam" {
  source = "./modules/iam"

  name_prefix             = local.name_prefix
  aws_region              = var.aws_region
  account_id              = data.aws_caller_identity.current.account_id
  artifact_bucket_arn     = aws_s3_bucket.artifacts.arn
  codebuild_project_arn   = "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/${local.codebuild_name}"
  ecr_repository_arn      = module.ecr.repository_arn
  log_group_arn           = module.logging.log_group_arn
  task_execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name_prefix}-ecs-task-execution"
  task_role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name_prefix}-ecs-task"
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix             = local.name_prefix
  cluster_name            = local.ecs_cluster_name
  service_name            = local.ecs_service_name
  task_family             = "${local.name_prefix}-task"
  image                   = local.bootstrap_image
  container_name          = "ecs-platform-demo"
  desired_count           = var.desired_count
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
  log_group_name          = module.logging.log_group_name
  aws_region              = var.aws_region
  target_group_arn        = module.alb.target_group_arn
  task_subnet_ids         = module.network.public_subnet_ids
  task_security_group_id  = module.network.ecs_security_group_id
}

module "alb" {
  source = "./modules/alb"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name_prefix}-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

module "codebuild" {
  source = "./modules/codebuild"

  name_prefix        = local.name_prefix
  project_name       = local.codebuild_name
  service_role_arn   = module.iam.codebuild_role_arn
  aws_region         = var.aws_region
  codebuild_image    = var.codebuild_image
  ecr_repository     = local.ecr_repository
  ecr_repository_uri = local.ecr_repository_uri
  environment_variables = var.codebuild_aws_endpoint == null ? {} : {
    AWS_ENDPOINT_URL = var.codebuild_aws_endpoint
  }
}

module "codepipeline" {
  source = "./modules/codepipeline"

  name_prefix            = local.name_prefix
  pipeline_name          = local.codepipeline_name
  pipeline_role_arn      = module.iam.codepipeline_role_arn
  artifact_bucket_name   = aws_s3_bucket.artifacts.id
  codebuild_project_name = module.codebuild.project_name
  cluster_name           = module.ecs.cluster_name
  service_name           = module.ecs.service_name
  source_object_key      = var.source_object_key
}
