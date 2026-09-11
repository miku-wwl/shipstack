# ECS 本地操作 Runbook

这份 Runbook 是 ECS 目标的唯一操作入口。所有命令都直接调用 Docker Compose、
Terraform 或 AWS CLI；仓库不再提供 PowerShell、Bash、Makefile 或其他包装脚本。

命令默认在仓库根目录 D:\workshop\sep\shipstack 的 PowerShell 中执行。
命令块中的变量只存在于当前终端，不会被保存成脚本文件。

## 1. 设置本地环境

~~~powershell
Set-Location D:\workshop\sep\shipstack

$TargetRoot = (Resolve-Path .\targets\ecs).Path
$InfraRoot = Join-Path $TargetRoot 'infra'
$LocalDir = Join-Path $TargetRoot '.local'
New-Item -ItemType Directory -Force -Path $LocalDir, (Join-Path $LocalDir 'localstack-data') | Out-Null

$env:AWS_ACCESS_KEY_ID = 'test'
$env:AWS_SECRET_ACCESS_KEY = 'test'
$env:AWS_SESSION_TOKEN = 'test'
$env:AWS_DEFAULT_REGION = 'us-east-1'
$env:AWS_REGION = 'us-east-1'
$env:AWS_ENDPOINT_URL = 'http://localhost:4567'
$env:TF_VAR_aws_api_endpoint = 'http://localhost:4567'
$env:TF_VAR_codebuild_aws_endpoint = 'http://shipstack-ecs-localstack:4566'
$env:TF_VAR_ecr_registry_port = '4567'
~~~

这些是 LocalStack 测试凭证，不得用于真实 AWS。不要把
LOCALSTACK_AUTH_TOKEN 写入仓库或命令历史。

## 2. 用 Docker Compose 启动 LocalStack

如果需要复用现有 localstack-main 的镜像和授权令牌，先在当前终端读取它们；
下面的命令不会打印令牌：

~~~powershell
$env:LOCALSTACK_IMAGE = (docker inspect localstack-main --format '{{.Config.Image}}').Trim()
$authLine = docker inspect localstack-main --format '{{range .Config.Env}}{{println .}}{{end}}' | Select-String '^LOCALSTACK_AUTH_TOKEN='
if (-not $authLine) { throw 'localstack-main 没有可复用的 LOCALSTACK_AUTH_TOKEN' }
$env:LOCALSTACK_AUTH_TOKEN = $authLine.ToString().Substring('LOCALSTACK_AUTH_TOKEN='.Length)
~~~

如果 localstack-main 不存在，请在 LocalStack 官方镜像配置中设置令牌后再执行
Compose。项目 Compose 文件位于
[docker-compose.localstack.yml](../docker-compose.localstack.yml)：

~~~powershell
docker compose -f .\targets\ecs\docker-compose.localstack.yml up -d
Invoke-RestMethod http://localhost:4567/_localstack/health
~~~

如果旧的同名容器是以前用 docker run 创建的，先显式移除这个项目容器，再交给
Compose 管理；不要删除 localstack-main：

~~~powershell
docker rm -f shipstack-ecs-localstack
docker compose -f .\targets\ecs\docker-compose.localstack.yml up -d
~~~

## 3. 构建应用和 CodeBuild 镜像

应用测试和打包直接使用 Maven：

~~~powershell
Set-Location .\targets\ecs\app
mvn -B clean package
Set-Location ..\..
~~~

LocalStack CodeBuild runner 使用的本地镜像直接用 Docker 构建：

~~~powershell
docker build --pull=false --tag shipstack-ecs-codebuild-local:1 .\targets\ecs\build-assets\codebuild-image
~~~

## 4. 直接使用 Terraform 创建控制面

Terraform provider 位于 root module；LocalStack endpoint 通过 root module 的
TF_VAR_aws_api_endpoint 注入，子模块不接收 LocalStack 配置。

~~~powershell
terraform -chdir=targets/ecs/infra init -input=false
terraform -chdir=targets/ecs/infra fmt -check -recursive
terraform -chdir=targets/ecs/infra validate

