#!/usr/bin/env bash
set -euo pipefail

# 统一镜像构建入口脚本（支持构建 base / develop，默认仅构建 develop）
# 镜像 Tag 自动从 Dockerfile.base 中的 ROS_DISTRO 读取（如 humble）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKERFILE_BASE="${SCRIPT_DIR}/Dockerfile.base"
DOCKERFILE_DEVELOP="${SCRIPT_DIR}/Dockerfile.develop"

# 从 Dockerfile.base 自动解析版本变量
parse_arg() {
  local key="$1"
  local file="$2"
  grep -E "^ARG[[:space:]]+${key}=" "${file}" | head -n 1 | cut -d'=' -f2- | tr -d '[:space:]"'\'''
}

ROS_DISTRO="$(parse_arg "ROS_DISTRO" "${DOCKERFILE_BASE}")"
UBUNTU_VERSION="$(parse_arg "UBUNTU_VERSION" "${DOCKERFILE_BASE}")"
IMAGE_TAG="${ROS_DISTRO:-humble}"

BASE_IMAGE_NAME="robotics-base"
DEVELOP_IMAGE_NAME="robotics-develop"

BUILD_BASE=false
BUILD_DEVELOP=false
INTERACTIVE=false

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

默认行为（无参数）: 仅构建 ${DEVELOP_IMAGE_NAME}:${IMAGE_TAG}

选项:
  -b, --base          构建 base 镜像 (${BASE_IMAGE_NAME}:${IMAGE_TAG})
  -d, --develop       构建 develop 镜像 (${DEVELOP_IMAGE_NAME}:${IMAGE_TAG})
  -a, --all           依次构建 base 和 develop 镜像
  -i, --interactive   交互式选择要构建的镜像（直接回车默认仅构建 develop）
  -t, --tag <tag>     手动覆盖镜像 Tag（默认自动读取 Dockerfile.base 的 ROS_DISTRO=${IMAGE_TAG}）
  -h, --help          显示帮助信息

示例:
  $(basename "$0")                 # 默认仅构建 develop
  $(basename "$0") --base          # 仅构建 base
  $(basename "$0") --all           # 构建 base + develop
  $(basename "$0") -i              # 交互式勾选
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--base)
      BUILD_BASE=true
      shift
      ;;
    -d|--develop)
      BUILD_DEVELOP=true
      shift
      ;;
    -a|--all)
      BUILD_BASE=true
      BUILD_DEVELOP=true
      shift
      ;;
    -i|--interactive)
      INTERACTIVE=true
      shift
      ;;
    -t|--tag)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --tag 需要指定参数值" >&2
        exit 1
      fi
      IMAGE_TAG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] 未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "${INTERACTIVE}" == "true" ]]; then
  echo "检测到 Dockerfile.base 配置: Ubuntu=${UBUNTU_VERSION:-unknown}, ROS_DISTRO=${ROS_DISTRO:-unknown}"
  echo "请选择要构建的镜像:"
  echo "  1) 仅构建 develop (默认)"
  echo "  2) 仅构建 base"
  echo "  3) 构建 base + develop"
  read -r -p "请输入选项 [1/2/3，直接回车默认 1]: " choice
  case "${choice:-1}" in
    1)
      BUILD_BASE=false
      BUILD_DEVELOP=true
      ;;
    2)
      BUILD_BASE=true
      BUILD_DEVELOP=false
      ;;
    3)
      BUILD_BASE=true
      BUILD_DEVELOP=true
      ;;
    *)
      echo "[ERROR] 无效选项: ${choice}" >&2
      exit 1
      ;;
  esac
fi

# 未做任何选择时，默认只构建 develop
if [[ "${BUILD_BASE}" == "false" && "${BUILD_DEVELOP}" == "false" ]]; then
  BUILD_DEVELOP=true
fi

echo ">>> 镜像 Tag: ${IMAGE_TAG} (读取自 Dockerfile.base: ROS_DISTRO=${ROS_DISTRO})"

if [[ "${BUILD_BASE}" == "true" ]]; then
  echo ">>> [1/2] 开始构建 ${BASE_IMAGE_NAME}:${IMAGE_TAG} ..."
  docker build \
    -t "${BASE_IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${DOCKERFILE_BASE}" \
    "${SCRIPT_DIR}"
fi

if [[ "${BUILD_DEVELOP}" == "true" ]]; then
  echo ">>> [2/2] 开始构建 ${DEVELOP_IMAGE_NAME}:${IMAGE_TAG} (基于 ${BASE_IMAGE_NAME}:${IMAGE_TAG}) ..."
  docker build \
    --build-arg "BASE_IMAGE=${BASE_IMAGE_NAME}:${IMAGE_TAG}" \
    -t "${DEVELOP_IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${DOCKERFILE_DEVELOP}" \
    "${PROJECT_ROOT}"
fi

echo ">>> 构建完成！当前相关镜像："
docker images | grep -E "REPOSITORY|${BASE_IMAGE_NAME}|${DEVELOP_IMAGE_NAME}" || true
