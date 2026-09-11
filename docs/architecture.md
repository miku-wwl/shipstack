# Shipstack 架构

Shipstack 是一个面向多种部署目标的交付平台学习工作区。每种部署技术都在
`targets/` 下拥有一个自包含的目标目录。

首个目标是 `targets/ecs/`，其流程如下：

```text
本地源代码压缩包 -> CodePipeline V1 -> CodeBuild -> ECR
                                      -> ECS 标准部署
ECS/Fargate -> ALB -> HTTP
应用标准输出 -> awslogs -> CloudWatch Logs
```

根目录不包含 ECS 的具体实现细节，只负责提供导航和仓库级约定；运行命令集中在
ECS target 的中文 Runbook 中，并直接使用 Docker Compose、Terraform 和 AWS CLI。