# 先创建完整控制面，但暂时不启动 ECS task。
terraform -chdir=targets/ecs/infra apply -auto-approve -input=false -var desired_count=0
~~~

## 5. 准备 bootstrap 镜像并完成 ECS 基础设施

第一次创建 ECS service 时需要一个已经存在的镜像。先从 Terraform output 读取 ECR
地址，再用原生 AWS CLI 登录和推送：

~~~powershell
$RepoUri = (terraform -chdir=targets/ecs/infra output -raw ecr_repository_uri).Trim()
$Registry = ($RepoUri -split '/')[0]

Set-Location .\targets\ecs\app
mvn -B package -DskipTests
docker build --pull=false --build-arg APP_VERSION=bootstrap --tag shipstack-ecs-platform-demo:bootstrap .
Set-Location ..\..

aws ecr get-login-password --region $env:AWS_DEFAULT_REGION --endpoint-url $env:AWS_ENDPOINT_URL | docker login --username AWS --password-stdin $Registry
docker tag shipstack-ecs-platform-demo:bootstrap "$($RepoUri):bootstrap"
docker push "$($RepoUri):bootstrap"

terraform -chdir=targets/ecs/infra apply -auto-approve -input=false
~~~

## 6. 生成并上传 source artifact

CodePipeline 的 Source action 读取 S3 中的 source.zip。下面是显式的 PowerShell
文件操作命令；它只在当前终端执行，不保存为 .ps1 文件：

~~~powershell
$ReleaseVersion = 'v1'
$RepoRoot = (Resolve-Path .).Path
$LocalDir = Join-Path $RepoRoot 'targets\ecs\.local'
$Stage = Join-Path $LocalDir "source-stage-$ReleaseVersion"
$Artifact = Join-Path $LocalDir "source-$ReleaseVersion.zip"

