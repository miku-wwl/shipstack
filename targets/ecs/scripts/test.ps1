$ErrorActionPreference = 'Stop'
$targetRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location (Join-Path $targetRoot 'app')
try {
    mvn -B package
    if ($LASTEXITCODE -ne 0) { throw 'Maven package or test phase failed.' }
} finally { Pop-Location }
