#!/usr/bin/env bash
set -euo pipefail
EXPECTED_VERSION="${1:?usage: validate-ecs.sh <expected-version>}"
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/validate-ecs.ps1" -ExpectedVersion "$EXPECTED_VERSION"
