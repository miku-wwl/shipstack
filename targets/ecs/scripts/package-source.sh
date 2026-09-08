#!/usr/bin/env bash
set -euo pipefail
RELEASE_VERSION="${1:?usage: package-source.sh <release-version> [output.zip]}"
OUTPUT_ZIP="${2:-targets/ecs/.local/source-${RELEASE_VERSION}.zip}"
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/package-source.ps1" -ReleaseVersion "$RELEASE_VERSION" -OutputZip "$OUTPUT_ZIP"
