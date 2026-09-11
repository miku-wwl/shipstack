# Shipstack CodePipeline 学习路径

这是一条从整体结构到运行验证、再到 AWS 迁移的渐进式学习路径。建议按顺序
阅读，并在每一阶段结合对应的代码、Terraform、Docker Compose 和 AWS CLI 命令进行观察。

## 学习顺序

### 01 - 仓库入口

阅读：[`README.md`](../README.md)

目标：了解 Shipstack 的定位、当前实现的 ECS 目标、LocalStack 运行前提和操作
Runbook 入口。

### 02 - 仓库整体架构

阅读：[`architecture.md`](architecture.md)

目标：理解多目标仓库结构，以及 source zip、CodePipeline、CodeBuild、ECR、ECS、
ALB 和 CloudWatch Logs 之间的关系。

### 03 - 目标目录约定

阅读：[`target-conventions.md`](target-conventions.md)

目标：理解为什么部署目标放在 `targets/<name>/`，以及资源命名、LocalStack 隔离和
共享代码的边界。

### 04 - ECS 目标入口

阅读：[`../targets/ecs/README.md`](../targets/ecs/README.md)

目标：掌握 ECS 目标的前置条件、Runbook 命令、完整 E2E 和 qualification 边界。

### 05 - ECS 交付架构

阅读：[`../targets/ecs/docs/architecture.md`](../targets/ecs/docs/architecture.md)

目标：沿着 S3 source artifact 到 CodePipeline、CodeBuild、ECR、ECS/Fargate、ALB
的路径理解一次发布如何流动。

### 06 - ECS 核心概念

阅读：[`../targets/ecs/docs/ecs-concepts.md`](../targets/ecs/docs/ecs-concepts.md)

目标：理解 cluster、task definition、task、service、desired count、Fargate 和
IAM role 在本项目中的具体含义。

### 07 - Terraform root module

阅读：[`../targets/ecs/infra/README.md`](../targets/ecs/infra/README.md)

目标：理解 root module 如何组合 network、ECR、IAM、logging、ECS、ALB、CodeBuild
和 CodePipeline 子模块，以及为什么 AWS provider 只在 root 配置。

### 08 - 本地环境与 LocalStack provider 边界

阅读：[`../targets/ecs/infra/environments/local/README.md`](../targets/ecs/infra/environments/local/README.md)

目标：理解 `TF_VAR_aws_api_endpoint`、CodeBuild 内部的 `AWS_ENDPOINT_URL`，以及
宿主机和 Docker network 的两个 endpoint 视角；LocalStack 由 Docker Compose 管理。

### 09 - CI/CD 发布流程

阅读：[`../targets/ecs/docs/cicd-flow.md`](../targets/ecs/docs/cicd-flow.md)

目标：理解 source zip、release manifest、CodePipeline artifact、镜像 tag、task
definition revision 和 CloudWatch Logs 的连接关系。

### 10 - CodeBuild 构建阶段

阅读：[`../targets/ecs/docs/codebuild-concepts.md`](../targets/ecs/docs/codebuild-concepts.md)

目标：理解 `buildspec.yml` 的 install、pre-build、build、post-build 阶段，以及
Docker 镜像构建和 `imagedefinitions.json` 的作用。

### 11 - CodePipeline 阶段编排

阅读：[`../targets/ecs/docs/codepipeline-concepts.md`](../targets/ecs/docs/codepipeline-concepts.md)

目标：理解 V1 pipeline 的 Source、Build、Deploy 三个阶段，以及 LocalStack V1
ECS deploy 状态滞后时的独立验证策略。

### 12 - 部署、发布和回滚

阅读：[`../targets/ecs/docs/deployment-lifecycle.md`](../targets/ecs/docs/deployment-lifecycle.md)

目标：理解 `v1`、`v2` 和 rollback 如何证明服务替换、ALB 可访问性和历史健康版本
恢复。

### 13 - AWS 迁移边界

阅读：[`../targets/ecs/docs/aws-migration.md`](../targets/ecs/docs/aws-migration.md)

目标：区分 LocalStack 专用内容与迁移到真实 AWS 时保持不变的应用、Terraform 和
CI/CD 设计。

### 14 - 后续路线图

阅读：[`roadmap.md`](roadmap.md)

目标：了解 ECS 之后的 EKS、Lambda 和 App Runner 目标，以及为什么当前不提前创建
空实现或占位目录。

## 推荐实践顺序

1. 先完成 01-06，建立系统和 ECS 基础模型。
2. 再阅读 07-08，重点观察 root provider 与 LocalStack endpoint 的边界。
3. 然后阅读 `targets/ecs/docs/operations-runbook.md`，按 09-12 的顺序直接执行
   Terraform、Docker Compose 和 AWS CLI 命令，跟踪一次发布、验证和回滚。
4. 最后阅读 13-14，思考从 LocalStack 迁移到真实 AWS 以及扩展第二个部署目标。
