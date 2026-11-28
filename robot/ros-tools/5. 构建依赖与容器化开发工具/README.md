# 5. 构建、依赖与容器化开发工具（`colcon` / `rosdep` / `vcs` / Docker）

> [返回 ROS Tools 总纲](../README.md) | [关联原理：第 6 层 `colcon` + `ament` 与 `.dsv` 环境加载机制](../../ros/6.%20构建、编排与系统工程层/README.md#61-构建系统colcon--ament与环境加载机制)
>
> **本模块核心定位**：沉淀大型 C++ 机器人代码仓日常高频使用的构建加速参数、依赖自动化工具、多仓库编排工具以及 Docker 开发/部署容器的最佳实践。

---

## 一、`colcon` 高频实用命令与提效技巧

* **精准增量编译（避免每次全量重编）**：
  * `--packages-select <pkg1> <pkg2>`：仅编译指定包。
  * `--packages-up-to <pkg>`：编译目标包及其所有上游依赖。
  * `--packages-above <pkg>`：修改底层公共接口包后，重编该包及其所有下游依赖。
  * `--packages-skip <pkg>`：跳过无关或暂未适配的包。
* **开发态核心选项**：
  * `--symlink-install`：对 Python、Launch、YAML、URDF 等资源建立软链接，修改后免重新 `colcon build` 即刻生效。
  * `--cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`：同时保留优化性能、调试符号，并生成 `build/compile_commands.json` 供 **VS Code / `clangd`** 实现零报错跳转与补全（可配合 `--merge-install` 或在工作空间根目录做软链）。
  * `--parallel-workers <N>` / `--executor sequential`：在内存受限的工控机（如 Jetson / 16GB 笔记本）编大模板 C++ 包（如 PCL/MoveIt）时防止 OOM 杀进程。
* **测试与依赖图查看**：`colcon test`、`colcon test-result --all --verbose`、`colcon list --topological-order`、`colcon graph --dot`。

---

## 二、依赖管理与多仓库同步（`rosdep` & `vcstool`）

### 2.1 `rosdep`（一键补齐系统与 ROS 依赖）
* 初始化与更新：`sudo rosdep init && rosdep update`（国内环境常见网络超时问题及镜像源方案）。
* 自动安装工作空间全部 `package.xml` 声明的依赖：
  ```bash
  rosdep install --from-paths src --ignore-src -r -y
  ```
* 排查缺失键：`rosdep resolve <dep_key>`、`rosdep check --from-paths src --ignore-src`。

### 2.2 `vcstool`（`vcs` 多仓库编排工具）
大型机器人项目（如 Nav2、MoveIt 2、Autoware）通常由数十个独立 Git 仓库组成，`vcs` 通过一份 `.repos` YAML 清单实现统一管理：
* `vcs import src < project.repos`：批量克隆全部子仓库到对应分支/Tag。
* `vcs pull src` / `vcs status src` / `vcs diff src`：并行拉取、查看全仓脏状态与改动。
* `vcs export src > snapshot.repos`：冻结当前所有子仓库精确 Commit Hash 用于发布归档。

---

## 三、机器人 Docker 开发容器与设备透传

机器人行业广泛采用 Docker（及 VS Code DevContainer / `rocker`）解决 Ubuntu 版本、CUDA/TensorRT 与 ROS 发行版强耦合问题。启动容器时最关键的 5 类透传参数：

| 透传需求 | 关键参数 / 配置 | 解决的问题 |
| :--- | :--- | :--- |
| **同网段 DDS 发现** | `--net=host`（配合显式 `ROS_DOMAIN_ID`） | 避开 Docker 默认 NAT 网桥阻断 UDP 多播自动发现。 |
| **跨容器共享内存（SHM）** | `--ipc=host`（必要时挂载 `/dev/shm`） | 支持 Fast DDS SHM / Iceoryx 在宿主机与容器间零拷贝通信。 |
| **GPU 加速与渲染** | `--gpus all` + `NVIDIA_DRIVER_CAPABILITIES=all` | 支持感知推理、Gazebo/Isaac Sim 与硬件加速 RViz2。 |
| **GUI 界面转发（X11）** | `-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix`（宿主机 `xhost +local:docker`） | 在容器内直接弹出 RViz2、rqt、PlotJuggler 窗口。 |
| **真机外设访问** | `--device=/dev/ttyUSB0` 或 `-v /dev:/dev --privileged` | 透传串口、相机、CAN 卡与手柄设备。 |

---

## 四、高频排障思考题（检验清单）

1. 使用 `colcon build` 时，如何在工控机上既不触发内存 OOM，又尽量利用多核编译？（提示：区分 `colcon --parallel-workers` 与 CMake/Ninja 的 `-j` / `MAKEFLAGS`）
2. 为什么在 Docker 容器里跑 ROS 2 节点，宿主机 `ros2 topic list` 经常看不到，或者能看到名字却收不到数据？（提示：`--net=host` 与 `--ipc=host` 各自的职责）
3. `clangd` 在 ROS 2 多包工作空间中经常报找不到生成的 `.hpp` 消息头文件，应如何正确合并/配置 `compile_commands.json`？

---

## 五、后续 Step 3 专题深潜规划

- 📌 `5.1 colcon与clangd工程提效手册.md`：`colcon` 默认配置文件（`defaults.yaml`）、ccache 编译加速与 VS Code `clangd` 完整配置范例。
- 📌 `5.2 机器人Docker开发环境模板.md`：面向 x86 / Jetson 的标准 `Dockerfile`、`docker-compose.yaml` 与 `devcontainer.json` 开箱模板。
