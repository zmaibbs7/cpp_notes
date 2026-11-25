# 支持多架构构建：docker buildx build --platform linux/amd64,linux/arm64 ...
ARG ROS_DISTRO=noetic
FROM ros:${ROS_DISTRO}-ros-base

ARG USERNAME=develop
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV DEBIAN_FRONTEND=noninteractive

# 安装 C++ 编译构建、调试、语言服务底座与 CLI 提效工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    ca-certificates \
    build-essential \
    cmake \
    ninja-build \
    ccache \
    clangd \
    clang-format \
    gdb \
    lldb \
    git \
    vim \
    tmux \
    ripgrep \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 开发用户（避免宿主机与容器挂载目录权限错乱）
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}
WORKDIR /workspace

# 自动加载 ROS 环境变量
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> "/home/${USERNAME}/.bashrc"
