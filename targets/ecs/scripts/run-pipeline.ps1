param([Parameter(Mandatory)][string]$ReleaseVersion)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory
Set-LocalAwsEnvironment

$artifact = Join-Path $script:LocalDir "source-$ReleaseVersion.zip"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'package-source.ps1') -ReleaseVersion $ReleaseVersion -OutputZip $artifact
if ($LASTEXITCODE -ne 0) { throw "Source packaging failed for $ReleaseVersion." }

$bucket = Get-InfraOutput -Name artifact_bucket_name
$key = Get-InfraOutput -Name source_object_key
$pipeline = Get-InfraOutput -Name codepipeline_name
& aws s3 cp $artifact "s3://$bucket/$key" --endpoint-url $script:Endpoint
if ($LASTEXITCODE -ne 0) { throw 'Source artifact upload failed.' }

$start = & aws codepipeline start-pipeline-execution --name $pipeline --query pipelineExecutionId --output text --endpoint-url $script:Endpoint
if ($LASTEXITCODE -ne 0) { throw 'CodePipeline start failed.' }
$executionId = $start.Trim()
Write-Host "PIPELINE_EXECUTION_ID=$executionId"

$deadline = (Get-Date).AddMinutes(12)
$state = ''
while ((Get-Date) -lt $deadline) {
    $json = & aws codepipeline get-pipeline-execution --pipeline-name $pipeline --pipeline-execution-id $executionId --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
    $state = [string]$json.pipelineExecution.status
    Write-Host "PIPELINE_STATUS=$state release=$ReleaseVersion"
    if ($state -in @('Succeeded','Failed','Stopped','Stopping','Superseded')) { break }
    Start-Sleep -Seconds 10
}
if ($state -ne 'Succeeded') {
    $actions = $null
    try {
        $actions = & aws codepipeline list-action-executions --pipeline-name $pipeline --filter "pipelineExecutionId=$executionId" --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
    } catch { }

    # LocalStack 2026.8 may leave a V1 ECS deploy execution in InProgress, or
    # report "Waiter ServicesStable failed: Max attempts exceeded", after the
    # CodeBuild artifact is uploaded and the ECS service is stable. Accept only
    # independently observable completion; never turn an arbitrary failure into
    # a pass.
    $buildAction = $actions.actionExecutionDetails | Where-Object { $_.actionName -eq 'BuildAndPush' } | Select-Object -First 1
    $deployAction = $actions.actionExecutionDetails | Where-Object { $_.actionName -eq 'DeployToECS' } | Select-Object -First 1
    $deployWaiterFailure = $deployAction.status -eq 'Failed' -and
        [string]$deployAction.output.executionResult.errorDetails.message -match 'Waiter ServicesStable failed: Max attempts exceeded'
    if (($state -eq 'InProgress' -or $deployWaiterFailure) -and $buildAction.status -eq 'Succeeded') {
        $cluster = Get-InfraOutput -Name ecs_cluster_name
        $service = Get-InfraOutput -Name ecs_service_name
        $serviceJson = & aws ecs describe-services --cluster $cluster --services $service --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
        $svc = $serviceJson.services | Select-Object -First 1
        $taskDef = [string]$svc.taskDefinition
        $td = & aws ecs describe-task-definition --task-definition $taskDef --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
        $image = [string]($td.taskDefinition.containerDefinitions | Select-Object -First 1).image
        if ($svc -and [int]$svc.desiredCount -ge 1 -and [int]$svc.runningCount -ge [int]$svc.desiredCount -and $image -match ":$([regex]::Escape($ReleaseVersion))$") {
            Write-Warning "LocalStack did not report a clean CodePipeline terminal status; BuildAndPush and independent ECS deployment evidence are complete."
            Write-Host "PIPELINE_STATUS=LOCALSTACK_ECS_DEPLOY_COMPLETED release=$ReleaseVersion"
            if ($buildAction.output.executionResult.externalExecutionId) {
                Write-Host "CODEBUILD_BUILD_ID=$($buildAction.output.executionResult.externalExecutionId)"
            }
            Write-Host "PIPELINE_EXECUTED=$ReleaseVersion"
            exit 0
        }
    }

    if ($actions) { $actions | ConvertTo-Json -Depth 12 }
    throw "CodePipeline execution $executionId ended with state '$state'."
}

$actions = & aws codepipeline list-action-executions --pipeline-name $pipeline --filter "pipelineExecutionId=$executionId" --output json --endpoint-url $script:Endpoint | ConvertFrom-Json
$buildAction = $actions.actionExecutionDetails | Where-Object { $_.actionName -eq 'BuildAndPush' } | Select-Object -First 1
if ($buildAction -and $buildAction.output.executionResult.externalExecutionId) {
    Write-Host "CODEBUILD_BUILD_ID=$($buildAction.output.executionResult.externalExecutionId)"
}
Write-Host "PIPELINE_EXECUTED=$ReleaseVersion"
