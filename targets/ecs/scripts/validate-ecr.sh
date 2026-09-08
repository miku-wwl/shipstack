#!/usr/bin/env bash
set -euo pipefail
RELEASE_VERSION="${1:?usage: validate-ecr.sh <release-version>}"
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/validate-ecr.ps1" -ReleaseVersion "$RELEASE_VERSION"
