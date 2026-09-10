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

Docker 必须可用。运行目标脚本时，它会复用已有 LocalStack 镜像并启动或使用项目专用
的 `shipstack-ecs-localstack` 容器，宿主机 endpoint 为 `http://localhost:4567`；脚本
会显式指定该 endpoint，不会调用真实 AWS。

```powershell
make ecs-test
make ecs-local-e2e
make ecs-rollback
```

目标相关的文档、脚本和 Terraform 全部位于 [`targets/ecs/`](targets/ecs/README.md)
下。根目录 Makefile 只提供仓库级委托命令。
