# 3. 可视化与 GUI 调试工具（RViz2 / Foxglove / PlotJuggler / rqt）

> [返回 ROS Tools 总纲](../README.md)
>
> **本模块核心定位**：覆盖感知三维可视化、远程真机监控、高频控制曲线分析与系统拓扑观察四大 GUI 场景，帮助工程师在不同场景下选对最高效的可视化武器。

---

## 一、主流可视化工具选型矩阵

| 工具 | 核心优势 | 最适合场景 | 典型短板 |
| :--- | :--- | :--- | :--- |
| **RViz2** | ROS 2 原生深度集成，支持 `InteractiveMarkers` 与 `Nav2` 目标点下发 | **本地开发机实时 3D 调试**、导航/机械臂交互测试 | 跨 Wi-Fi 直连真机极易卡顿掉帧；不擅长多路时序曲线与离线大包拖拽。 |
| **Foxglove Studio**（及开源分支 Lichtblick） | 现代跨平台（Web/桌面），原生秒开 TB 级 `.mcap`；3D + 曲线 + 日志 + 视频同屏联动 | **真机远程低带宽监控（配 `foxglove_bridge`）**、**离线故障复盘**、团队共享布局 | 复杂自定义 ROS 插件扩展门槛略高于 RViz2；商业云功能付费（本地桌面端免费够用）。 |
| **PlotJuggler** | 极高帧率时序绘图、内置公式引擎（微分/滤波/四元数转 RPY）、支持实时与离线 `.mcap`/`.db3`/CSV | **运控 PID 调参、底盘里程计/IMU 标定、SLAM 轨迹误差对比** | 仅聚焦 2D 时序曲线，无 3D 场景渲染。 |
| **`rqt` 工具集** | 轻量插件化面板，随 ROS 2 生态开箱即用 | 快速查看**节点拓扑图（`rqt_graph`）**、**聚合日志（`rqt_console`）**、**动态调参（`rqt_reconfigure`）** | 界面老旧，高频大数据量下易卡顿（`rqt_plot` 已被 PlotJuggler 全面替代）。 |

---

## 二、本模块核心工具大纲

### 3.1 RViz2 实战要点
* **核心 Display 插件**：`TF`、`RobotModel`、`LaserScan`、`PointCloud2`、`Image` / `Camera`、`Marker` / `MarkerArray`、`Path`、`Map`、`Odometry`、`PoseWithCovariance`、`InteractiveMarkers`。
* **最高频两大排坑点**：
  1. **Fixed Frame 报错**：当 `Global Options -> Fixed Frame`（如 `map` 或 `odom`）在 TF 树中不存在时，所有三维数据均无法渲染；临时调试可先切为传感器自身坐标系（如 `laser_link`）。
  2. **Topic QoS 不匹配导致画面空白**：展开对应 Display 的 `Topic -> Reliability / Durability Policy`（例如静态地图 `/map` 需 `Transient Local`，激光雷达/相机常需 `Best Effort`）。
* **工程固化**：将调好的视角与插件保存为 `.rviz` 配置文件，并通过 `rviz2 -d config/debug.rviz` 或 Launch 文件一键拉起。

### 3.2 Foxglove Studio 与 `foxglove_bridge`
* **离线模式**：直接拖入 `.mcap` 文件即可时间轴秒级拖动，支持同步播放 3D 点云、相机压缩图、Plot 曲线、Raw Messages 与 `/rosout` 日志，且可导出 `.json` Layout 团队复用。
* **在线远程模式（强烈推荐用于真机）**：在机载端运行 C++ 编写的 `foxglove_bridge`（`ros2 launch foxglove_bridge foxglove_bridge_launch.xml`），通过轻量 WebSocket（默认端口 `8765`）按需订阅转发，彻底避开直接跨 Wi-Fi 跑 DDS 多播导致的带宽风暴。

### 3.3 PlotJuggler（规控与算法调优利器）
* 支持多种数据源：实时订阅 `ROS2 Topic Subscriber`、离线加载 `.mcap`/`.db3`/CSV。
* 核心高效功能：拖拽信号分屏对比、时间轴全局联动、内置 `Custom Series`（Lua 脚本实时计算四元数 → Roll/Pitch/Yaw、速度微分加速度、目标值与实际值残差曲线）。

### 3.4 `rqt` 经典工具集
* `rqt_graph`：排查节点命名空间拼错、Topic 重映射失败导致的“断链”（注意取消勾选 `Hide: Dead sinks / Leaf topics` 查看全貌）。
* `rqt_console`：跨节点聚合 `/rosout` 日志，支持按级别过滤、节点筛选与关键字高亮。
* `rqt_reconfigure`（`ros2 run rqt_reconfigure rqt_reconfigure`）：可视化滑块/下拉框实时修改支持动态更新的节点参数。
* `rqt_image_view` / `rqt_service_caller` / `rqt_tf_tree`：轻量单用途调试面板。

---

## 三、高频排障思考题（检验清单）

1. 在 RViz2 中添加了 `/map` 话题但画面一直不显示，同时终端日志出现 `New publisher discovered on topic '/map', offering incompatible QoS`，应当在 RViz2 界面中调整哪两个 QoS 选项？
2. 为什么在真机通过 Wi-Fi 联调时，往往推荐“机载跑 `foxglove_bridge` + 笔记本开 Foxglove”而不是“笔记本直接开 RViz2 连同一 `ROS_DOMAIN_ID`”？
3. 在 PlotJuggler 中如何把 `geometry_msgs/Quaternion` 转换成直观的欧拉角（Yaw）曲线来排查底盘航向漂移？

---

## 四、后续 Step 3 专题深潜规划

- 📌 `3.1 RViz2配置与自定义Marker调试指南.md`：常用 Display 参数速查、QoS 排查对照与 C++ 发布 `MarkerArray` 可视化调试范例。
- 📌 `3.2 Foxglove与PlotJuggler高效工作流.md`：`foxglove_bridge` 生产参数配置、布局模板设计及 PlotJuggler 常用 Lua 数学脚本合集。
