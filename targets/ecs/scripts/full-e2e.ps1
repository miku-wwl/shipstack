param(
    [string]$InitialReleaseVersion = 'v1',
    [string]$CandidateReleaseVersion = 'v2'
)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Write-Host 'QUALIFICATION_STATE=GENERATED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'deploy-infra.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Infrastructure deployment failed.' }
Write-Host 'QUALIFICATION_STATE=LOCALSTACK_INFRA_DEPLOYED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-pipeline.ps1') -ReleaseVersion $InitialReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Initial release pipeline failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecr.ps1') -ReleaseVersion $InitialReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Initial release ECR validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion $InitialReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Initial release ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion $InitialReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Initial release HTTP validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-logs.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Initial release log validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'mark-last-known-good.ps1') -ExpectedVersion $InitialReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Initial release qualification state could not be recorded.' }
Write-Host 'QUALIFICATION_STATE=HTTP_E2E_VERIFIED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-pipeline.ps1') -ReleaseVersion $CandidateReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Candidate release pipeline failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecr.ps1') -ReleaseVersion $CandidateReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Candidate release ECR validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion $CandidateReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Candidate release ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion $CandidateReleaseVersion
if ($LASTEXITCODE -ne 0) { throw 'Candidate release HTTP validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-logs.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Candidate release log validation failed.' }
# Keep the initial release as the fixture for this lab's rollback exercise.
# A normal promotion can record the candidate by calling mark-last-known-good.ps1.
Write-Host 'QUALIFICATION_STATE=SECOND_RELEASE_VERIFIED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'rollback.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Rollback validation failed.' }
Write-Host 'QUALIFICATION_STATE=ROLLBACK_VERIFIED'
Write-Host 'LOCALSTACK_QUALIFIED'
