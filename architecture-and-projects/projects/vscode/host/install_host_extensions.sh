#!/usr/bin/env bash
set -euo pipefail

# 宿主机 VSCode 极简初始化脚本：仅安装连接容器/远程开发所需的 3 个桥梁插件
# 其余 C++ / ROS / Git / AI 等项目级插件由 .devcontainer/devcontainer.json 在容器内自动安装

if ! command -v code >/dev/null 2>&1; then
  echo "[ERROR] 未检测到 'code' 命令。"
  echo "请先打开 VSCode，按 Cmd+Shift+P（Linux/Win 为 Ctrl+Shift+P），执行："
  echo "  Shell Command: Install 'code' command in PATH"
  exit 1
fi

HOST_EXTENSIONS=(
  "ms-vscode-remote.remote-containers" # Dev Containers
  "ms-vscode-remote.remote-ssh"        # Remote - SSH
  "ms-azuretools.vscode-docker"        # Docker
)

echo ">>> 开始安装宿主机 VSCode 桥梁插件..."
for ext in "${HOST_EXTENSIONS[@]}"; do
  echo "  -> 安装 ${ext}"
  code --install-extension "${ext}" --force
done

echo ">>> 宿主机桥梁插件安装完成！当前已安装插件列表："
code --list-extensions
