# Shipstack ECS 目标

这是 Shipstack 的首个部署目标，是一个基于 LocalStack Ultimate 的 AWS ECS 应用
CI/CD 可运行系统实验。

## 流程

```text
S3 中的 source zip -> CodePipeline V1 -> CodeBuild
                     Maven test/package -> Docker build/push -> ECR
                     ECS standard deploy -> task-definition revision -> ECS service
                     ECS/Fargate -> ALB -> HTTP
Spring Boot stdout -> awslogs -> CloudWatch Logs
```

本地 source 使用确定性的 S3 zip，因此 qualification 不需要交互式 GitHub 授权。迁移
到真实 AWS 时，只需将 source action 替换为 GitHub CodeConnections。

## 前置条件

- Docker 可用；LocalStack Ultimate 已由外部环境启动
- Java 21（应用使用 Java 17 也可以）
- Maven、Terraform 和 AWS CLI 已加入 PATH

命令使用测试凭证和显式的外部 LocalStack endpoint，不会调用真实 AWS。本仓库不
创建或重启 LocalStack，也不保存 `LOCALSTACK_AUTH_TOKEN`。

## 运行

Terraform root module、业务应用和 CodeBuild buildspec 是本目标的核心内容。LocalStack
endpoint、AWS 测试凭证和可选的 CodeBuild endpoint 由外部环境提供；本目录不提供
LocalStack Compose 文件、Makefile、PowerShell/Bash wrapper 或 helper automation script。

直接操作时，在外部 LocalStack 已就绪后设置 `TF_VAR_aws_api_endpoint`、
`TF_VAR_codebuild_aws_endpoint` 和 AWS CLI endpoint，再执行：

```powershell
terraform -chdir=infra init -input=false
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra validate
terraform -chdir=infra plan
```

完整 E2E 会运行初始 release（默认 `v1`）、候选 release（默认 `v2`），执行 HTTP 和
日志检查，将初始 release 记录为 last-known-good，然后回滚到记录中的 task definition。
它不会假设“当前 revision 减一”就是正确的回滚目标。

## Qualification 边界

只有在 infrastructure、两次 pipeline execution、ECR、ECS 稳定性、ALB HTTP 响应、
CloudWatch Logs 和 rollback check 全部通过后，才会报告 `LOCALSTACK_QUALIFIED`。
LocalStack 的 IAM enforcement setting 单独报告，因为它属于已有 LocalStack 进程的
属性。

可通过 [`docs/aws-migration.md`](docs/aws-migration.md) 了解可移植性边界，通过
[`docs/deployment-lifecycle.md`](docs/deployment-lifecycle.md) 了解 release 和
rollback 语义。本地 provider 和 LocalStack 边界见
[`infra/environments/local/README.md`](infra/environments/local/README.md)。
