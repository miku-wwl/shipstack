output "codebuild_role_arn" { value = aws_iam_role.codebuild.arn }
output "codepipeline_role_arn" { value = aws_iam_role.codepipeline.arn }
output "task_execution_role_arn" { value = aws_iam_role.ecs_execution.arn }
output "task_role_arn" { value = aws_iam_role.ecs_task.arn }
