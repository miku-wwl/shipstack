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

## 当前网络选择

当前 LocalStack 学习环境只创建 public subnets。ALB 使用 public subnets，ECS/Fargate
tasks 也使用 public subnets 并分配 public IP；这让 LocalStack 中的 ALB、任务和容器
网络路径保持可观察且简单。未使用的 private subnets 和 NAT Gateway 不会被提前创建。
真实 AWS 环境需要重新设计为 public ALB、private ECS tasks，并验证 NAT Gateway 或
VPC endpoints。

## 所有权边界

- Terraform：网络、安全组、IAM、ECR、ECS cluster/service、ALB、日志组、CodeBuild、
  CodePipeline 和 bootstrap task definition。
- CodePipeline ECS deploy action：发布时注册的 task definition revision、应用镜像和
  active release。

ECS service 对 `task_definition` 的 `lifecycle.ignore_changes` 是这个边界的实现方式，
不是忽略部署状态的捷径。

## IAM 边界

CodeBuild、CodePipeline、ECS execution role 和 ECS task role 各自使用对应 service
principal 的 trust policy。ECS execution role 只负责拉取 ECR 镜像和写入日志；当前
Spring Boot 应用不访问 AWS，因此 task role 暂无权限策略。
