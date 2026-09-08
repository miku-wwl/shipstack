# 本目标中的 ECS 概念

- **Cluster**：`shipstack-ecs-cluster`，逻辑上的放置边界。
- **Task definition**：用于版本化描述镜像、资源、端口、环境、health check、角色和
  日志配置的契约。
- **Task**：一个正在运行的 task definition 实例。
- **Service**：维持期望数量的任务运行，并将它们注册到 ALB target group。
- **Desired count**：本地 service 设置为 2，以便观察替换行为。
- **Fargate**：service 使用的启动类型。
- **Task execution role**：允许拉取镜像并传递日志。
- **Task role**：应用身份；由于此演示不依赖 AWS data plane，因此有意保持为空。
