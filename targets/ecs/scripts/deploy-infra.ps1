. (Join-Path $PSScriptRoot 'common.ps1')
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'start-project-localstack.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Project-scoped LocalStack startup failed.' }
Ensure-LocalStack
Ensure-LocalDirectory
Set-LocalAwsEnvironment

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build-codebuild-image.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Local CodeBuild image preparation failed.' }

& terraform "-chdir=$($script:InfraRoot)" init -input=false
if ($LASTEXITCODE -ne 0) { throw 'Terraform init failed.' }
& terraform "-chdir=$($script:InfraRoot)" fmt -check -recursive
if ($LASTEXITCODE -ne 0) { throw 'Terraform formatting check failed.' }
& terraform "-chdir=$($script:InfraRoot)" validate
if ($LASTEXITCODE -ne 0) { throw 'Terraform validation failed.' }

# Create the full control plane with zero tasks before the seed image is pushed.
# This avoids a Terraform target-only apply and leaves the ECR repository in state.
& terraform "-chdir=$($script:InfraRoot)" apply -auto-approve -input=false -var desired_count=0
if ($LASTEXITCODE -ne 0) { throw 'Terraform control-plane bootstrap apply failed.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'seed-bootstrap.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Bootstrap image preparation failed.' }

& terraform "-chdir=$($script:InfraRoot)" apply -auto-approve -input=false
if ($LASTEXITCODE -ne 0) { throw 'Terraform infrastructure apply failed.' }

$iamEnv = docker inspect shipstack-ecs-localstack --format '{{range .Config.Env}}{{println .}}{{end}}' 2>$null | Select-String '^ENFORCE_IAM='
if ($iamEnv) { Write-Host "IAM_ENFORCEMENT=$iamEnv" } else { Write-Warning 'IAM_ENFORCEMENT=NOT_ENABLED in the project LocalStack process.' }
Write-Host 'LOCALSTACK_INFRA_DEPLOYED'
