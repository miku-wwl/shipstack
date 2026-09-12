locals {
  name_prefix               = "${var.project_name}-${var.target_name}"
  artifact_bucket_name      = "${local.name_prefix}-artifacts"
  lambda_function_name      = "${local.name_prefix}-function"
  codebuild_name            = "${local.name_prefix}-build"
  codepipeline_name         = "${local.name_prefix}-pipeline"
  lambda_bootstrap_artifact = abspath("${path.module}/../app/target/lambda-function.jar")
}
