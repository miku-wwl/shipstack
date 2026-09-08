. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Set-LocalAwsEnvironment
$cluster = Get-InfraOutput -Name ecs_cluster_name
$service = Get-InfraOutput -Name ecs_service_name
$family = Get-InfraOutput -Name ecs_task_definition_family
$current = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
$currentArn = [string]$current.services[0].taskDefinition
if ($currentArn -notmatch ':(\d+)$') { throw "Unable to read current task definition revision from $currentArn" }
$currentRevision = [int]$Matches[1]
$previous = $currentRevision - 1
if ($previous -lt 1) { throw "No previous task-definition revision exists for rollback (current=$currentRevision)." }
$rollbackArn = "$family`:$previous"
& aws ecs update-service --cluster $cluster --service $service --task-definition $rollbackArn --force-new-deployment --output json --endpoint-url $script:Endpoint | Out-Null
if ($LASTEXITCODE -ne 0) { throw "ECS rollback to $rollbackArn failed." }
Write-Host "ROLLBACK_TASK_DEFINITION=$rollbackArn"
$deadline = (Get-Date).AddMinutes(5)
while ((Get-Date) -lt $deadline) {
    $check = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
    $svc = $check.services[0]
    if ([int]$svc.runningCount -ge [int]$svc.desiredCount -and [string]$svc.taskDefinition -match ":$previous$") { break }
    Start-Sleep -Seconds 10
}
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Rollback ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Rollback HTTP validation failed.' }
Write-Host 'ROLLBACK_VERIFIED'
