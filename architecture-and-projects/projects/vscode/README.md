# VSCode 机器人中台开发指南

## 0. 目录结构与快速上手

- `host/install_host_extensions.sh`：宿主机 VSCode 桥梁插件一键安装脚本。
- `templates/`：ROS 2 + C++ Dev Container 标准项目模板（内置 `src/example_cpp` 验证工程）。

**首次初始化与验证：**
1. **初始化宿主机**（确保已安装 VSCode 与 Docker / OrbStack）：
   ```bash
   ./host/install_host_extensions.sh
   ```
2. **以 Dev Container 模式打开模板工程**：
   ```bash
   ./templates/open_devcontainer.sh
   ```
3. **容器内编译与测试验证**（在 VSCode 集成终端中执行）：
   ```bash
   make build   # 默认 Debug 模式（Ninja + ccache），自动生成 build/compile_commands.json
   make test    # 运行工作区单元测试并输出汇总
   ```
4. **验证节点运行与代码跳转**：
   - 终端 1 执行 `source install/setup.bash && ros2 run example_cpp talker`
   - 终端 2 执行 `source install/setup.bash && ros2 run example_cpp listener`
   - 打开 `src/example_cpp/src/talker.cpp`，按 `F12` 确认 `rclcpp::Node` 跳转正常。

## 1. 场景定位与核心架构（C++ 机器人中台 + Docker）

- **开发形态痛点**：中台代码仓体积大、跨模块依赖深、构建环境强绑定 Ubuntu/ROS/Docker 容器，且需要避免污染本地电脑环境。
- **推荐核心架构（Local UI + Dev Containers）**：
  - **本地零污染**：宿主机仅安装 VSCode（纯界面壳子）与 Docker（macOS 推荐 OrbStack），不在容器内安装桌面版 VSCode 或使用 VNC。
  - **容器内闭环**：编译器、ROS 环境、GDB、`clangd` 及 C++ 插件全部运行在容器内，由 VSCode 自动注入轻量 `vscode-server` 衔接。
  - **核心工具链**：`Dev Containers` / `Remote - SSH` + `clangd`（基于 `compile_commands.json`）+ `CMake Tools` / `Ninja`。
- **多架构开发原则**：同一份 `Dockerfile` 通过 `buildx` 维护 `amd64` / `arm64` 双架构镜像，Mac（ARM）与 Linux（x86）研发均拉取本机原生镜像，避免跨架构模拟编译导致的严重性能损耗。
- **大仓性能与索引优化**：通过 `files.exclude` / `search.exclude` 屏蔽 `build/`、`install/`、`log/` 等产物目录，避免卡顿与误搜：

```json
// .vscode/settings.json
{
  "files.exclude": {
    "**/build": true,
    "**/install": true,
    "**/log": true
  },
  "search.exclude": {
    "**/build": true,
    "**/install": true,
    "**/log": true,
    "**/third_party": true
  }
}
```

## 2. 环境边界与安装清单（本机 vs Dockerfile vs 容器内插件）

明确“什么装在本机、什么打进镜像、什么由配置自动装”，新人按表核对即可完成环境初始化：

