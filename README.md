# Shipstack

Shipstack 是一个以本地优先为原则的 AWS 交付平台，用于通过 Terraform 和原生
CI/CD 服务构建、部署、验证和运行云原生应用。

本仓库以部署目标为组织单位：

```text
shipstack/
└── targets/
    └── ecs/   # 首个已实现的部署目标
```

当前目标是一个完整的 ECS 应用 CI/CD 实验，使用 LocalStack Ultimate、Terraform、
CodePipeline V1、CodeBuild、ECR、ECS/Fargate、ALB 和 CloudWatch Logs。未来的
EKS 或 Lambda 等部署目标将作为 `targets/` 下的并列目录添加；当前仓库状态尚未
实现这些目标。

## 快速开始

Docker、Docker Compose、Java 21、Maven、Terraform 和 AWS CLI 必须可用。
ECS 目标通过项目级 Docker Compose 管理 `shipstack-ecs-localstack`，宿主机 endpoint
为 `http://localhost:4567`；Terraform 和 AWS CLI 的 LocalStack endpoint 都由当前
终端显式设置，不会调用真实 AWS。

完整的学习和操作命令见
[`targets/ecs/docs/operations-runbook.md`](targets/ecs/docs/operations-runbook.md)。
其中每条命令都直接调用 Docker Compose、Terraform、Maven、Docker 或 AWS CLI；仓库
不提供 Makefile、PowerShell/Bash 包装脚本或其他 orchestration helper。

目标相关的文档、Docker Compose 配置和 Terraform 全部位于
[`targets/ecs/`](targets/ecs/README.md) 下。
