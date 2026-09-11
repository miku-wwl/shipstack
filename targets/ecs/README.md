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

- Docker Desktop 正在运行，并支持 Docker Compose
- Java 21（应用使用 Java 17 也可以）
- Maven、Terraform 和 AWS CLI 已加入 PATH
- LocalStack Pro/Ultimate 运行镜像的授权令牌只存在于本地环境变量中

命令使用测试凭证和显式的 LocalStack endpoint，不会调用真实 AWS。项目 LocalStack
由 [`docker-compose.localstack.yml`](docker-compose.localstack.yml) 管理；不会修改
已有的 `localstack-main` 容器。

## 运行

完整的启动、Terraform、bootstrap image、source artifact、CodePipeline、ECS/ALB/
CloudWatch 验证以及 rollback 命令，统一见
[`docs/operations-runbook.md`](docs/operations-runbook.md)。Runbook 中的命令必须
直接使用 Docker Compose、Terraform、Maven、Docker 和 AWS CLI；本目录不再提供
Makefile、PowerShell/Bash wrapper 或 helper automation script。

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