| 归属层级 | 负责安装的内容 | 说明 / 维护方式 |
| :--- | :--- | :--- |
| **本机（宿主机）**<br>基础软件 | • VSCode 本体<br>• Docker（macOS 推荐 OrbStack）<br>• Git（管理本地 SSH Key 与初始拉仓） | 研发人员自行安装，**严禁**在本机折腾 ROS / C++ 编译器 |
| **本机 VSCode**<br>必装插件（仅 3 个） | • `Dev Containers`<br>• `Remote - SSH`<br>• `Docker` | 连接容器的“桥梁”插件；其余主题、字体、快捷键等个人偏好插件按需装在本机 |
| **`Dockerfile.base`**<br>（通用基础镜像底座） | • **用户与权限**：Ubuntu 基础镜像、非 root 的 `develop` 用户<br>• **编译与调试**：`gcc/g++`、`cmake`、`ninja`、`colcon`、`ccache`、`clangd`、`clang-format`、`gdb`<br>• **机器人底座**：ROS 2 Base 环境<br>• **通用 Linux 与排障 CLI**：`git`、`vim`、`tmux`、`ripgrep`、`tree`、`procps` (`ps`/`top`)、`htop`、`psmisc`、`lsof`、`strace`、`file`、`iproute2`、`ping`、`dnsutils`、`nc`、`wget`、`rsync`、`zip/unzip`、`jq` | 稳定底座，低频变更，团队统一维护并推送至私有镜像仓库 |
| **`Dockerfile.develop`**<br>（项目级研发与质检层） | • **代码质量门禁**：`clang-tidy`、`doxygen`、`pre-commit`、`gitlint`<br>• **测试与基准库**：`libgtest-dev`（GoogleTest）、`libbenchmark-dev`（Google Benchmark）<br>• **项目源码与环境**：拷贝工作区并自动 source `install/setup.bash` | 继承 `base` 镜像，按项目/中台规范快速迭代重建，开箱满足 `make check` / `pre-commit` 全检 |
| **`.devcontainer/devcontainer.json`**<br>（容器内自动安装的 VSCode 插件） | • **C++ 与构建**：`clangd` 插件、`CMake Tools`、`Makefile Tools`<br>• **机器人与配置**：`ROS`、`URDF`、`YAML`、`XML`<br>• **协作与效率**：`GitLens`、`Git Graph`、`Error Lens`、`Todo Tree`<br>• **AI 辅助**：`4copy`、团队合规 AI 插件（如 `Continue` / `Copilot`） | 随 Git 仓库分发；首次进入容器时由 VSCode 自动安装，**无需在 Dockerfile 里手动安装插件** |

## 3. 常用插件体系（按核心场景分类）

### 3.1 C++ 语言服务、构建与代码规范
- **语言服务与补全底座**：`clangd`（推荐主力）vs `C/C++ (Microsoft)`。
  - `clangd` 基于 `compile_commands.json` 索引，大仓跳转速度与复杂 C++ 模板推导显著优于默认 IntelliSense。
  - 若同时安装 Microsoft `C/C++`（仅用于复用其 `cppdbg` 调试器），需在配置中关闭其 IntelliSense 避免冲突：
    ```json
    "C_Cpp.intelliSenseEngine": "disabled"
    ```
- **工程构建与调试**：`CMake Tools`、`Makefile Tools`（多目标切换、一键构建与 Debug，贴近 CLion 工程体验）。若需临时编译运行单个 C++ 文件/算法片段，可配合 `Code Runner` 或自定义 `tasks.json`。
- **代码格式化与静态检查**：配合仓库级 `.clang-format`（保存自动格式化）与 `.clangd` 配置，统一中台代码风格、减少 Review 噪音。
- **机器人生态辅助（按需）**：`ROS` / `URDF` / `YAML` / `XML`。

### 3.2 Docker 与远程 / CI 开发
- **容器与远程开发**：`Dev Containers`、`Remote - SSH`（宿主机无缝挂载进 Ubuntu/ROS 容器内编码与调试）。
- **容器管理**：`Docker`（镜像、容器状态、日志查看及 Dockerfile 语法检查）。
- **CI / 流水线辅助**：`GitLab Workflow` / `GitHub Actions`（编辑器内查看流水线状态与 YAML 校验）。

### 3.3 AI 辅助开发（上下文提取 & 代码补全）
- **前提与合规说明**：
  - AI 对 C++ 复杂模板与跨文件调用的补全准确度，高度依赖 `clangd` + `compile_commands.json` 提供的符号索引。
  - **代码保密红线**：明确团队允许使用的 AI 工具范围（内网私有模型 vs 商业版插件），严禁将核心中台代码上传至未授权的公网服务。
- **上下文打包插件（现有特色）**：`4copy`（及同类如 `Copy4AI`）—— 一键复制选定目录结构与多文件源码到剪贴板，适合向网页版 AI 投喂完整上下文或内网排查。
- **AI 代码补全与对话插件**：
  - `GitHub Copilot`：生态成熟，行内补全与多文件 Agent 重构能力强，C++ 样板代码/STL 逻辑稳定。
  - `Continue` / `Cline`（开源 + BYOM）：支持接入本地部署模型（如 Ollama + DeepSeek/Qwen）或公司私有 API，适合保密/离线内网环境。
  - `Windsurf (原 Codeium)`：轻量、响应快，适合日常 C++/Python/Shell 混合开发（按合规要求选用）。

### 3.4 Git 版本控制与协作
- `GitLens`：行级 Blame 溯源、提交历史与中台多人协作排查。
- `Git Graph`：分支拓扑可视化、Cherry-pick 与合并冲突直观查看。

