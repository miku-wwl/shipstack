# ECS Terraform

root module 组合了 network、ECR、ECS、ALB、IAM、logging、CodeBuild 和 CodePipeline
等小型模块。它使用标准 AWS provider resources。AWS provider 及其可选 endpoint
overrides 只在此 root module 中配置；子模块只接收标准资源输入。

本地执行时，脚本为 Terraform provider 设置 `TF_VAR_aws_api_endpoint`，并设置
CodeBuild 环境中的独立 `AWS_ENDPOINT_URL`，供 build container 内运行的命令使用。
这两个值都不属于子模块接口。

ECS service 初始使用确定性的 bootstrap image，以便 Terraform 在首次 CodePipeline
运行前创建健康的 service。随后 pipeline 使用 `imagedefinitions.json` 中的 release
image 替换该 task definition。

本地 source bucket 有意使用 S3 source action，而不是 GitHub-connected action。这样
可以保持 E2E qualification 的确定性，同时为未来改用 CodeConnections 保留清晰的
source-stage 边界。
