. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Set-LocalAwsEnvironment
$group = Get-InfraOutput -Name log_group_name
$deadline = (Get-Date).AddMinutes(3)
$events = $null
while ((Get-Date) -lt $deadline) {
    $events = & aws logs filter-log-events --log-group-name $group --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
    if ($events.events.Count -gt 0) { break }
    Start-Sleep -Seconds 10
}
if (-not $events -or $events.events.Count -lt 1) { throw "No CloudWatch Logs events found in $group." }
Write-Host "CLOUDWATCH_LOG_GROUP=$group"
Write-Host "CLOUDWATCH_EVENT_COUNT=$($events.events.Count)"