### 3.5 代码阅读与通用效率
- `Error Lens`：行内实时高亮编译与静态分析报错。
- `Todo Tree` / `Bookmarks`：长链路源码阅读时的关键节点标记。

## 4. VSCode 高频核心技巧（中台 & Docker 实战）

- **Docker DevContainer 极简实践**：
  - **权限简化**：在 `Dockerfile` 内直接创建非 root 的 `develop` 用户并设为默认用户，避免宿主机与容器文件权限错乱。
  - **自动化配置**：通过 `.devcontainer/devcontainer.json` 自动安装容器内项目级插件、配置 `compile_commands.json` 路径及 GDB/LLDB 调试权限（`SYS_PTRACE`）：
    ```json
    {
      "name": "robotics-middleware-dev",
      "image": "registry.example.com/robotics/dev:latest",
      "remoteUser": "develop",
      "runArgs": ["--cap-add=SYS_PTRACE", "--security-opt", "seccomp=unconfined"],
      "customizations": {
        "vscode": {
          "extensions": [
            "llvm-vs-code-extensions.vscode-clangd",
            "ms-vscode.cmake-tools",
            "eamodio.gitlens",
            "usernamehw.errorlens"
          ]
        }
      }
    }
    ```
  - **macOS 磁盘 I/O 优化**：大仓编译卡顿时，推荐配合 OrbStack 或 Docker Named Volume 提升挂载读写速度。
- **构建与调试配置**：
  - `tasks.json`：一键触发 `cmake` / `colcon` / `just` 构建任务（如 `colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`）。
  - `launch.json`：一键启动 Debug 或 Attach 到运行中的中台守护进程 / 机器人节点。
- **中台调试与可视化链路**：
  - **日常主力（终端/SSH）**：直接在容器集成终端或通过 SSH 打印日志与 Topic 数据（如 `ros2 topic echo`），保持环境轻量与隔离。
  - **可视化扩展（预留/按需）**：中台本地暂不强依赖图形界面（重度点云/RViz 交由专用机器）；后续如需本地看图，预留通过端口映射接入 Foxglove 及配置 `ROS_DOMAIN_ID` 隔离的方案。
- **源码阅读与重构技巧**：Outline 大纲、Call Hierarchy 调用层级、正则跨文件检索与 `F2` 全局符号重命名。
- **环境同步原则**：项目级插件统一写入 `devcontainer.json` 随 Git 分发；个人主题、字体与快捷键通过 `Settings Sync` 同步（如需命令行迁移本机插件，可使用 `code --list-extensions > extensions.txt`）。

## 5. 常用快捷键速查（macOS / Linux-Win 对照）

### 5.1 全局面板与窗口管理

