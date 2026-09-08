$ErrorActionPreference = 'Stop'

$containerName = 'shipstack-ecs-localstack'
$hostPort = 4567
$healthUri = "http://localhost:$hostPort/_localstack/health"
$dataRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\.local')).Path
$dataDir = Join-Path $dataRoot 'localstack-data'
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

$running = docker ps --filter "name=^/$containerName$" --filter status=running --format '{{.Names}}'
if ($running -eq $containerName) {
    Write-Host "PROJECT_LOCALSTACK=$containerName already running on port $hostPort"
    exit 0
}

$existing = docker ps -a --filter "name=^/$containerName$" --format '{{.Names}}'
if ($existing -eq $containerName) {
    docker rm -f $containerName | Out-Null
}

$image = docker inspect localstack-main --format '{{.Config.Image}}'
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($image)) {
    throw 'The existing localstack-main container is required as the source image.'
}
$authEntry = docker inspect localstack-main --format '{{range .Config.Env}}{{println .}}{{end}}' | Select-String '^LOCALSTACK_AUTH_TOKEN='
if (-not $authEntry) { throw 'The existing LocalStack container has no auth token to reuse.' }
$authToken = $authEntry.ToString().Substring('LOCALSTACK_AUTH_TOKEN='.Length)

$dockerArgs = @(
    'run', '-d', '--name', $containerName,
    '-p', "$hostPort`:4566",
    '-v', '//var/run/docker.sock:/var/run/docker.sock',
    '-v', "$dataDir`:/var/lib/localstack",
    '-e', 'SERVICES=s3,iam,ec2,ecr,ecs,elbv2,logs,codebuild,codepipeline,sts,cloudwatch',
    '-e', 'ENFORCE_IAM=1',
    '-e', 'CODEBUILD_ENABLE_CUSTOM_IMAGES=1',
    '-e', 'CODEBUILD_REMOVE_CONTAINERS=0',
    '-e', 'DEBUG=1',
    '-e', 'PERSISTENCE=0',
    '-e', "LOCALSTACK_AUTH_TOKEN=$authToken",
    $image
)
docker @dockerArgs | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Failed to start the project-scoped LocalStack container.' }

$deadline = (Get-Date).AddMinutes(3)
while ((Get-Date) -lt $deadline) {
    try {
        $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 5
        if ($health.services) {
            Write-Host "PROJECT_LOCALSTACK=$containerName port=$hostPort version=$($health.version) iam=ENFORCED custom_codebuild=ENABLED"
            exit 0
        }
    } catch { }
    Start-Sleep -Seconds 3
}
throw "Project LocalStack did not become healthy at $healthUri."
