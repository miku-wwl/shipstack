$ErrorActionPreference = 'Stop'
$targetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location (Join-Path $targetRoot 'app')
try {
    mvn -B package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw 'Maven package failed.' }
} finally { Pop-Location }
