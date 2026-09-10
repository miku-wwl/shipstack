param([Parameter(Mandatory)][string]$ReleaseVersion)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Set-LocalAwsEnvironment
$repo = Get-InfraOutput -Name ecr_repository_name
$result = & aws ecr describe-images --repository-name $repo --image-ids imageTag=$ReleaseVersion --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $result.imageDetails.Count -lt 1) { throw "ECR image tag '$ReleaseVersion' was not found in $repo." }
$image = $result.imageDetails | Select-Object -First 1
$digest = [string]$image.imageDigest
if ([string]::IsNullOrWhiteSpace($digest)) { throw "ECR image '$repo`:$ReleaseVersion' has no image digest." }
Write-Host "ECR_IMAGE=$repo`:$ReleaseVersion"
Write-Host "ECR_DIGEST=$digest"
