$ErrorActionPreference = 'Stop'
$targetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location (Join-Path $targetRoot 'app')
try {
    mvn -B package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw 'Maven package failed before Docker build.' }
    docker build --pull=false --tag shipstack-ecs-platform-demo:local .
    if ($LASTEXITCODE -ne 0) { throw 'Docker build failed.' }
} finally { Pop-Location }
