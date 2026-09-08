# 本地环境与 LocalStack 边界

本地环境使用 `../../` 中的共享 Terraform root。LocalStack routing 由本地 PowerShell
脚本在 root module 的 AWS provider 边界配置；Terraform resources 和子模块保持
AWS 形态，以便迁移时复用。

## Provider 边界

root module 负责可选的 AWS-compatible endpoint overrides。本地脚本设置
`TF_VAR_aws_api_endpoint`，`../../versions.tf` 中的 AWS provider 将 Terraform
service calls 路由到项目专用的 LocalStack 实例。因此，LocalStack 专用 endpoint
值保留在 environment/root 边界，不传入可复用的子模块。

本目标使用名为 `shipstack-ecs-localstack` 的项目专用 LocalStack 容器，地址为
`http://localhost:4567`。它复用 `localstack-main` 中已安装的 LocalStack 镜像和
auth token，但不会重启或覆盖已有容器。项目实例为 CodeBuild 和 IAM qualification
路径启用 `CODEBUILD_ENABLE_CUSTOM_IMAGES=1` 和 `ENFORCE_IAM=1`。同时将
`targets/ecs/.local/localstack-data` bind-mount 到 `/var/lib/localstack`，这是
LocalStack CodeBuild runner 所需的目录。

宿主机侧 Terraform 和 AWS CLI endpoint 是 `http://localhost:4567`。CodeBuild 在
Docker network 中运行，并通过通用的 `AWS_ENDPOINT_URL` runtime environment
variable 获得自己可访问的 endpoint。这是同一个 LocalStack service 的两个网络视角，
并不是两套 Terraform provider 配置。

已有的 `localstack-main` 容器不会被重启或覆盖。

## CodeBuild 镜像资产

LocalStack 的 CodeBuild local runner 通常会拉取 AWS 标准 CodeBuild image。为了
让 Windows/Docker Desktop 运行更加确定，本目标基于已安装的 LocalStack CodeBuild
runner image 构建 `shipstack-ecs-codebuild-local:1`。它增加 Java 17、Maven 3.9.9、
AWS CLI 和 archive tools；项目仍然执行原生 CodeBuild Source、Build 和 ECS Deploy
actions。迁移到真实 AWS 时，可以将 `codebuild_image` 设置为 AWS CodeBuild standard
image。

Docker build context 仍然作为独立构建资产放在
`targets/ecs/build-assets/codebuild-image` 中，不属于 Terraform AWS provider 配置。

在 `targets/ecs/` 下运行：

```powershell
make terraform-fmt
make terraform-validate
make local-infra
```
