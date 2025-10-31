#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[run_checks] Ensuring virtual environment..." >&2
"${ROOT_DIR}/scripts/create_venv.sh" >/dev/null

source "${ROOT_DIR}/.venv/bin/activate"

export TZ="UTC"
export HOST="${HOST:-127.0.0.1}"
export PORT="${PORT:-8080}"

echo "[run_checks] Running API selftest" >&2
python "${ROOT_DIR}/api/main.py" --selftest

echo "[run_checks] Exercising integration workflow" >&2
python "${ROOT_DIR}/scripts/integration_demo.py"

echo "[run_checks] All checks passed" >&2
