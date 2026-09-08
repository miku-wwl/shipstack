. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Write-Host 'QUALIFICATION_STATE=GENERATED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'deploy-infra.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Infrastructure deployment failed.' }
Write-Host 'QUALIFICATION_STATE=LOCALSTACK_INFRA_DEPLOYED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-pipeline.ps1') -ReleaseVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Release 1 pipeline failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecr.ps1') -ReleaseVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Release 1 ECR validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Release 1 ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion v1
if ($LASTEXITCODE -ne 0) { throw 'Release 1 HTTP validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-logs.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Release 1 validation failed.' }
Write-Host 'QUALIFICATION_STATE=HTTP_E2E_VERIFIED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-pipeline.ps1') -ReleaseVersion v2
if ($LASTEXITCODE -ne 0) { throw 'Release 2 pipeline failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecr.ps1') -ReleaseVersion v2
if ($LASTEXITCODE -ne 0) { throw 'Release 2 ECR validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-ecs.ps1') -ExpectedVersion v2
if ($LASTEXITCODE -ne 0) { throw 'Release 2 ECS validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'smoke-test.ps1') -ExpectedVersion v2
if ($LASTEXITCODE -ne 0) { throw 'Release 2 HTTP validation failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate-logs.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Release 2 log validation failed.' }
Write-Host 'QUALIFICATION_STATE=SECOND_RELEASE_VERIFIED'

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'rollback.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Rollback validation failed.' }
Write-Host 'QUALIFICATION_STATE=ROLLBACK_VERIFIED'
Write-Host 'LOCALSTACK_QUALIFIED'
