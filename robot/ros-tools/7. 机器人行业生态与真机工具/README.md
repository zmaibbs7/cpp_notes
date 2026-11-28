# 7. 机器人行业生态与真机工具

> [返回 ROS Tools 总纲](../README.md)
>
> **本模块核心定位**：跳出纯 ROS 2 官方命令行范畴，补齐机器人行业工程师在**仿真验证、真机硬件总线调试、现场运维以及标定/精度评测**中每天都在使用的生态核心工具。

---

## 一、主流机器人仿真器选型大纲

| 仿真器 | 核心定位与优势 | 与 ROS 2 集成方式 | 典型行业场景 |
| :--- | :--- | :--- | :--- |
| **Gazebo（Harmonic / Garden，`gz sim`）** | ROS 2 官方生态首选，开源轻量、插件与传感器模型丰富（替代已停维的 Gazebo Classic） | `ros_gz_bridge` + `gz_ros2_control` | 移动底盘导航（Nav2）、机械臂规划（MoveIt 2）、教学与常规算法 CI 回归。 |
| **NVIDIA Isaac Sim** | 基于 Omniverse RTX 光追渲染 + GPU 大规模并行物理（Isaac Lab），感知合成数据逼真 | 内置原生 ROS 2 Bridge 扩展 | 具身智能、视觉 VLA/强化学习大规模并行训练、高拟真相机/雷达感知仿真。 |
| **MuJoCo** | 接触动力学精度极高、计算极快、XML（MJCF）简洁 | C++/Python API 或轻量 ROS 2 桥接节点 | 足式/人形机器人运动控制、灵巧手精细操作、强化学习策略训练（Sim2Real）。 |

---

## 二、真机硬件总线与现场调试工具

### 2.1 CAN / CAN-FD 总线（`can-utils`）
机器人底盘、伺服电机、机械臂关节、BMS 电池管理系统几乎全部走 CAN / CAN-FD：
* 接口拉起：`sudo ip link set can0 up type can bitrate 500000`（CAN-FD 附带 `dbitrate 2000000 fd on`）。
* 抓包与发帧：`candump can0`（实时监听报文）、`cansend can0 123#DEADBEEF`（手发控制/查询帧）、`cansniffer`（高亮变化字节，逆向协议神器）、`ip -details -statistics link show can0`（查 Bus-Off 与错误帧计数）。

### 2.2 串口 / EtherCAT 与外设持久化（`udev`）
* **串口调试**：`picocom` / `minicom`（终端轻量）、`cutecom`（GUI 十六进制收发），配合 `lsusb` / `dmesg | grep tty` 定位新插设备。
* **`udev` 规则固定设备别名**：解决多路 USB 串口/雷达/IMU 每次重启 `/dev/ttyUSB0` 与 `/dev/ttyUSB1` 编号随机漂移的大坑（通过 `udevadm info -a -n /dev/ttyUSB0` 提取 `idVendor`/`idProduct`/`serial`，映射为固定 `/dev/imu_front`、`/dev/chassis_can`）。
* **EtherCAT（工业机械臂/人形关节高频总线）**：`ethercat slaves`（查看从站状态 `INIT/PREOP/SAFEOP/OP`）、`ethercat pdos`、`ethercat master`。

### 2.3 现场运维与遥控交互
* **`tmux`（真机 SSH 必备保活神器）**：在车端工控机分屏启动多个 Launch、查看日志与资源监控；即使 Wi-Fi 断连重连，车端进程完全不退出。
* **手动遥控验证**：`ros2 run teleop_twist_keyboard teleop_twist_keyboard`（键盘发 `/cmd_vel`）、`joy_node` + `teleop_twist_joy`（无线手柄实车安全接管）。

---

## 三、传感器标定与算法精度评估套件

| 领域 | 行业常用工具 | 核心能力 |
| :--- | :--- | :--- |
| **单目/双目相机内参标定** | `camera_calibration`（ROS 2 官方） | 基于棋盘格/Charuco 板实时标定畸变系数与内参矩阵并输出标准 YAML。 |
| **相机—IMU 联合外参标定** | **Kalibr**（ETH Zurich） | 行业事实标准，标定多相机内/外参、相机-IMU 空间外参与时间偏移（Time Offset）。 |
| **激光雷达—相机外参标定** | `direct_visual_lidar_calibration` / `velo2cam_calibration` | 无标定板或标定板方式求解雷达点云到图像像素的精准投影外参。 |
| **SLAM / 定位轨迹精度评估** | **`evo`**（`evo_ape` / `evo_rpe` / `evo_traj`） | 直接读取 ROS bag（含 ROS 2 / MCAP）、TUM、KITTI 轨迹，一键计算绝对位姿误差（APE）与相对位姿误差（RPE）并生成对比图与统计报告。 |

---

## 四、高频排障思考题（检验清单）

1. 真机重启后原本正常的 IMU 和底盘驱动突然报错“协议校验失败”，最常见的原因是什么？如何用 `udev` 规则一劳永逸解决？
2. 当电机驱动器在高速启停时 CAN 总线进入 `BUS-OFF` 状态，如何在 `ip link set` 中配置 `restart-ms` 自动恢复，并用 `candump` / 统计信息排查终端电阻或波特率问题？
3. 用 `evo_ape` 评估自家 SLAM 轨迹与动捕/RTK 真值误差时，为什么通常需要加上 `-a`（Umeyama 轨迹对齐）与 `--t_max_diff` 时间戳容差参数？

---

## 五、后续 Step 3 专题深潜规划

- 📌 `7.1 真机硬件调试速查(CAN_串口_udev_tmux).md`：`can-utils` 常用命令模板、`udev` 规则编写完整示例与车端 `tmux` 常用快捷键速查。
- 📌 `7.2 标定与evo轨迹评测实战指南.md`：`camera_calibration` / Kalibr 采集注意事项与 `evo_ape` / `evo_rpe` 常用出图命令合集。
