# AWS 迁移说明

## 预计保持不变的部分

- Spring Boot 应用和单元测试
- Dockerfile 和容器端口
- ECS task definition 和 service 架构
- ECR repository 设计和 release tagging
- ALB、target group 和 health-check 模型
- CloudWatch Log Group 和 `awslogs` 配置
- `buildspec.yml` 阶段以及 `imagedefinitions.json`
- CodeBuild build stage 和 ECS standard deploy stage
- 大部分 Terraform 资源以及 smoke-test 意图

## 预计需要变化的部分

- 本地 root provider 的 endpoint override 将变为使用真实 AWS 凭证、账户和区域的
  标准 Terraform provider 配置。
- 确定性的 S3 source action 可以替换为 GitHub CodeConnections。
- LocalStack 兼容的 ECR registry addressing 和 endpoint 环境变量需要移除或
  参数化。
- IAM policy 必须在真实账户中验证，包括 `iam:PassRole`、ECR、S3 artifact、ECS
  和 CloudWatch 权限。
- VPC routing、security groups、ALB DNS、ECS networking 以及 CloudWatch 行为
  都需要经过真实 AWS 验证。

所有 LocalStack 专用行为都隔离在 `targets/ecs/scripts/`、root provider 的可选
endpoint override、本地环境说明以及 CodeBuild runtime 的可选
`AWS_ENDPOINT_URL` 变量中。应用和可复用的 Terraform 子模块不依赖 LocalStack。
