param()

$ErrorActionPreference = 'Stop'
$script:TargetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:RepoRoot = (Resolve-Path (Join-Path $script:TargetRoot '..\..')).Path
$script:InfraRoot = Join-Path $script:TargetRoot 'infra'
$script:LocalDir = Join-Path $script:TargetRoot '.local'
$script:ReleaseStatePath = Join-Path $script:LocalDir 'last-known-good.json'
$script:Endpoint = 'http://localhost:4567'
$script:Region = 'us-east-1'

function Ensure-LocalStack {
    try {
        $health = Invoke-RestMethod -Uri "$script:Endpoint/_localstack/health" -TimeoutSec 5
    } catch {
        throw "LocalStack is not reachable at $script:Endpoint. Start the existing LocalStack Ultimate instance first."
    }
    if (-not $health.services) { throw 'LocalStack health response did not contain services.' }
    Write-Host "LocalStack $($health.version) edition=$($health.edition) is reachable."
}

function Set-LocalAwsEnvironment {
    $env:AWS_ACCESS_KEY_ID = 'test'
    $env:AWS_SECRET_ACCESS_KEY = 'test'
    $env:AWS_SESSION_TOKEN = 'test'
    $env:AWS_DEFAULT_REGION = $script:Region
    $env:AWS_REGION = $script:Region
    $env:LOCALSTACK_HOST = 'localhost:4567'
    $env:AWS_ENDPOINT_URL = $script:Endpoint
    $env:TF_VAR_aws_api_endpoint = $script:Endpoint
    $env:TF_VAR_codebuild_aws_endpoint = 'http://shipstack-ecs-localstack:4566'
    $env:TF_VAR_ecr_registry_port = '4567'
}

function Invoke-LocalAws {
    param([Parameter(Mandatory)][string[]]$Arguments)
    Set-LocalAwsEnvironment
    & aws @Arguments --endpoint-url $script:Endpoint
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI failed with exit code ${LASTEXITCODE}: aws $($Arguments -join ' ')" }
}

function Get-InfraOutput {
    param([Parameter(Mandatory)][string]$Name)
    Set-LocalAwsEnvironment
    $value = & terraform "-chdir=$($script:InfraRoot)" output -raw $Name 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Terraform output '$Name' is unavailable. Apply infrastructure first." }
    return $value.Trim()
}

function Ensure-LocalDirectory { if (-not (Test-Path $script:LocalDir)) { New-Item -ItemType Directory -Path $script:LocalDir | Out-Null } }

function Save-LastKnownGoodRelease {
    param(
        [Parameter(Mandatory)][string]$ReleaseVersion,
        [Parameter(Mandatory)][string]$TaskDefinitionArn,
        [Parameter(Mandatory)][string]$ImageUri,
        [Parameter(Mandatory)][string]$ImageDigest
    )

    Ensure-LocalDirectory
    $state = [ordered]@{
        releaseVersion     = $ReleaseVersion
        taskDefinitionArn  = $TaskDefinitionArn
        imageUri           = $ImageUri
        imageDigest        = $ImageDigest
        recordedAtUtc      = (Get-Date).ToUniversalTime().ToString('o')
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($script:ReleaseStatePath, ($state | ConvertTo-Json -Depth 5), $utf8NoBom)
    Write-Host "LAST_KNOWN_GOOD=$ReleaseVersion taskDefinition=$TaskDefinitionArn imageDigest=$ImageDigest"
}

function Get-LastKnownGoodRelease {
    if (-not (Test-Path -LiteralPath $script:ReleaseStatePath)) { return $null }
    try {
        $state = Get-Content -Raw -LiteralPath $script:ReleaseStatePath | ConvertFrom-Json
    } catch {
        throw "Last-known-good release state is invalid at $($script:ReleaseStatePath): $($_.Exception.Message)"
    }
    foreach ($property in @('releaseVersion', 'taskDefinitionArn', 'imageUri', 'imageDigest')) {
        if ([string]::IsNullOrWhiteSpace([string]$state.$property)) {
            throw "Last-known-good release state is missing '$property': $($script:ReleaseStatePath)"
        }
    }
    return $state
}