| 功能 | macOS | Linux / Windows |
| :--- | :--- | :--- |
| 打开命令面板 | `Cmd + Shift + P` / `F1` | `Ctrl + Shift + P` / `F1` |
| 快速打开文件 | `Cmd + P` | `Ctrl + P` |
| 切换集成终端 | ``Ctrl + ` `` | ``Ctrl + ` `` |
| 新建集成终端 | ``Ctrl + Shift + ` `` | ``Ctrl + Shift + ` `` |
| 显示/隐藏侧边栏 | `Cmd + B` | `Ctrl + B` |
| 编辑器向右分屏 | `Cmd + \` | `Ctrl + \` |
| 切换分屏焦点 | `Cmd + 1 / 2 / 3` | `Ctrl + 1 / 2 / 3` |

### 5.2 代码阅读与快速导航

| 功能 | macOS | Linux / Windows |
| :--- | :--- | :--- |
| 跳转到定义 | `F12` / `Cmd + 单击` | `F12` / `Ctrl + 单击` |
| 窥视定义（浮窗） | `Option + F12` | `Alt + F12` |
| 查找所有引用 | `Shift + F12` | `Shift + F12` |
| 头文件 / 源文件切换（`clangd`） | `Option + O` | `Alt + O` |
| 光标历史后退 / 前进 | `Ctrl + -` / `Ctrl + Shift + -` | `Alt + Left` / `Alt + Right` |
| 当前文件符号搜索（Outline） | `Cmd + Shift + O` | `Ctrl + Shift + O` |
| 全局工作区符号搜索 | `Cmd + T` | `Ctrl + T` |
| 跳转到指定行 | `Ctrl + G` | `Ctrl + G` |

### 5.3 高效编辑与多光标批处理

| 功能 | macOS | Linux / Windows |
| :--- | :--- | :--- |
| 上下移动当前行 | `Option + Up / Down` | `Alt + Up / Down` |
| 向上/下复制当前行 | `Shift + Option + Up / Down` | `Shift + Alt + Up / Down` |
| 删除当前行 | `Cmd + Shift + K` | `Ctrl + Shift + K` |
| 选中下一个相同词（多光标） | `Cmd + D` | `Ctrl + D` |
| 选中所有相同词 | `Cmd + Shift + L` | `Ctrl + Shift + L` |
| 列选择（框选） | `Shift + Option + 鼠标拖动` | `Shift + Alt + 鼠标拖动` |
| 折叠 / 展开当前代码块 | `Option + Cmd + [` / `]` | `Ctrl + Shift + [` / `]` |
| 行注释 / 块注释 | `Cmd + /` / `Shift + Option + A` | `Ctrl + /` / `Shift + Alt + A` |

### 5.4 查找、替换与重构

| 功能 | macOS | Linux / Windows |
| :--- | :--- | :--- |
| 当前文件查找 / 替换 | `Cmd + F` / `Option + Cmd + F` | `Ctrl + F` / `Ctrl + H` |
| 全局跨文件查找 / 替换 | `Cmd + Shift + F` / `Cmd + Shift + H` | `Ctrl + Shift + F` / `Ctrl + Shift + H` |
| 查找面板切换大小写 / 全字 / 正则 | `Option + C` / `W` / `R` | `Alt + C` / `W` / `R` |
| 全局重命名符号 | `F2` | `F2` |
| 快速修复（Quick Fix） | `Cmd + .` | `Ctrl + .` |
| 格式化文档 | `Shift + Option + F` | `Shift + Alt + F` |

### 5.5 调试控制

| 功能 | macOS | Linux / Windows |
| :--- | :--- | :--- |
| 启动调试 / 继续运行 | `F5` | `F5` |
| 单步跳过（Step Over） | `F10` | `F10` |
| 单步步入（Step Into） | `F11` | `F11` |
| 单步跳出（Step Out） | `Shift + F11` | `Shift + F11` |
| 切换断点 | `F9` | `F9` |
| 停止调试 | `Shift + F5` | `Shift + F5` |

### 5.6 跨平台键位习惯建议

- **macOS 与 Linux 远程一致性**：macOS 上 `Cmd` 对应 Linux/Windows 的 `Ctrl`，但终端内 `Ctrl + C` 仍保留中断语义；建议保持默认映射，仅对个人高频冲突键（如切换终端、头文件/源文件切换）通过 `Settings Sync` 统一。
- **从 CLion 迁移**：若习惯 CLion 快捷键，可在保留 VSCode 原生操作的同时，微调 `Navigate Back/Forward` 与 `Switch Header/Source`（`clangd.switchheadersource`）即可覆盖 90% 高频导航。

## 6. 高频报错排查 FAQ

- **Q1：`clangd` 满屏红波浪线或无法跳转到定义**
  - **排查方向**：检查构建时是否开启 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`，以及工作区根目录或 `build/` 下是否存在有效的 `compile_commands.json`。
  - **常见修复**：ROS / Colcon 多包工作区可在项目根目录软链或配置 `.clangd` 指定 `CompilationDatabase: build`，修改后执行命令面板 `clangd: Restart language server`。
- **Q2：容器内 GDB 无法 Attach 进程（报错 `ptrace: Operation not permitted`）**
  - **排查方向**：Docker 默认安全策略禁用了 `ptrace` 系统调用。
  - **常见修复**：在 `.devcontainer/devcontainer.json` 的 `runArgs` 中添加 `"--cap-add=SYS_PTRACE"` 与 `"--security-opt"`, `"seccomp=unconfined"` 并重建容器。
- **Q3：容器内无法 `git pull` 或拉取私有子模块**
  - **排查方向**：容器内缺少宿主机的 SSH 私钥或未启用 SSH Agent Forwarding。
  - **常见修复**：在宿主机确认 `ssh-add -l` 有密钥加载；macOS 需确保 `~/.ssh/config` 或钥匙串配置正确，Dev Containers 会自动转发本地 `SSH_AUTH_SOCK` 到容器内。
