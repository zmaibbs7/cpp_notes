#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# 一键以 VSCode Dev Container 模式打开当前项目（无需先开本地窗口再点弹窗）
# 用法：./open_devcontainer.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v code >/dev/null 2>&1; then
  echo "[ERROR] 未检测到 'code' 命令，请先在 VSCode 中执行："
  echo "  Shell Command: Install 'code' command in PATH"
  exit 1
fi

# 从 devcontainer.json 读取容器内工作目录（默认 /workspace）
WORKSPACE_FOLDER="/workspace"
DEVCONTAINER_JSON="${SCRIPT_DIR}/.devcontainer/devcontainer.json"
if [[ -f "${DEVCONTAINER_JSON}" ]] && command -v python3 >/dev/null 2>&1; then
  WORKSPACE_FOLDER="$(python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    print(json.load(f).get("workspaceFolder", "/workspace"))
' "${DEVCONTAINER_JSON}")"
fi

# 将项目绝对路径编码为 16 进制（VSCode dev-container URI 规范）
if command -v xxd >/dev/null 2>&1; then
  HEX_PATH="$(printf "%s" "${SCRIPT_DIR}" | xxd -p -c 256 | tr -d '\n')"
elif command -v python3 >/dev/null 2>&1; then
  HEX_PATH="$(python3 -c 'import sys; print(sys.argv[1].encode("utf-8").hex())' "${SCRIPT_DIR}")"
else
  echo "[ERROR] 需要 xxd 或 python3 来编码项目路径" >&2
  exit 1
fi

echo ">>> 正在以 Dev Container 模式打开: ${SCRIPT_DIR} -> ${WORKSPACE_FOLDER}"
code --folder-uri "vscode-remote://dev-container+${HEX_PATH}${WORKSPACE_FOLDER}"
