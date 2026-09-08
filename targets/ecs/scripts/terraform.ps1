param([Parameter(Mandatory)][ValidateSet('fmt','validate','plan','apply')][string]$Command)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalDirectory
Set-LocalAwsEnvironment
if ($Command -eq 'fmt') {
    & terraform "-chdir=$($script:InfraRoot)" fmt -check -recursive
} else {
    & terraform "-chdir=$($script:InfraRoot)" $Command -input=false @($args)
}
if ($LASTEXITCODE -ne 0) { throw "Terraform $Command failed." }
