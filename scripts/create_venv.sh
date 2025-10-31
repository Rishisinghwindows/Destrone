#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

if [ -d "${VENV_DIR}" ]; then
  echo "Virtual environment already exists at ${VENV_DIR}" >&2
else
  python3 -m venv "${VENV_DIR}"
  echo "Created virtual environment at ${VENV_DIR}" >&2
fi

source "${VENV_DIR}/bin/activate"

REQ_FILE="${ROOT_DIR}/api/requirements.txt"
if [ -f "${REQ_FILE}" ] && grep -qE "^[[:alnum:]]" "${REQ_FILE}"; then
  PIP_DEFAULT_TIMEOUT=${PIP_DEFAULT_TIMEOUT:-20} \
  python -m pip install -r "${REQ_FILE}" || \
    echo "Warning: failed to install requirements (check network access)" >&2
else
  echo "No additional Python packages to install" >&2
fi

echo "Virtual environment ready. Activate with: source ${VENV_DIR}/bin/activate" >&2
