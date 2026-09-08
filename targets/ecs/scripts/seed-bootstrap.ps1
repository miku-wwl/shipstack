. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Set-LocalAwsEnvironment

$repoUri = Get-InfraOutput -Name ecr_repository_uri
Push-Location (Join-Path $script:TargetRoot 'app')
try {
    mvn -B package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw 'Maven package failed before bootstrap Docker build.' }
    docker build --pull=false --build-arg APP_VERSION=bootstrap --tag shipstack-ecs-platform-demo:bootstrap .
    if ($LASTEXITCODE -ne 0) { throw 'Bootstrap Docker build failed.' }
} finally { Pop-Location }

$registry = $repoUri.Split('/')[0]
& aws ecr get-login-password --region $script:Region --endpoint-url $script:Endpoint | docker login --username AWS --password-stdin $registry
if ($LASTEXITCODE -ne 0) { throw 'Docker login to LocalStack ECR failed.' }
docker tag shipstack-ecs-platform-demo:bootstrap "$repoUri`:bootstrap"
docker push "$repoUri`:bootstrap"
if ($LASTEXITCODE -ne 0) { throw 'Bootstrap image push failed.' }
Write-Host "BOOTSTRAP_IMAGE=$repoUri`:bootstrap"
