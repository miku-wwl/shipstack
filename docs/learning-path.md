# Shipstack 学习路径

这条路径只围绕仓库当前保留的 Terraform、业务代码和 CodeBuild buildspec。
LocalStack Ultimate 由外部环境提供，不在本仓库中安装、启动或配置。

## 01 - 仓库入口

阅读：[README.md](../README.md)

目标：了解部署目标目录、外部 LocalStack 边界，以及 Terraform 和业务代码的职责。

## 02 - 整体架构

阅读：[architecture.md](architecture.md)

目标：理解 source artifact、CodePipeline、CodeBuild、ECR、ECS/Fargate、ALB
和 CloudWatch Logs 的关系。

## 03 - 目标目录约定

阅读：[target-conventions.md](target-conventions.md)

目标：理解为什么部署目标放在 targets/<name>/ 下，以及 Terraform root module
和业务代码的边界。

## 04 - ECS 目标入口

阅读：[targets/ecs/README.md](../targets/ecs/README.md)

目标：掌握 ECS 目标保留的 Terraform、业务应用和 buildspec，以及外部 LocalStack
endpoint 的输入方式。

## 05 - Terraform root module

阅读：[targets/ecs/infra/README.md](../targets/ecs/infra/README.md)

目标：理解 root module 如何组合 network、ECR、IAM、logging、ECS、ALB、CodeBuild
和 CodePipeline 子模块，以及为什么 AWS provider 只在 root 配置。

## 06 - AWS provider 与外部 LocalStack

阅读：[targets/ecs/infra/environments/local/README.md](../targets/ecs/infra/environments/local/README.md)

目标：理解 TF_VAR_aws_api_endpoint、CodeBuild 内部的 AWS_ENDPOINT_URL，以及
外部 LocalStack 与 Terraform root module 的边界。

## 07 - 业务应用

阅读：[targets/ecs/app](../targets/ecs/app)

目标：从 Spring Boot 启动类、REST controller、日志过滤器和 Dockerfile 观察应用
如何提供 hello、version 和 health endpoint。

## 08 - CodeBuild 构建契约

阅读：[targets/ecs/buildspec.yml](../targets/ecs/buildspec.yml)

目标：理解 install、pre_build、build、post_build 阶段，以及镜像 tag、
imagedefinitions.json 和 release-metadata.json。

## 09 - Terraform 子模块

阅读：[targets/ecs/infra/modules](../targets/ecs/infra/modules)

目标：按 network、ECR、IAM、ECS、ALB、logging、CodeBuild、CodePipeline 的顺序
跟踪资源输入、输出和依赖关系。

## 10 - 运行与迁移思考

阅读：[roadmap.md](roadmap.md)

目标：在外部 LocalStack 上完成 Terraform plan/apply 后，思考迁移到真实 AWS 时
需要替换的 endpoint、凭证、网络和发布入口。

## 推荐实践顺序

1. 先阅读 01-04，建立仓库和 ECS 目标边界。
2. 再阅读 05-06，重点观察 root provider 如何接收外部 LocalStack endpoint。
3. 然后阅读 07-09，对照业务代码、buildspec 和 Terraform modules。
4. 最后执行 Terraform CLI，并在外部 LocalStack 上观察资源和 AWS API 结果。
