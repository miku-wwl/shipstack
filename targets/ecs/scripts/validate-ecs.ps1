param([Parameter(Mandatory)][string]$ExpectedVersion)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Set-LocalAwsEnvironment
$cluster = Get-InfraOutput -Name ecs_cluster_name
$service = Get-InfraOutput -Name ecs_service_name
$family = Get-InfraOutput -Name ecs_task_definition_family
$serviceJson = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
$svc = $serviceJson.services | Select-Object -First 1
if (-not $svc) { throw 'ECS service was not found.' }
$running = [int]$svc.runningCount
$desired = [int]$svc.desiredCount
if ($running -lt $desired -or $desired -lt 1) { throw "ECS service is not stable: running=$running desired=$desired." }
$taskDef = [string]$svc.taskDefinition
if ($taskDef -notmatch ":(\d+)$") { throw "Unexpected task definition ARN: $taskDef" }
$revision = $Matches[1]
$td = & aws ecs describe-task-definition --task-definition $taskDef --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
$container = $td.taskDefinition.containerDefinitions | Select-Object -First 1
$image = [string]$container.image
if ($image -notmatch ':([^:]+)$') { throw "Unexpected ECS container image: $image" }
$imageVersion = $Matches[1]
Write-Host "ECS_TASK_DEFINITION=$family`:$revision"
Write-Host "ECS_SERVICE_STATUS=$($svc.status) running=$running desired=$desired"
Write-Host "ECS_IMAGE=$image"
if ($ExpectedVersion -and $imageVersion -ne $ExpectedVersion) { throw "ECS image tag '$imageVersion' does not match '$ExpectedVersion'." }
