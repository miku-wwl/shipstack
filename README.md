# Shipstack

Shipstack 是一个本地优先的 AWS 交付工程学习实验室。项目保留 AWS 概念和 CI/CD 操作的可见性，使用 Terraform 和 AWS 原生 CI/CD 服务；ECS、EC2、EKS、Elastic Beanstalk 和 Lambda 目标都面向外部提供的 LocalStack Ultimate/Pro 环境。

```text
shipstack/
└── targets/
    ├── ecs/      # ECS 容器镜像交付目标
    ├── ec2/      # EC2 主机与进程交付目标
    ├── eks/      # EKS Kubernetes 镜像交付目标
    ├── beanstalk/  # Elastic Beanstalk 应用平台交付目标
    ├── lambda/   # Lambda 部署包交付目标
    └── batch/    # AWS Batch 一次性 Job 交付目标
```

当前 ECS、EC2、EKS、Elastic Beanstalk、Lambda 和 AWS Batch 目标主要面向 **LocalStack Ultimate**，分别学习长期容器服务、EC2 主机 JAR、Kubernetes 镜像、托管应用平台版本、Lambda 部署包和一次性批处理 Job 六种交付模型。目标都使用传统的 CodePipeline V1 -> CodeBuild 学习路径；EC2 目标在 CodeBuild 中显式使用 SSM 完成主机部署，EKS 目标在 CodeBuild 中显式使用 kubectl 完成 Kubernetes 部署，Beanstalk 目标在 CodeBuild 中显式调用 Elastic Beanstalk API 完成版本发布与环境更新，Batch 目标在 CodeBuild 中显式注册 Job Definition、提交 Job 并校验 Job 日志。

只有在不同目标之间确实出现重复后，才引入共享抽象。

## 仓库原则

- 优先使用 LocalStack Ultimate，同时保留迁移到真实 AWS 的清晰路径。
- Terraform 负责基础设施；保持每个目标的操作命令显式，不为方便操作额外套编排层。
- 执行实验室操作时，保留 AWS/LocalStack 原生 CLI 命令的可见性。
- 优先使用直接资源，避免过早引入 Terraform 模块。
- 保持演示业务足够小，让学习重点集中在交付链路上。

建议先阅读 [`targets/ecs/README.md`](targets/ecs/README.md) 了解长期容器服务，再阅读 [`targets/eks/README.md`](targets/eks/README.md) 对比 Kubernetes 的 Deployment、Pod 和 Service，然后阅读 [`targets/ec2/README.md`](targets/ec2/README.md) 观察主机与进程细节，接着阅读 [`targets/beanstalk/README.md`](targets/beanstalk/README.md) 理解 PaaS 的应用版本与环境，再阅读 [`targets/lambda/README.md`](targets/lambda/README.md) 比较函数部署包交付，最后阅读 [`targets/batch/README.md`](targets/batch/README.md) 学习异步 Job、队列和计算环境。

## 目标对比

| 目标 | 运行对象 | CodePipeline V1 的部署动作 | 运行时抽象 |
| --- | --- | --- | --- |
| ECS | ECR 镜像 | ECS Deploy Action 更新 ECS Service | ECS Service / Fargate Task |
| EKS | ECR 镜像 | CodeBuild 执行 `kubectl apply` 与 rollout | Kubernetes Deployment / Pod / Service |
| EC2 | S3 中的 JAR | CodeBuild 通过 SSM 部署进程 | EC2 实例 / Java 进程 |
| Elastic Beanstalk | S3 中的应用 bundle | CodeBuild 调用 EB API 创建 Application Version、更新 Environment | 托管应用平台 / PaaS；LocalStack 只验证控制面 |
| Lambda | S3 中的 JAR | CodeBuild 执行 Lambda 更新 API | Lambda Function |
| Batch | ECR 镜像 | CodeBuild 注册 Job Definition、提交 Job 并校验日志 | Job Queue / Fargate Compute Environment / 一次性 Job |
