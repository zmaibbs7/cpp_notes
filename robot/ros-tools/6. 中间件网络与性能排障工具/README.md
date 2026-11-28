# 6. 中间件、网络与性能排障工具

> [返回 ROS Tools 总纲](../README.md) | [关联原理：第 4 层 DDS/RTPS、发现风暴与 QoS 调优](../../ros/4.%20底层通信中间件与传输层/README.md)
>
> **本模块核心定位**：当 `ros2 topic` 与 GUI 工具已无法解释“为什么丢帧、为什么多机连不上、为什么回调延迟飙升、为什么 C++ 节点随机崩溃”时，本模块提供下沉至**网络报文、时间同步、中间件状态与内核线程级**的硬核排障工具链。

---

## 一、DDS 与底层网络诊断工具

### 1.1 Wireshark（RTPS 协议抓包分析）
* **核心过滤器**：`rtps`（查看全部 DDS 流量）、`rtps.sm.id == 0x15`（DATA）、`rtps.sm.id == 0x07`（HEARTBEAT）、`rtps.sm.id == 0x06`（ACKNACK）、`udp.port >= 7400 && udp.port <= 7500`。
* **典型排障目标**：
  * 确认 SPDP/SEDP 发现报文是否发出与到达（区分防火墙/交换机拦截 vs 应用层 QoS 拒连）。
  * 观察是否出现高频 `HEARTBEAT` / `ACKNACK` 重传风暴或 UDP 大包分片丢失（图像/点云传输卡顿元凶）。

### 1.2 中间件原厂工具与 Linux 网络基建
* **Fast DDS Monitor & `fastdds discovery`**：图形化监控 Participant/DataWriter/DataReader 吞吐、丢包与延迟；快速拉起 Discovery Server 规避弱网多播风暴。
* **Linux 网络核查命令**：
  * `ip route` / `ip maddr`：核查多播路由绑定到哪张网卡（多网卡工控机极易把 DDS 流量发到错误网口）。
  * `iperf3`：压测车端与上位机 Wi-Fi/千兆网口真实带宽与 UDP 抖动。
  * `sysctl net.core.rmem_max net.core.wmem_max`：检查并调大 Linux 内核 UDP 收发缓冲区，解决高频点云/图像内核丢包。

---

## 二、多机与传感器时间同步（高频隐形大坑）

在多工控机（感知机 + 规控机）或以太网激光雷达（如 Livox / Hesai / Ouster）联调中，只要主机间时钟偏差几十毫秒，就会引发大面积 **TF 外推报错** 与 **多传感器融合错位**：
* **`chrony`（NTP 毫秒级同步）**：`chronyc tracking`、`chronyc sources -v`，适合多机常规局域网同步（内网无外网时可配置一台主控机为本地 Stratum 时钟源）。
* **`linuxptp`（`ptp4l` + `phc2sys`，微秒/亚微秒级硬件时间戳同步）**：工业雷达、工业相机硬触发与高精多机协同标配。

---

## 三、性能剖析与 C++ 节点调试工具

| 排查目标 | 核心工具 | 典型用法大纲 |
| :--- | :--- | :--- |
| **ROS 2 端到端链路延迟** | **`ros2_tracing` (`tracetools`) + LTTng** | 极低开销追踪消息从 `publish` → RMW/DDS → `Executor` 回调触发的微秒级耗时，配合 `tracetools_analysis` 绘制延迟分布。 |
| **线程级 CPU 热点定位** | `htop`（开启 `H` 显示线程）、`top -H -p <pid>`、`perf record -g` + 火焰图 | 区分是业务回调算法慢、CDR 序列化重，还是 DDS 后台收发线程打满单核。 |
| **C++ 节点崩溃（Segfault / Core Dump）** | **GDB + Launch `prefix`** | 在 Launch 的 `Node(...)` 中配置 `prefix=['xterm -e gdb -ex run --args']` 或开启 `ulimit -c unlimited` 抓取 core 文件离线回溯调用栈。 |
| **内存泄漏与越界踩踏** | **AddressSanitizer (ASan) / Valgrind** | 编译时注入 `--cmake-args -DCMAKE_CXX_FLAGS="-fsanitize=address -g"` 快速捕获野指针与内存泄漏（比 Valgrind 快一个数量级）。 |

---

## 四、高频排障思考题（检验清单）

1. 机载工控机插了“接激光雷达的网口 A”和“接路由器 Wi-Fi 的网口 B”，为什么经常出现电脑连上 Wi-Fi 却看不到机载任何 ROS 2 话题？如何用 `ip route` 与 DDS XML 白名单解决？
2. 如何在不改动业务源码的前提下，通过 Launch 文件一键把 GDB 挂载到某个特定的 C++ 节点上捕获段错误？
3. 为什么传输 1080p 未压缩图像时，CPU 并不高但订阅端帧率掉了一半？在 Linux 内核层与 Wireshark 中分别该看什么指标？

---

## 五、后续 Step 3 专题深潜规划

- 📌 `6.1 Wireshark与DDS多机联调排障实战.md`：RTPS 常见报文抓包示例、UDP 内核缓冲调优参数与 Fast DDS/Cyclone DDS 网卡绑定模板。
- 📌 `6.2 多机时间同步与C++节点性能剖析指南.md`：`chrony`/`ptp4l` 离线内网配置、`ros2_tracing` 采样脚本以及 Launch 挂载 GDB/ASan 完整步骤。
