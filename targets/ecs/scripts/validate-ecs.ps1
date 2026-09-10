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
if ([string]$svc.status -ne 'ACTIVE') { throw "ECS service is not ACTIVE: status=$($svc.status)." }
$running = [int]$svc.runningCount
$desired = [int]$svc.desiredCount
if ($desired -lt 1 -or $running -lt $desired -or [int]$svc.pendingCount -gt 0) {
    throw "ECS service is not stable: running=$running desired=$desired pending=$($svc.pendingCount)."
}
$primary = @($svc.deployments | Where-Object { $_.status -eq 'PRIMARY' }) | Select-Object -First 1
if (-not $primary) { throw 'ECS service has no PRIMARY deployment.' }
if (($primary.PSObject.Properties.Name -contains 'rolloutState') -and
    -not [string]::IsNullOrWhiteSpace([string]$primary.rolloutState) -and
    [string]$primary.rolloutState -ne 'COMPLETED') {
    throw "ECS PRIMARY deployment is not complete: rolloutState=$($primary.rolloutState)."
}
$taskList = & aws ecs list-tasks --cluster $cluster --service-name $service --desired-status RUNNING --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Unable to list ECS service tasks.' }
$taskArns = @($taskList.taskArns | Where-Object { $_ })
if ($taskArns.Count -lt $desired) { throw "ECS has too few RUNNING task ARNs: count=$($taskArns.Count) desired=$desired." }
$tasks = & aws ecs describe-tasks --cluster $cluster --tasks $taskArns --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Unable to describe ECS service tasks.' }
$nonRunning = @($tasks.tasks | Where-Object { $_.lastStatus -ne 'RUNNING' })
if ($nonRunning.Count -gt 0) { throw "ECS returned a non-RUNNING task: $($nonRunning[0].lastStatus)." }
$unhealthy = @($tasks.tasks | Where-Object { $_.healthStatus -eq 'UNHEALTHY' })
if ($unhealthy.Count -gt 0) { throw 'ECS returned an UNHEALTHY task.' }
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
