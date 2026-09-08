# 部署生命周期

qualification script 验证三个生命周期节点：

1. **Release 1**：构建并推送 `v1`，通过 ALB 完成部署和访问，并在 CloudWatch Logs
   中观察到日志。
2. **Release 2**：新的 source artifact 和 image tag `v2` 生成新的 task definition
   revision，service 通过 HTTP 返回 `v2`。
3. **Rollback**：将 service 更新到上一个健康的 task-definition revision。ALB
   保持可访问，并返回预期的上一版本 release。

不会故意引入损坏的镜像、IAM policy、task definition 或应用。
