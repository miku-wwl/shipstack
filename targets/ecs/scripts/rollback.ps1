. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Set-LocalAwsEnvironment
$cluster = Get-InfraOutput -Name ecs_cluster_name
$service = Get-InfraOutput -Name ecs_service_name
$lastKnownGood = Get-LastKnownGoodRelease
if (-not $lastKnownGood) {
    throw "No last-known-good release is recorded at $($script:ReleaseStatePath). Deploy and validate a release, then run mark-last-known-good.ps1 first."
}
$rollbackArn = [string]$lastKnownGood.taskDefinitionArn
$current = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
$currentArn = [string]$current.services[0].taskDefinition
if ([string]::IsNullOrWhiteSpace($currentArn)) { throw 'Unable to read current ECS task definition.' }
$targetDefinition = & aws ecs describe-task-definition --task-definition $rollbackArn --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $targetDefinition.taskDefinition) { throw "Recorded last-known-good task definition is unavailable: $rollbackArn" }
& aws ecs update-service --cluster $cluster --service $service --task-definition $rollbackArn --force-new-deployment --output json --endpoint-url $script:Endpoint | Out-Null
if ($LASTEXITCODE -ne 0) { throw "ECS rollback to $rollbackArn failed." }
Write-Host "ROLLBACK_RELEASE=$($lastKnownGood.releaseVersion)"
Write-Host "ROLLBACK_TASK_DEFINITION=$rollbackArn"
$deadline = (Get-Date).AddMinutes(5)
$reached = $false
while ((Get-Date) -lt $deadline) {
    $check = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
    $svc = $check.services[0]
    if ([int]$svc.runningCount -ge [int]$svc.desiredCount -and [string]$svc.taskDefinition -eq $rollbackArn) {
        $reached = $true
        break
    }
    Start-Sleep -Seconds 10
}
if (-not $reached) { throw "Rollback did not converge to recorded task definition $rollbackArn before timeout." }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion $lastKnownGood.releaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Rollback ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion $lastKnownGood.releaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Rollback HTTP validation failed.' }
Write-Host 'ROLLBACK_VERIFIED'
