#!/usr/bin/env bash
set -euo pipefail
RELEASE_VERSION="${1:?usage: run-pipeline.sh <release-version>}"
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/run-pipeline.ps1" -ReleaseVersion "$RELEASE_VERSION"
