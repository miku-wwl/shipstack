# Target 约定

- 将部署目标的实现放在 `targets/<name>/` 下。
- 每个目标都应能够独立理解和运行。
- 云资源名称统一使用 `shipstack-<target>-` 作为前缀。
- 将 LocalStack 兼容行为保留在目标目录内部。
- 只有在第二个具体目标证明某段代码确实可复用后，才将代码加入 `shared/`。
- 操作流程必须写成目标目录中的 Markdown Runbook 显式命令；不创建 Makefile、
  PowerShell/Bash 包装脚本或其他 orchestration helper。

ECS 目标是这些约定的参考实现。
