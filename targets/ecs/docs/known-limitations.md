# 当前限制与下一步问题

## 已知限制

- 这次证据来自 LocalStack，不等价于真实 AWS 中的 CodePipeline、ECS、ALB、IAM 或 CloudWatch qualification。
- `.local/last-known-good.json` 是本地实验状态文件，不是生产环境的发布登记库；生产环境需要受保护、可审计的 release metadata 存储。
- LocalStack 的滚动替换可能短时间显示 `runningCount` 大于 `desiredCount`；Runbook 因此要求至少达到 desired count，并同时检查任务健康状态。
- `targets/ecs/app/src/test` 已按学习范围删除，所以 Maven 构建通过不代表当前拥有有效的单元测试覆盖率。
- 本地 Runbook 以 PowerShell 为主；CodeBuild 内部仍按 AWS buildspec 的 Bash shell 执行，宿主机不需要安装 Bash。

## 下一里程碑

1. 在隔离 AWS 账号中先做 Terraform plan 和 IAM action 验证，再迁移 CodeBuild、ECR、ECS 和 ALB。
2. 生产 ECS 任务迁移到 private subnets，并补 NAT Gateway 或 VPC endpoints 的网络设计。
3. 决定生产 release metadata 的权威存储、保留策略和审批绑定方式。
4. 恢复最小的应用测试集，再把测试结果作为 CodePipeline 的独立质量门禁。
