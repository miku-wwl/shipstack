# ECS 目标架构

ECS 目标模拟标准的 AWS 交付路径，同时使用 LocalStack 作为本地 endpoint：

```text
S3 本地源代码制品
  -> CodePipeline V1 Source
  -> CodeBuild（Maven test/package、Docker build/push）
  -> ECR
  -> ECS 标准 Deploy action
  -> 新的 task-definition revision
  -> ECS Fargate service
  -> ALB target group and listener
  -> HTTP
```

Terraform root 组合了 network、ECR、IAM、logging、ECS、ALB、CodeBuild 和
CodePipeline 模块。资源名称统一使用 `shipstack-ecs-` 前缀，以便未来目标能够
与其共存。
