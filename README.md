# Shipstack

Shipstack 是一个本地优先的 AWS 交付工程学习实验室。项目保留 AWS 概念和 CI/CD 操作的可见性，使用 Terraform 和 AWS 原生 CI/CD 服务；ECS 目标还提供一个仅面向 LocalStack 的 PowerShell 命令，用两个阶段重复执行源码上传和流水线触发流程。

```text
shipstack/
└── targets/
    └── ecs/   # 第一个已实现的交付目标
```

当前 ECS 目标主要面向 **LocalStack Ultimate**，模拟一条包含 Terraform、S3、CodePipeline V1、CodeBuild、ECR、ECS/Fargate、ALB 和 CloudWatch Logs 的小型交付链路。

未来可以在 `targets/ecs/` 旁边增加 EC2、EKS 或 Lambda 等目标。只有在不同目标之间确实出现重复后，才引入共享抽象。

## 仓库原则

- 优先使用 LocalStack Ultimate，同时保留迁移到真实 AWS 的清晰路径。
- Terraform 负责基础设施；操作脚本只保留 ECS 学习流程所需的一个双阶段命令。
- 执行实验室操作时，保留 AWS/LocalStack 原生 CLI 命令的可见性。
- 优先使用直接资源，避免过早引入 Terraform 模块。
- 保持演示业务足够小，让学习重点集中在交付链路上。

请从 [`targets/ecs/README.md`](targets/ecs/README.md) 开始学习。
