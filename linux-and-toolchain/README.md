# Linux 系统与工具链

### 1. C++ 编译、构建与工具链
- **编译与链接原理**
  - 预处理、编译、汇编与 ELF 目标文件结构
  - 静态链接、动态链接、符号解析与重定位
  - 编译器（GCC / Clang）常用选项与优化级别
- **构建系统与包管理** 
  - Make、CMake 与 Ninja 的核心工作流
  - 系统包管理（apt、pkg-config）与 C++ 包管理（conan、vcpkg、Bazel、CPM.cmake、Pixi、XMake、Buck2、Meson）
  - 静态/动态库组织、符号可见性与 ABI 兼容性
- **交叉编译与工具链**
  - 工具链组成（Host/Target、sysroot、binutils、glibc/musl）
  - 交叉工具链构建与配置（crosstool-NG、CMake Toolchain File）
  - 跨架构仿真与验证（QEMU）

### 2. Linux 核心机制与性能优化
- **CPU 微架构与缓存优化**
  - 流水线、分支预测与无分支编程实践
  - L1/L2/L3 Cache、缓存行（Cache Line）与伪共享消除
  - 缓存一致性（MESI）与内存屏障
- **进程、线程与调度优化**
  - 进程/线程模型、IPC 与同步原语（futex、mutex、spinlock）
  - 调度策略（CFS、实时调度 SCHED_FIFO / SCHED_RR）
  - 绑核（CPU Affinity）、中断亲和性与隔离核心（isolcpus）
- **内存、文件系统与 I/O 优化**
  - 虚拟内存、页表、TLB、大页（HugePages）与 NUMA 局部性
  - 缺页异常、内存映射（mmap）与分配器选型（ptmalloc、jemalloc、tcmalloc）
  - VFS、页缓存（Page Cache）、DMA、Direct I/O 与零拷贝技术
- **网络编程与低延迟优化**
  - Socket 编程、TCP/UDP 协议栈与内核收发包路径
  - I/O 多路复用（select、poll、epoll）与事件驱动模型
  - 内核网络参数调优（sysctl）与内核旁路基础
- **调试、诊断与性能剖析**
  - 调试与缺陷检测（GDB、Core Dump、ASan/TSan/UBSan）
  - 二进制分析工具（readelf、objdump、nm、ldd）
  - 性能剖析与追踪（perf、火焰图、strace、eBPF、Google Benchmark）

### 3. Linux 系统架构、启动与定制裁剪
- **Linux 完整启动与生命周期**
  - 上电引导流程（BIOS/UEFI、Bootloader / U-Boot）
  - 内核启动、设备树（Device Tree / DTS 载板硬件适配）与 initramfs
  - 根文件系统（rootfs）挂载、PID 1（systemd / init）与服务管理
- **内核、BSP 与根文件系统裁剪**
  - 内核配置（Kconfig / menuconfig）、模块裁剪与实时内核补丁（PREEMPT_RT）
  - SoC 厂商 BSP 与闭源驱动集成（NPU/GPU/ISP 固件、`.ko` 内核模块与用户态库）
  - 常见驱动模型与用户态/内核态交互（sysfs、procfs、ioctl、udev 权限规则）
  - 最小根文件系统组成（BusyBox、动态库精简、基础配置）
- **自定义 Linux 构建与部署**
  - 主流 SoC 镜像构建方案（Yocto、Buildroot、Debian/Ubuntu Base `debootstrap`/`chroot` 定制）
  - 声明式不可变系统构建与原子回滚（Nix / NixOS 基础）
  - 镜像打包、刷写与安全 OTA 升级（A/B 分区、U-Boot 引导切换与失败回滚）
  - 容器化与环境隔离（Docker、DevContainer）