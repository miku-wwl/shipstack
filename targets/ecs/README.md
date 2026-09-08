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

- LocalStack Ultimate 运行在 `http://localhost:4566`
- Docker Desktop 正在运行
- Java 21（应用使用 Java 17 也可以）
- Maven 和 Terraform 已加入 PATH
- AWS CLI 已加入 PATH

命令使用测试凭证和显式的 LocalStack endpoint，不会调用真实 AWS。现有 LocalStack
容器会被复用；本目标不会重启或重新配置它。

## 运行

在当前目录运行：

```powershell
make test
make terraform-fmt
make terraform-validate
make local-e2e
make rollback
```

在仓库根目录运行：

```powershell
make ecs-test
make ecs-local-e2e
make ecs-rollback
```

完整 E2E 会运行 Release 1（`v1`）、Release 2（`v2`），执行 HTTP 和日志检查，
然后回滚到上一个健康的 ECS task-definition revision。

## Qualification 边界

只有在 infrastructure、两次 pipeline execution、ECR、ECS 稳定性、ALB HTTP 响应、
CloudWatch Logs 和 rollback check 全部通过后，才会报告 `LOCALSTACK_QUALIFIED`。
LocalStack 的 IAM enforcement setting 单独报告，因为它属于已有 LocalStack 进程的
属性。

可通过 [`docs/aws-migration.md`](docs/aws-migration.md) 了解可移植性边界，通过
[`docs/deployment-lifecycle.md`](docs/deployment-lifecycle.md) 了解 release 和
rollback 语义。本地 provider 和 LocalStack 边界见
[`infra/environments/local/README.md`](infra/environments/local/README.md)。
