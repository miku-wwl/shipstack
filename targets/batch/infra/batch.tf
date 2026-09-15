resource "aws_batch_compute_environment" "this" {
  compute_environment_name = local.batch_environment
  type                     = "MANAGED"
  state                    = "ENABLED"
  service_role             = aws_iam_role.batch_service.arn

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 4
    subnets            = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.batch.id]
  }

  tags = { Name = "${local.name_prefix}-compute" }

  depends_on = [aws_iam_role_policy.batch_service]
}

resource "aws_batch_job_queue" "this" {
  name     = local.batch_queue
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 0
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

resource "aws_batch_job_definition" "this" {
  name                       = local.batch_job_definition
  type                       = "container"
  platform_capabilities      = ["FARGATE"]
  deregister_on_new_revision = false

  container_properties = jsonencode({
    image = var.bootstrap_image
    resourceRequirements = [
      { type = "VCPU", value = "0.25" },
      { type = "MEMORY", value = "512" }
    ]
    command = ["sh", "-c", "echo bootstrap job definition"]
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }
    executionRoleArn = aws_iam_role.batch_task_execution.arn
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "batch"
      }
    }
  })

  tags = { Name = "${local.name_prefix}-job" }

  depends_on = [aws_iam_role_policy.batch_task_execution]
}
