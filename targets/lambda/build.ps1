# 第一阶段：将当前 Git HEAD 上传到 LocalStack S3
# .\targets\lambda\build.ps1 -Stage Upload -LocalStackEndpoint http://localhost:4566
#
# 第二阶段：触发 LocalStack CodePipeline，并等待部署与校验完成
# .\targets\lambda\build.ps1 -Stage Pipeline -LocalStackEndpoint http://localhost:4566

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Upload", "Pipeline")]
    [string] $Stage,
    [string] $LocalStackEndpoint = "http://localhost:4566",
    [int] $PollSeconds = 10,
    [int] $WaitTimeoutMinutes = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Command {
    param([Parameter(Mandatory)][string] $Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "找不到命令 '$Name'。请先安装并确保它位于 PATH 中。"
    }
}

function Get-TerraformOutput {
    param([Parameter(Mandatory)][string] $Name)

    Push-Location $InfraDirectory
    try {
        $output = & terraform output -raw $Name
        if ($LASTEXITCODE -ne 0) {
            throw "无法读取 Terraform 输出 '$Name'。请先在 $InfraDirectory 完成 terraform apply。"
        }

        return ($output | Out-String).Trim()
    }
    finally {
        Pop-Location
    }
}

function Invoke-LocalStackAws {
    param([Parameter(Mandatory)][string[]] $Arguments)

    $output = & aws --no-cli-pager "--endpoint-url=$LocalStackEndpoint" "--region=$AwsRegion" @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI 执行失败：aws $($Arguments -join ' ')"
    }

    return $output
}

function Assert-LocalStack {
    try {
        $health = Invoke-RestMethod -Uri "$LocalStackEndpoint/_localstack/health" -Method Get
        Write-Host "LocalStack 可访问：version=$($health.version)，edition=$($health.edition)"
    }
    catch {
        throw "无法访问 LocalStack endpoint '$LocalStackEndpoint'。请确认 LocalStack 已由外部环境启动。"
    }
}

Assert-Command "aws"
Assert-Command "terraform"
Assert-Command "git"

$LocalStackEndpoint = $LocalStackEndpoint.TrimEnd("/")
if ($LocalStackEndpoint -notmatch "^https?://") {
    throw "LocalStackEndpoint 必须是 http:// 或 https:// 开头的 URL。"
}
if ($PollSeconds -lt 1) {
    throw "PollSeconds 必须大于或等于 1。"
}
if ($WaitTimeoutMinutes -lt 1) {
    throw "WaitTimeoutMinutes 必须大于或等于 1。"
}

$TargetDirectory = (Resolve-Path $PSScriptRoot).Path
$RepositoryRoot = (& git -C $TargetDirectory rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    throw "无法定位 Git 仓库根目录。"
}

$TargetRelativePath = $TargetDirectory.Substring($RepositoryRoot.Length).TrimStart("\", "/").Replace("\", "/")
$InfraDirectory = Join-Path $TargetDirectory "infra"
if (-not (Test-Path -LiteralPath $InfraDirectory)) {
    throw "找不到 Terraform 目录：$InfraDirectory"
}

Assert-LocalStack
$AwsRegion = Get-TerraformOutput "aws_region"

switch ($Stage) {
    "Upload" {
        $ArtifactBucket = Get-TerraformOutput "artifact_bucket_name"
        $SourceObjectKey = Get-TerraformOutput "source_object_key"
        $ArchivePath = Join-Path ([System.IO.Path]::GetTempPath()) "shipstack-lambda-source-$([guid]::NewGuid()).zip"

        try {
            $TrackedTargetFiles = @(& git -C $RepositoryRoot ls-tree -r --name-only HEAD -- $TargetRelativePath)
            if ($LASTEXITCODE -ne 0 -or $TrackedTargetFiles.Count -eq 0) {
                throw "当前 Git HEAD 不包含 $TargetRelativePath。请先提交 Lambda 目标，再上传源码。"
            }

            Write-Host "从当前 Git HEAD 创建源码归档：$ArchivePath"
            & git -C $RepositoryRoot archive --format=zip "--output=$ArchivePath" HEAD
            if ($LASTEXITCODE -ne 0) {
                throw "git archive 执行失败。"
            }

            $Destination = "s3://$ArtifactBucket/$SourceObjectKey"
            Write-Host "上传源码到 LocalStack S3：$Destination"
            Invoke-LocalStackAws @("s3", "cp", $ArchivePath, $Destination) | Out-Host
            Invoke-LocalStackAws @("s3api", "head-object", "--bucket", $ArtifactBucket, "--key", $SourceObjectKey) | Out-Null
            Write-Host "源码上传并校验成功。"
        }
        finally {
            if (Test-Path -LiteralPath $ArchivePath) {
                Remove-Item -LiteralPath $ArchivePath -Force
            }
        }
    }

    "Pipeline" {
        $PipelineName = Get-TerraformOutput "codepipeline_name"
        $StartResult = Invoke-LocalStackAws @(
            "codepipeline", "start-pipeline-execution",
            "--name", $PipelineName,
            "--output", "json"
        ) | ConvertFrom-Json
        $ExecutionId = [string] $StartResult.pipelineExecutionId
        if ([string]::IsNullOrWhiteSpace($ExecutionId)) {
            throw "CodePipeline 没有返回 pipelineExecutionId。"
        }

        Write-Host "已触发 LocalStack CodePipeline：$PipelineName"
        Write-Host "执行 ID：$ExecutionId"

        $Deadline = (Get-Date).AddMinutes($WaitTimeoutMinutes)
        $Execution = $null
        do {
            $ExecutionList = Invoke-LocalStackAws @(
                "codepipeline", "list-pipeline-executions",
                "--pipeline-name", $PipelineName,
                "--max-items", "20",
                "--output", "json"
            ) | ConvertFrom-Json

            $Execution = @($ExecutionList.pipelineExecutionSummaries) |
                Where-Object { [string] $_.pipelineExecutionId -eq $ExecutionId } |
                Select-Object -First 1

            if ($null -ne $Execution) {
                $Status = [string] $Execution.status
                Write-Host "CodePipeline 状态：$Status"

                if ($Status -eq "Succeeded") {
                    $PipelineState = Invoke-LocalStackAws @(
                        "codepipeline", "get-pipeline-state",
                        "--name", $PipelineName,
                        "--output", "json"
                    ) | ConvertFrom-Json

                    if ($PipelineState.stageStates) {
                        $PipelineState.stageStates | ForEach-Object {
                            Write-Host "阶段 $($_.stageName)：$($_.latestExecution.status)"
                        }
                    }

                    Write-Host "CodePipeline 执行成功，已完成从 S3 下载源码、构建、Lambda 部署和运行校验。"
                    exit 0
                }

                if ($Status -in @("Failed", "Stopped", "Superseded")) {
                    throw "CodePipeline 执行结束但未成功：$Status。执行 ID：$ExecutionId"
                }
            }

            if ((Get-Date) -ge $Deadline) {
                throw "等待 CodePipeline 超时（${WaitTimeoutMinutes} 分钟）。执行 ID：$ExecutionId"
            }

            Start-Sleep -Seconds $PollSeconds
        } while ($true)
    }
}
