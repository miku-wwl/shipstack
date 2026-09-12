# Shipstack

Shipstack 是一个本地优先的 AWS 交付工程学习实验室。项目保留 AWS 概念和 CI/CD 操作的可见性，使用 Terraform 和 AWS 原生 CI/CD 服务；ECS 和 Lambda 目标都提供仅面向 LocalStack 的 PowerShell 双阶段命令，用于重复执行源码上传和流水线触发流程。

```text
shipstack/
└── targets/
    ├── ecs/      # ECS 容器镜像交付目标
    └── lambda/   # Lambda 部署包交付目标
```

当前 ECS 和 Lambda 目标主要面向 **LocalStack Ultimate**，分别模拟容器镜像交付和 Lambda 部署包交付。两个目标都使用传统的 CodePipeline V1 -> CodeBuild 学习路径。

未来可以在 `targets/ecs/` 旁边增加 EC2、EKS 或 Lambda 等目标。只有在不同目标之间确实出现重复后，才引入共享抽象。

## 仓库原则

- 优先使用 LocalStack Ultimate，同时保留迁移到真实 AWS 的清晰路径。
- Terraform 负责基础设施；操作脚本只保留每个目标各自所需的一个双阶段命令。
- 执行实验室操作时，保留 AWS/LocalStack 原生 CLI 命令的可见性。
- 优先使用直接资源，避免过早引入 Terraform 模块。
- 保持演示业务足够小，让学习重点集中在交付链路上。

建议先阅读 [`targets/ecs/README.md`](targets/ecs/README.md)，再阅读 [`targets/lambda/README.md`](targets/lambda/README.md)，比较容器镜像和 Lambda 部署包两种交付模型。
