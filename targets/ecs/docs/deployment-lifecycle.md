# 部署生命周期

qualification script 验证三个生命周期节点：

1. **初始 Release**：构建并推送 `v1`，通过 ALB 完成部署和访问，并在 CloudWatch Logs
   中观察到日志；全部通过后写入 `.local/last-known-good.json`。
2. **候选 Release**：新的 source artifact 和 image tag `v2` 生成新的 task definition
   revision，service 通过 HTTP 返回 `v2`。完整实验故意保留 `v1` 为回滚 fixture；正常
   发布可以在验证通过后手动记录 `v2`。
3. **Rollback**：读取 last-known-good 中保存的 task definition ARN，而不是计算
   `current revision - 1`，更新 service 后再次验证 ECS、ALB 和实际 release version。

last-known-good metadata 包含：

- release version
- task definition ARN
- image URI
- ECR image digest
- 记录时间

不会故意引入损坏的镜像、IAM policy、task definition 或应用。
