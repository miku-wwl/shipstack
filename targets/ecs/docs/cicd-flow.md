# CI/CD 流程

Runbook 中的显式 PowerShell 文件命令创建一个确定性的压缩包，其中包含仓库内容以及
位于 `targets/ecs/release/APP_VERSION` 的 release manifest。压缩包会使用原生 AWS
CLI 上传到目标 artifact bucket。

CodePipeline V1 读取该 S3 对象，将 source artifact 传递给 CodeBuild，并接收包含
`imagedefinitions.json` 的 build artifact。CodeBuild 使用一次 `mvn -B package` 完成
测试和打包，构建 Docker 镜像，登录 LocalStack ECR，并推送显式的 release tag。

发布后 CodeBuild 会读取 ECR digest，并额外生成 `release-metadata.json`；ECS standard
deploy 仍通过 `imagedefinitions.json` 使用 release tag，不使用 `latest`。

ECS standard deploy action 读取 image definition，注册新的 task definition revision，
并更新 ECS service。ECS 替换任务；ALB health check 使用 `/actuator/health`。应用
标准输出通过 `awslogs` driver 传递到 CloudWatch Logs。
