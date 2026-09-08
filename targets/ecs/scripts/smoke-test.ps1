param([string]$ExpectedVersion = '')
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Set-LocalAwsEnvironment
$endpoint = Get-InfraOutput -Name alb_endpoint
if ([string]::IsNullOrWhiteSpace($endpoint)) { throw 'ALB endpoint output is empty.' }
$endpoint = $endpoint.TrimEnd('/')
if ($endpoint -notmatch ':[0-9]+$') { $endpoint = "$endpoint`:4567" }
$deadline = (Get-Date).AddMinutes(5)
$responses = @{}
while ((Get-Date) -lt $deadline) {
    try {
        $responses.hello = Invoke-RestMethod "$endpoint/api/v1/hello" -TimeoutSec 10
        $responses.version = Invoke-RestMethod "$endpoint/api/v1/version" -TimeoutSec 10
        $responses.health = Invoke-RestMethod "$endpoint/actuator/health" -TimeoutSec 10
        if ($responses.health.status -eq 'UP') { break }
    } catch { Start-Sleep -Seconds 10 }
}
if (-not $responses.health -or $responses.health.status -ne 'UP') { throw "ALB smoke test did not reach a healthy application: $endpoint" }
if ($ExpectedVersion -and $responses.version.version -ne $ExpectedVersion) { throw "Expected version '$ExpectedVersion', got '$($responses.version.version)'." }
Write-Host "ALB_ENDPOINT=$endpoint"
Write-Host "HELLO_RESPONSE=$($responses.hello | ConvertTo-Json -Compress)"
Write-Host "VERSION_RESPONSE=$($responses.version | ConvertTo-Json -Compress)"
Write-Host "HEALTH_RESPONSE=$($responses.health | ConvertTo-Json -Compress)"
