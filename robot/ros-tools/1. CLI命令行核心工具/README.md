# 1. CLI 命令行核心工具（`ros2` CLI）

> [返回 ROS Tools 总纲](../README.md) | [关联原理：第 6 层 `ros2` CLI 插件与 Daemon 机制](../../ros/6.%20构建、编排与系统工程层/README.md#63-命令行插件架构ros2-clirosbag2mcap与诊断工具链)
>
> **本模块核心定位**：覆盖机器人日常开发与现场排障最高频的 `ros2` 命令行体系，梳理全局通用参数规范与各子命令核心能力边界，为后续 Step 3 详尽参数速查表建立清晰索引。

---

## 一、全局通用规范：`--ros-args` 参数注入语法

在 ROS 2 中，无论是 `ros2 run` 还是直接运行 C++/Python 可执行文件，所有 ROS 框架级参数都统一收口在 `--ros-args` 之后（若需透传用户自定义参数，可用 `--` 结束 ROS 参数段）：

| 参数形式 | 作用 | 典型示例 |
| :--- | :--- | :--- |
| `-r <old>:=<new>` / `--remap` | 重映射话题、服务、节点名或命名空间 | `-r __node:=my_lidar -r __ns:=/front -r /scan:=/lidar/scan` |
| `-p <name>:=<value>` / `--param` | 启动时注入单个节点参数（支持 YAML 字面量） | `-p use_sim_time:=true -p max_vel:=1.5` |
| `--params-file <path.yaml>` | 加载整份 YAML 参数文件（可多次指定叠加） | `--params-file config/nav2_params.yaml` |
| `--log-level <level>` | 全局或按节点名设置日志级别（`DEBUG/INFO/WARN/ERROR`） | `--log-level my_node:=debug` |
| `--disable-rosout-logs` | 关闭 `/rosout` 话题上报以降低高并发日志开销 | 高频控制节点压测时常用 |

---

## 二、子命令能力大纲

### 1.1 通信与图自省工具（日常最高频）
* **`ros2 topic`**：
  * 拓扑与详情：`list`（`-t` 显示类型、`-c` 计数、`--include-hidden-topics` 含隐藏话题）、`info <topic> -v`（**排障必用**：查看发布/订阅节点名、GID 与完整 QoS 策略，一眼定位 RxO 不匹配）。
  * 数据观察与测速：`echo`（高频参数：`--qos-reliability best_effort`、`--qos-durability transient_local`、`--field data`、`--no-arr` 折叠大数组、`--once`、`--csv`）、`hz -w <window>`（测频率）、`bw`（测带宽）、`delay`（基于 `header.stamp` 测传输延迟）。
  * 构造注入与反查：`pub`（`-r <hz>`、`--once`、`--times N`、QoS 覆写）、`type`、`find <msg_type>`。
* **`ros2 node`**：`list`（`-a` 含隐藏节点）、`info <node>`（一次性列出该节点的全部 Subs / Pubs / Services / Actions）。
* **`ros2 service`**：`list -t`、`type`、`find`、`call <srv> <type> "{...}"`（同步调试短耗时接口）。
* **`ros2 action`**：`list -t`、`info <action>`、`type <action>`、`send_goal <action> <type> "{...}" --feedback`（测试导航/抓取等长耗时任务及实时反馈）。
* **`ros2 interface`**：`list`（`-m/-s/-a` 过滤）、`show <type>`（看字段定义）、`proto <type>`（**极实用**：直接生成可用于 `topic pub` / `service call` 的 YAML 模板）、`package` / `packages`。

### 1.2 参数、生命周期与组件管理
* **`ros2 param`**：`list`、`get`、`set`、`describe`（查看参数类型、取值范围与只读约束）、`dump <node>`（导出运行中节点参数为标准 YAML，调参固化神器）、`load <node> <file.yaml>`、`delete`。
* **`ros2 lifecycle`**：`nodes`、`list <node>`（查看允许的状态迁移）、`get <node>`、`set <node> <configure|activate|deactivate|cleanup|shutdown>`。
* **`ros2 component`**：`types`（查看已注册组件插件）、`list`、`load <container> <pkg> <plugin>`（动态注入进程内零拷贝容器）、`unload`、`standalone`。

### 1.3 运行编排、包管理与系统诊断
* **`ros2 run` & `ros2 launch`**：
  * `ros2 launch <pkg> <file>` 高频选项：`-s` / `--show-args`（查看所有可传入的 `LaunchArgument` 及默认值）、`-d` / `--debug`、`-n` / `--noninteractive`、`key:=value` 传参。
* **`ros2 pkg`**：`list`、`prefix <pkg>`（定位安装路径）、`executables <pkg>`、`xml <pkg>`、`create`（脚手架建包）。
* **`ros2 daemon`**：`status`、`start`、`stop`（切换 `ROS_DOMAIN_ID`、`RMW_IMPLEMENTATION` 或网络配置后图拓扑陈旧时必执行）。
* **`ros2 doctor` / `ros2 multicast`**：
  * `ros2 doctor --report` / `--report-failed`（系统环境、网络、QoS 体检）。
  * `ros2 multicast send` / `receive`（两台主机直测 UDP 多播链路是否被交换机或防火墙拦截）。
* **`ros2 control`（工业底盘/机械臂标配扩展）**：`list_controllers`、`list_hardware_interfaces`、`switch_controllers`、`set_controller_state`。

---

## 三、高频排障思考题（检验清单）

1. 用 `ros2 topic echo /scan` 一直无输出，但 `ros2 topic hz /scan` 却有频率或雷达驱动正常，最常见的 QoS 原因是什么？应该用哪条命令验证并加什么参数解决？
2. 为什么修改 `ROS_DOMAIN_ID` 或切换 DDS 配置后，`ros2 topic list` 有时依然返回旧结果？如何强制绕过后台缓存（提示：`--no-daemon` 与 `ros2 daemon stop`）？
3. 当需要手工 `ros2 topic pub` 一个嵌套层级很深的自定义消息时，如何用 `ros2 interface proto` 避免手拼 YAML 格式出错？

---

## 四、后续 Step 3 专题深潜规划

- 📌 `1.1 通信与图自省工具.md`：`topic` / `node` / `service` / `action` / `interface` 全参数速查表、QoS 覆写组合模板与常见报错对照。
- 📌 `1.2 参数生命周期与组件管理.md`：`param dump/load` 热调参工作流、`lifecycle` 状态机联调命令与 `component` 容器动态装卸实战。
- 📌 `1.3 运行编排包管理与自检.md`：`launch` 调试技巧、`daemon` 排坑、`doctor` 报告解读、`multicast` 联调与 `ros2 control` 常用命令。