if (Test-Path $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Stage | Out-Null

$RepoPrefix = $RepoRoot.TrimEnd('\') + '\'
Get-ChildItem -LiteralPath $RepoRoot -File -Recurse -Force |
    Where-Object {
        $_.FullName -notmatch '\\.git(\\|$)' -and
        $_.FullName -notmatch '\\.local(\\|$)' -and
        $_.FullName -notmatch '\\.terraform(\\|$)' -and
        $_.FullName -notmatch '\\target(\\|$)' -and
        $_.FullName -notmatch '\\tmp(\\|$)' -and
        $_.Name -notmatch '\.(tfstate|zip)(\.|$)'
    } |
    ForEach-Object {
        $Relative = $_.FullName.Substring($RepoPrefix.Length)
        $Destination = Join-Path $Stage $Relative
        New-Item -ItemType Directory -Force -Path (Split-Path $Destination) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Force
    }

$ReleaseDir = Join-Path $Stage 'targets\ecs\release'
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
Set-Content -LiteralPath (Join-Path $ReleaseDir 'APP_VERSION') -Value $ReleaseVersion -NoNewline
Set-Content -LiteralPath (Join-Path $ReleaseDir 'RELEASE_ID') -Value $ReleaseVersion -NoNewline

if (Test-Path $Artifact) { Remove-Item -LiteralPath $Artifact -Force }
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $Artifact -CompressionLevel Optimal
~~~

使用原生 AWS CLI 上传并启动 CodePipeline：

~~~powershell
$Bucket = (terraform -chdir=targets/ecs/infra output -raw artifact_bucket_name).Trim()
$SourceKey = (terraform -chdir=targets/ecs/infra output -raw source_object_key).Trim()
$Pipeline = (terraform -chdir=targets/ecs/infra output -raw codepipeline_name).Trim()

aws s3 cp $Artifact "s3://$Bucket/$SourceKey" --endpoint-url $env:AWS_ENDPOINT_URL
$ExecutionId = (aws codepipeline start-pipeline-execution --name $Pipeline --query pipelineExecutionId --output text --endpoint-url $env:AWS_ENDPOINT_URL).Trim()
$ExecutionId
~~~

轮询这次执行的状态，直到状态变成终态：

~~~powershell
do {
    $Execution = aws codepipeline get-pipeline-execution --pipeline-name $Pipeline --pipeline-execution-id $ExecutionId --output json --endpoint-url $env:AWS_ENDPOINT_URL | ConvertFrom-Json
    $PipelineStatus = [string]$Execution.pipelineExecution.status
    Write-Host "PIPELINE_STATUS=$PipelineStatus release=$ReleaseVersion"
    if ($PipelineStatus -notin @('Succeeded','Failed','Stopped','Stopping','Superseded')) {
        Start-Sleep -Seconds 10
    }
} while ($PipelineStatus -notin @('Succeeded','Failed','Stopped','Stopping','Superseded'))

if ($PipelineStatus -ne 'Succeeded') {
    aws codepipeline list-action-executions --pipeline-name $Pipeline --filter "pipelineExecutionId=$ExecutionId" --output json --endpoint-url $env:AWS_ENDPOINT_URL
    throw "CodePipeline 执行未成功：$PipelineStatus"
}
~~~

LocalStack 某些版本可能在 ECS 已稳定后仍短暂显示 V1 Deploy action 为
InProgress，或报告 waiter 超时。此时不能把状态直接当作成功，必须继续执行下面的
ECR、ECS、HTTP 和日志验证；只有独立证据全部通过，才算发布完成。

## 7. 验证 ECR、ECS、ALB 和日志

~~~powershell
$Repo = (terraform -chdir=targets/ecs/infra output -raw ecr_repository_name).Trim()
$Cluster = (terraform -chdir=targets/ecs/infra output -raw ecs_cluster_name).Trim()
$Service = (terraform -chdir=targets/ecs/infra output -raw ecs_service_name).Trim()
$Family = (terraform -chdir=targets/ecs/infra output -raw ecs_task_definition_family).Trim()
$LogGroup = (terraform -chdir=targets/ecs/infra output -raw log_group_name).Trim()

aws ecr describe-images --repository-name $Repo --image-ids imageTag=$ReleaseVersion --output json --endpoint-url $env:AWS_ENDPOINT_URL

$ServiceJson = aws ecs describe-services --cluster $Cluster --services $Service --output json --endpoint-url $env:AWS_ENDPOINT_URL | ConvertFrom-Json
$ServiceJson.services | Select-Object serviceName,status,desiredCount,runningCount,pendingCount,taskDefinition

$TaskArns = @(aws ecs list-tasks --cluster $Cluster --service-name $Service --desired-status RUNNING --query taskArns --output text --endpoint-url $env:AWS_ENDPOINT_URL) -split '\s+'
aws ecs describe-tasks --cluster $Cluster --tasks $TaskArns --output json --endpoint-url $env:AWS_ENDPOINT_URL

$TaskDefinitionArn = [string]$ServiceJson.services[0].taskDefinition
aws ecs describe-task-definition --task-definition $TaskDefinitionArn --query 'taskDefinition.containerDefinitions[0].image' --output text --endpoint-url $env:AWS_ENDPOINT_URL

$AlbEndpoint = (terraform -chdir=targets/ecs/infra output -raw alb_endpoint).TrimEnd('/')
$BaseUrl = if ($AlbEndpoint -match ':[0-9]+$') { $AlbEndpoint } else { "$($AlbEndpoint):4567" }
Invoke-RestMethod "$BaseUrl/api/v1/hello"
Invoke-RestMethod "$BaseUrl/api/v1/version"
Invoke-RestMethod "$BaseUrl/actuator/health"

aws logs filter-log-events --log-group-name $LogGroup --output json --endpoint-url $env:AWS_ENDPOINT_URL
~~~

正确的 LocalStack ALB 地址必须包含 localhost，例如：

~~~text
http://shipstack-ecs-alb.elb.localhost.localstack.cloud:4567/api/v1/version
http://shipstack-ecs-alb.elb.localhost.localstack.cloud:4567/actuator/health
~~~

## 8. 记录 last-known-good

发布通过独立验证后，直接使用 AWS CLI 查询实际运行的 task definition、镜像 URI 和
digest，再写入本地学习状态文件：

~~~powershell
$ExpectedVersion = $ReleaseVersion
$ServiceJson = aws ecs describe-services --cluster $Cluster --services $Service --output json --endpoint-url $env:AWS_ENDPOINT_URL | ConvertFrom-Json
$TaskDefinitionArn = [string]$ServiceJson.services[0].taskDefinition
$TaskDefinitionJson = aws ecs describe-task-definition --task-definition $TaskDefinitionArn --output json --endpoint-url $env:AWS_ENDPOINT_URL | ConvertFrom-Json
$ImageUri = [string]$TaskDefinitionJson.taskDefinition.containerDefinitions[0].image
$ImageDigest = [string](aws ecr describe-images --repository-name $Repo --image-ids imageTag=$ExpectedVersion --query 'imageDetails[0].imageDigest' --output text --endpoint-url $env:AWS_ENDPOINT_URL).Trim()

if ($ImageUri -notmatch ":$([regex]::Escape($ExpectedVersion))$" -or [string]::IsNullOrWhiteSpace($ImageDigest)) {
    throw '运行中的镜像版本或 ECR digest 与预期不一致。'
}

$LastKnownGood = [ordered]@{
    releaseVersion = $ExpectedVersion
    taskDefinitionArn = $TaskDefinitionArn
    imageUri = $ImageUri
    imageDigest = $ImageDigest
    recordedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
}
$LastKnownGood | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $LocalDir 'last-known-good.json') -Encoding utf8
~~~

## 9. 发布第二个版本并执行回滚

将第 6 节中的 ReleaseVersion 改为 v2，重新生成 source zip、上传 S3、启动并轮询
pipeline，再重复第 7 节验证。确认 version API 返回 v2 后，读取已经记录的 task
definition ARN，执行显式回滚：

~~~powershell
$LastKnownGood = Get-Content -Raw (Join-Path $LocalDir 'last-known-good.json') | ConvertFrom-Json
$RollbackArn = [string]$LastKnownGood.taskDefinitionArn

aws ecs describe-task-definition --task-definition $RollbackArn --output json --endpoint-url $env:AWS_ENDPOINT_URL
aws ecs update-service --cluster $Cluster --service $Service --task-definition $RollbackArn --force-new-deployment --output json --endpoint-url $env:AWS_ENDPOINT_URL
~~~

轮询 service，直到运行中的 task definition 确认回到已记录 ARN：

~~~powershell
do {
    Start-Sleep -Seconds 10
    $RollbackService = aws ecs describe-services --cluster $Cluster --services $Service --output json --endpoint-url $env:AWS_ENDPOINT_URL | ConvertFrom-Json
    $RollbackState = $RollbackService.services[0]
    Write-Host "TASK_DEFINITION=$($RollbackState.taskDefinition) running=$($RollbackState.runningCount) desired=$($RollbackState.desiredCount)"
} while ([string]$RollbackState.taskDefinition -ne $RollbackArn -or [int]$RollbackState.runningCount -lt [int]$RollbackState.desiredCount)

Invoke-RestMethod "$BaseUrl/api/v1/version"
Invoke-RestMethod "$BaseUrl/actuator/health"
~~~

回滚目标必须来自记录的 task definition ARN，不能用“当前 revision 减一”推算。

## 10. 停止或销毁本地环境

只停止项目 LocalStack 容器：

~~~powershell
docker compose -f .\targets\ecs\docker-compose.localstack.yml down
~~~

如果确认要删除 Terraform 创建的本地 AWS 资源：

~~~powershell
terraform -chdir=targets/ecs/infra destroy -auto-approve -input=false
~~~

destroy 是破坏性操作，学习时通常只需要停止 Compose 服务，不需要销毁基础设施。
