param(
    [Parameter(Mandatory)][string]$ReleaseVersion,
    [string]$OutputZip
)
. (Join-Path $PSScriptRoot 'common.ps1')
Ensure-LocalStack
Ensure-LocalDirectory

if ([string]::IsNullOrWhiteSpace($OutputZip)) { $OutputZip = Join-Path $script:LocalDir 'source.zip' }
$stage = Join-Path $script:LocalDir "source-stage-$($ReleaseVersion -replace '[^A-Za-z0-9_.-]', '-')"
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

$repoPrefix = $script:RepoRoot.TrimEnd('\') + '\'
$files = Get-ChildItem -LiteralPath $script:RepoRoot -File -Recurse -Force | Where-Object {
    $_.FullName -notmatch '\\\.git(\\|$)' -and
    $_.FullName -notmatch '\\\.local(\\|$)' -and
    $_.FullName -notmatch '\\.terraform(\\|$)' -and
    $_.FullName -notmatch '\\target(\\|$)' -and
    $_.FullName -notmatch '\\tmp(\\|$)' -and
    $_.Name -notmatch '\.(tfstate|zip)(\.|$)'
}
foreach ($file in $files) {
    $relative = $file.FullName.Substring($repoPrefix.Length)
    $destination = Join-Path $stage $relative
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
}
$releaseDir = Join-Path $stage 'targets\ecs\release'
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $releaseDir 'APP_VERSION'), $ReleaseVersion, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $releaseDir 'RELEASE_ID'), $ReleaseVersion, $utf8NoBom)

if (Test-Path -LiteralPath $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archiveStream = [System.IO.File]::Open($OutputZip, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($archiveStream, ([System.IO.Compression.ZipArchiveMode]::Create), $false)
try {
    $stagePrefix = $stage.TrimEnd('\') + '\'
    Get-ChildItem -LiteralPath $stage -File -Recurse -Force | ForEach-Object {
        $entryName = $_.FullName.Substring($stagePrefix.Length).Replace('\', '/')
        $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $inputStream = [System.IO.File]::OpenRead($_.FullName)
        $outputStream = $entry.Open()
        try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
    }
} finally {
    $archive.Dispose()
    $archiveStream.Dispose()
}
Write-Host "SOURCE_ARTIFACT=$OutputZip"
Write-Host "RELEASE_VERSION=$ReleaseVersion"
