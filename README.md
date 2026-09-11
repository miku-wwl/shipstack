# Shipstack

Shipstack 是一个以本地优先为原则的 AWS 交付平台，用于通过 Terraform 和原生
CI/CD 服务构建、部署、验证和运行云原生应用。

本仓库以部署目标为组织单位：

```text
shipstack/
└── targets/
    └── ecs/   # 首个已实现的部署目标
```

当前目标是一个完整的 ECS 应用 CI/CD 实验，使用 LocalStack Ultimate、Terraform、
CodePipeline V1、CodeBuild、ECR、ECS/Fargate、ALB 和 CloudWatch Logs。未来的
EKS 或 Lambda 等部署目标将作为 `targets/` 下的并列目录添加；当前仓库状态尚未
实现这些目标。

## 快速开始

Java 21、Maven、Terraform 和 AWS CLI 必须可用。LocalStack Ultimate 由外部环境
提供；本仓库不启动、配置或打包 LocalStack。Terraform root module 通过
`TF_VAR_aws_api_endpoint` 接收外部 LocalStack endpoint，业务应用和 Terraform
代码位于 [`targets/ecs/`](targets/ecs/README.md) 下。

本仓库不提供 Makefile、PowerShell/Bash 包装脚本或 LocalStack 编排文件。运行时请在
外部 LocalStack 已经可用的前提下，直接执行 Terraform CLI、Maven、Docker 和 AWS CLI。
