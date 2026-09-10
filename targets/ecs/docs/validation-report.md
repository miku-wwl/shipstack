# ECS 目标验证报告

验证日期：2026-09-10

## 验证范围

本次只验证现有 ECS target：Terraform 基础设施、CodePipeline、CodeBuild、ECR、ECS、ALB、CloudWatch Logs，以及显式的 last-known-good 回滚。没有实现 EC2、Lambda 或 EKS。

## 静态与构建检查

| 检查 | 结果 |
| --- | --- |
| `terraform validate` | PASS |
| `terraform fmt -check -recursive` | PASS |
| PowerShell 脚本解析 | PASS |
| `buildspec.yml` YAML 解析 | PASS |
| `mvn -B clean package` | PASS；当前没有测试源文件，因此显示 `No tests to run` |
| `git diff --check` | PASS；仅有 Windows 换行提示 |
| Bash 脚本语法检查 | NOT VERIFIED；当前 Windows 环境没有 `/bin/bash` |

## LocalStack 运行时证据

LocalStack `2026.8.0.dev194`（Pro）已复用项目容器 `shipstack-ecs-localstack`，项目 API 端口为 `4567`。

1. v1 发布：CodePipeline 成功，ECR digest 为
   `sha256:d0cccd773c05e683f615c9aaff4d35f1c49671ba5ff7fbc84e163a4d270f01d1`，ECS task definition 为 `shipstack-ecs-task:14`。
2. v1 HTTP 验证：`/api/v1/hello`、`/api/v1/version`、`/actuator/health` 均返回成功响应；CloudWatch Logs 找到 `request method=` 请求日志。
3. v2 发布：CodePipeline 成功，ECR digest 为
   `sha256:8fc746fa3759991fde0904ef62deff32aa8eda19733249f41800bb39399346e6`，ECS task definition 为 `shipstack-ecs-task:15`，version 返回 `v2`。
4. 回滚：没有使用“当前 revision 减一”，而是读取 `.local/last-known-good.json` 中记录的 v1 ARN，回滚到 `shipstack-ecs-task:14`，version 恢复为 `v1`。

最终状态：`LOCALSTACK_QUALIFIED`。

## 正确访问地址

ALB 访问地址必须包含 `localhost`：

```text
http://shipstack-ecs-alb.elb.localhost.localstack.cloud:4567/api/v1/version
http://shipstack-ecs-alb.elb.localhost.localstack.cloud:4567/actuator/health
```

截图中的 `shipstack-ecs-alb.elb.localstack.cloud` 少了 `localhost`，会导致 DNS_PROBE_FINISHED_NXDOMAIN。
