# CodePipeline 概念

该 pipeline 使用 V1 版本，包含三个阶段：

1. **Source** 从 S3 读取 `source.zip` 并输出 `SourceOutput`。
2. **Build** 使用 `SourceOutput` 调用 CodeBuild 并输出 `BuildOutput`。
3. **Deploy** 使用 `BuildOutput` 调用 ECS standard action，并读取
   `imagedefinitions.json`。

这里有意使用本地 S3 source，这样无需 GitHub 授权或自动触发行为即可执行可重复
的 qualification run。source stage 保持隔离，以便未来迁移到真实 AWS 时使用
CodeConnections。
启动、轮询和验证命令集中在 [`operations-runbook.md`](operations-runbook.md)，直接
使用 AWS CLI。
# LocalStack 执行说明

本地 Runbook 还会检查 Build action 和 ECS service 的可观测输出。在 LocalStack
2026.8 中，V1 ECS deploy plugin 可能在 service 已经收到新的 task-definition
revision 并达到 desired count 后，仍将父 pipeline execution 保持为
`InProgress`，或者将 waiter 报告为 `Waiter ServicesStable failed: Max attempts exceeded`。
只有当 build 为 `Succeeded`、ECS service 稳定，并且 active image tag 与请求的
release 匹配时，才接受该 fallback。AWS qualification 应使用原生 CodePipeline
terminal status。
