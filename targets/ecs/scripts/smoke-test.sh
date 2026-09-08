#!/usr/bin/env bash
set -euo pipefail
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/smoke-test.ps1" "${1:-}"
