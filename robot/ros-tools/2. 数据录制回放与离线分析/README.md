# 2. 数据录制回放与离线分析（`ros2 bag` & MCAP）

> [返回 ROS Tools 总纲](../README.md) | [关联原理：第 6 层 `rosbag2` 插件化与 MCAP 存储架构](../../ros/6.%20构建、编排与系统工程层/README.md#63-命令行插件架构ros2-clirosbag2mcap与诊断工具链)
>
> **本模块核心定位**：沉淀机器人研发中最核心的“黑匣子”数据闭环工具链——涵盖在线录制、高保真回放、大包离线裁剪压缩以及免 ROS 环境的 Python 数据提取。

---

## 一、核心版本差异速览（Humble vs Jazzy）

| 维度 | ROS 2 Humble | ROS 2 Jazzy | 工程实践建议 |
| :--- | :--- | :--- | :--- |
| **默认存储格式** | `sqlite3`（`.db3`，异常断电易锁库损坏） | **`mcap`**（`.mcap`，单文件自包含 Schema） | Humble 环境下**强烈建议安装 `ros-humble-rosbag2-storage-mcap` 并显式加 `-s mcap`**。 |
| **服务录制支持** | 基础话题为主 | 原生支持 Service 录制与回放 | 复杂系统联调时按需开启 `--services`。 |
| **正则排除参数** | `-x` / `--exclude <regex>` | **`--exclude-regex <regex>`** | Jazzy 移除了 `-x` 短参数，跨版本写录制脚本时需注意区分。 |

---

## 二、本模块核心工具大纲

### 2.1 `ros2 bag` 录制与回放高频参数骨架
* **录制（`ros2 bag record`）**：
  * 目标过滤：`-a`（全量录制）、`-e <regex>`（正则包含）、`-x <regex>`（Humble）/ `--exclude-regex <regex>`（Jazzy，正则排除大流量原始图像/点云，如 `".*image_raw.*"`）、`--include-hidden-topics`。
  * 存储与防爆盘：`-s mcap`、`-o <output_dir>`、`-b <bytes>` / `--max-bag-size`（按体积自动切分）、`-d <sec>` / `--max-bag-duration`（按时长切分）、`--compression-mode file|message` + `--compression-format zstd`（高速高压缩比）。
  * 时序与 QoS：`--use-sim-time`、`--qos-profile-overrides-path <qos.yaml>`（解决特殊传感器 QoS 录不进问题）。
* **回放（`ros2 bag play`）**：
  * 节奏与定位：`-r <rate>`（倍速）、`-l`（循环）、`--start-offset <sec>`（跳到故障前几秒）、`--clock [hz]`（发布 `/clock` 驱动仿真时间，配合下游节点 `use_sim_time:=true`）。
  * 过滤与重映射：`--topics <t1> <t2>`、`--remap /old:=/new`、`--qos-profile-overrides-path <qos.yaml>`。
  * 交互快捷键：运行中按 `Space` 暂停/继续、`→` 单帧步进、`↑/↓` 动态调速。
* **维护与转换**：`ros2 bag info`（查看时长、消息数、话题列表与存储格式）、`ros2 bag reindex`（修复异常断电未生成 `metadata.yaml` 的残包）、`ros2 bag convert`（`.db3` ↔ `.mcap` 转换或二次裁剪）。

### 2.2 `mcap` 独立命令行工具（Foxglove 官方）
* 无需安装任何 ROS 环境即可在服务器/本地高速处理 GB/TB 级 `.mcap` 文件：
  * `mcap info <file.mcap>`：查看 Chunk 统计、压缩率、各通道消息数与时间跨度。
  * `mcap filter`：按起止时间戳（`--start` / `--end`）或话题名（`-y` / `-n`）秒级切片提取故障片段。
  * `mcap merge`：合并多个分段录制的 `.mcap` 文件。
  * `mcap compress` / `mcap doctor` / `mcap recover`：离线重压缩、完整性体检与损坏包恢复。

### 2.3 Python 离线解包与批量分析
* **`rosbags`（纯 Python 库，零 ROS 依赖）**：同时支持 ROS 1 `.bag`、ROS 2 `.db3` 与 `.mcap` 读取与格式互转，适合在算法服务器、macOS/Windows 上批量导出 CSV / 图片 / 点云。
* **`rosbag2_py` / `mcap-ros2-support`**：结合官方反序列化接口与 `pandas` / `numpy` 构建自动化回归评测脚本。

---

## 三、高频排障思考题（检验清单）

1. 录制包含相机原始图像的大流量数据包时，如何避免写盘带宽打满导致丢帧？（提示：`--max-cache-size`、`-x` / `--exclude-regex` 排除未压缩流只录 `compressed`、`zstd` 压缩与独立 NVMe 盘）
2. 为什么回放数据包时算法节点报 TF 时间戳严重滞后，仅仅加 `--clock` 够吗？下游节点还必须配合什么参数？
3. 机器人现场突然断电导致 `ros2 bag record` 没来得及写 `metadata.yaml`，如何抢救已经落盘的数据？

---

## 四、后续 Step 3 专题深潜规划

- 📌 `2.1 ros2_bag与MCAP实战速查.md`：完整参数表、QoS 覆写 YAML 模板、异常断电恢复步骤与实车防爆盘录制脚本。
- 📌 `2.2 离线解包与Python数据分析脚本.md`：`mcap` CLI 常用命令组合与 `rosbags` 批量导出 CSV/图像/点云的代码模板。
