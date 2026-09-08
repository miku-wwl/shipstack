$ErrorActionPreference = 'Stop'
$targetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$context = Join-Path $targetRoot 'build-assets\codebuild-image'
docker build --pull=false --tag shipstack-ecs-codebuild-local:1 $context
if ($LASTEXITCODE -ne 0) { throw 'Local CodeBuild image build failed.' }
