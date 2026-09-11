# ECS Terraform

root module 组合了 network、ECR、ECS、ALB、IAM、logging、CodeBuild 和 CodePipeline
等小型模块。它使用标准 AWS provider resources。AWS provider 及其可选 endpoint
overrides 只在此 root module 中配置；子模块只接收标准资源输入。

本地执行时，由外部环境设置 `TF_VAR_aws_api_endpoint`，并设置 CodeBuild 环境中的
独立 `AWS_ENDPOINT_URL`，供 build container 内运行的命令使用。这两个值都不属于
子模块接口。

ECS service 初始使用确定性的 bootstrap image，以便 Terraform 在首次 CodePipeline
运行前创建健康的 service。随后 pipeline 使用 `imagedefinitions.json` 中的 release
image 替换该 task definition。

本地 source bucket 有意使用 S3 source action，而不是 GitHub-connected action。这样
可以保持 E2E qualification 的确定性，同时为未来改用 CodeConnections 保留清晰的
source-stage 边界。

当前 LocalStack 拓扑只创建 public subnets：ALB 和 ECS/Fargate tasks 都在 public
subnets，task 使用 public IP。这是本地学习环境的有意选择；未使用的 private subnet、
private route table 和 NAT 没有被创建。迁移到真实 AWS 时，再由环境配置引入 private
tasks、NAT Gateway 或 VPC endpoints。

Terraform 拥有网络、IAM、ECR、ECS service 配置、ALB、CodeBuild、CodePipeline、日志组
和 bootstrap task definition。CodePipeline 拥有发布时的 application image、task
definition revision 和 active release；因此 ECS service 对 `task_definition` 使用
`lifecycle.ignore_changes`，避免 Terraform apply 把成功部署恢复成 bootstrap。

ECS 应用 release 的 last-known-good 状态如果需要记录，应由外部发布系统或人工使用
AWS CLI 管理；Terraform module 本身不创建发布编排器，也不保存 LocalStack 状态。
