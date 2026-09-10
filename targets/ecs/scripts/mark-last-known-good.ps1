param([Parameter(Mandatory)][string]$ExpectedVersion)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Set-LocalAwsEnvironment

$cluster = Get-InfraOutput -Name ecs_cluster_name
$service = Get-InfraOutput -Name ecs_service_name
$serviceJson = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Unable to read ECS service while recording last-known-good release.' }
$svc = $serviceJson.services | Select-Object -First 1
if (-not $svc -or [string]$svc.status -ne 'ACTIVE') { throw 'Cannot record last-known-good: ECS service is not ACTIVE.' }
if ([int]$svc.desiredCount -lt 1 -or [int]$svc.runningCount -lt [int]$svc.desiredCount) {
    throw "Cannot record last-known-good: ECS service is not ready (running=$($svc.runningCount) desired=$($svc.desiredCount))."
}

$taskDefinitionArn = [string]$svc.taskDefinition
$taskDefinition = & aws ecs describe-task-definition --task-definition $taskDefinitionArn --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "Unable to describe ECS task definition $taskDefinitionArn." }
$imageUri = [string](($taskDefinition.taskDefinition.containerDefinitions | Select-Object -First 1).image)
if ($imageUri -notmatch ':([^:]+)$') { throw "Cannot record last-known-good: unexpected image URI '$imageUri'." }
if ($Matches[1] -ne $ExpectedVersion) { throw "Cannot record last-known-good: image tag '$($Matches[1])' does not match '$ExpectedVersion'." }

$repo = Get-InfraOutput -Name ecr_repository_name
$imageJson = & aws ecr describe-images --repository-name $repo --image-ids imageTag=$ExpectedVersion --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $imageJson.imageDetails.Count -lt 1) { throw "Cannot record last-known-good: ECR image '$repo`:$ExpectedVersion' was not found." }
$imageDigest = [string](($imageJson.imageDetails | Select-Object -First 1).imageDigest)
if ([string]::IsNullOrWhiteSpace($imageDigest)) { throw 'Cannot record last-known-good: ECR image has no digest.' }

Save-LastKnownGoodRelease -ReleaseVersion $ExpectedVersion -TaskDefinitionArn $taskDefinitionArn -ImageUri $imageUri -ImageDigest $imageDigest
Write-Host "LAST_KNOWN_GOOD_STATE=$($script:ReleaseStatePath)"
