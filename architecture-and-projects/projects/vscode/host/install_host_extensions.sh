#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# 宿主机 VSCode 极简初始化脚本
# 功能：仅在宿主机安装连接容器/远程开发所需的 3 个桥梁插件
#      （其余 C++ / ROS 2 / Git / AI 等项目级插件由 devcontainer.json 在容器内自动安装）
# ==============================================================================

# 1. 检查 VSCode CLI (`code`) 是否已加入 PATH
if ! command -v code >/dev/null 2>&1; then
  echo "[ERROR] 未检测到 'code' 命令。"
  echo "请先打开 VSCode，按 Cmd+Shift+P（Linux/Win 为 Ctrl+Shift+P），执行："
  echo "  Shell Command: Install 'code' command in PATH"
  exit 1
fi

# 2. 安装宿主机必备的 3 个桥梁插件
HOST_EXTENSIONS=(
  "ms-vscode-remote.remote-containers" # Dev Containers：连接本地 Docker 容器
  "ms-vscode-remote.remote-ssh"        # Remote - SSH：连接远程开发机/机器人主机
  "ms-azuretools.vscode-docker"        # Docker：管理本地镜像与容器状态
)

echo ">>> 开始安装宿主机 VSCode 桥梁插件..."
for ext in "${HOST_EXTENSIONS[@]}"; do
  echo "  -> 安装 ${ext}"
  code --install-extension "${ext}" --force
done

echo ">>> 宿主机初始化完成！当前已安装插件列表："
code --list-extensions
