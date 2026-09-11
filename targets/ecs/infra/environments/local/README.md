# 本地环境与 LocalStack 边界

本地环境使用 `../../` 中的共享 Terraform root。外部 LocalStack routing 由当前终端
的环境变量在 root module 的 AWS provider 边界配置；Terraform resources 和子模块
保持 AWS 形态，以便迁移时复用。

## Provider 边界

root module 负责可选的 AWS-compatible endpoint overrides。Runbook 设置
`TF_VAR_aws_api_endpoint`，`../../versions.tf` 中的 AWS provider 将 Terraform
service calls 路由到项目专用的 LocalStack 实例。因此，LocalStack 专用 endpoint
值保留在 environment/root 边界，不传入可复用的子模块。

本目标不创建项目专用 LocalStack 容器。外部 LocalStack Ultimate 可以使用
`http://localhost:4567` 或其他 endpoint；其授权、服务列表、IAM enforcement 和
CodeBuild runner 配置都不属于本仓库。

宿主机侧 Terraform 和 AWS CLI endpoint 是 `http://localhost:4567`。CodeBuild 在
Docker network 中运行，并通过通用的 `AWS_ENDPOINT_URL` runtime environment
variable 获得自己可访问的 endpoint。这是同一个 LocalStack service 的两个网络视角，
并不是两套 Terraform provider 配置。

在外部 LocalStack 已经就绪，并且当前终端已设置 endpoint 后，直接运行：

```powershell
terraform -chdir=targets/ecs/infra fmt -check -recursive
terraform -chdir=targets/ecs/infra validate
terraform -chdir=../../ init -input=false
terraform -chdir=../../ fmt -check -recursive
terraform -chdir=../../ validate
terraform -chdir=../../ plan
```
