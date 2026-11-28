# tldr / tealdeer 命令速查工具手册

> [返回 CLI 工具总览](README.md)

---

## 1. 工具定位与核心特点

### 1.1 定位：先分清 tldr-pages 与 tealdeer
- **tldr-pages**（"Too Long; Didn't Read"）：社区维护的**极简命令行示例知识库**，将每个命令浓缩为“一句话说明 + 5~8 条最高频实用示例”。
- **tealdeer**：用 **Rust** 编写的高速 `tldr` 客户端（安装后可执行命令仍为 `tldr`），是目前官方最推荐的客户端实现之一。

### 1.2 与同类查手册工具的对比

| 工具 | 定位 | 优点 | 局限 | 推荐场景 |
| :--- | :--- | :--- | :--- | :--- |
| **`tldr` (`tealdeer`)** | 高频示例速查 | 毫秒级响应、5 秒定位可复制示例、离线可用 | 不覆盖冷门参数与底层细节 | **日常 90% 的忘记参数场景**（`tar`/`find`/`rsync`/`ffmpeg`） |
| **`man <cmd>`** | 官方权威全量手册 | 参数完整、版本与本机一致 | 动辄数千行，检索高频用法慢 | 查具体边界行为、冷门标志位、系统调用（`man 2/3`） |
| **`<cmd> --help`** | 程序内置帮助 | 绝对匹配当前二进制版本 | 只有参数列表，通常缺完整组合示例 | 确认本机版本是否支持某个开关 |
| **`cheat`** | 个人笔记型速查表 | 偏重个人维护的 cheatsheet | 社区页面覆盖面不如 tldr-pages | 强定制个人内部命令备忘 |

### 1.3 `tealdeer` 的核心特点
- **极致性能**：Rust 编译为单一原生二进制，无 Node.js / Python 运行时开销，查询耗时通常在毫秒级。
- **离线可用**：通过 `tldr --update` 将全部页面打包缓存在本地，断网/内网/容器环境照常秒查。
- **跨平台与多语言**：支持显式指定 `linux` / `osx` / `windows` 平台页面，并支持中文（`-L zh`）。
- **支持自定义页面与补丁**：可追加团队内部工具说明或给官方页面打补丁。

---

## 2. 安装与首次初始化

### 2.1 安装 `tealdeer`

```bash
# macOS (Homebrew，最推荐)
brew install tealdeer

# Ubuntu 22.04+ / Debian（注意部分旧版 Ubuntu 的 apt 包叫 tealdeer，二进制可能叫 tealdeer 或 tldr）
sudo apt update && sudo apt install -y tealdeer

# 通用方式：通过 Cargo（适合任意 Linux/macOS 获取最新版）
cargo install tealdeer
```

> [!TIP]
> 在部分 Ubuntu/Debian 发行版中，`apt install tealdeer` 安装后的二进制名可能是 `tldr`，也可能是与 Python 版 `tldr` 避免冲突的命名；可用 `which tldr tealdeer` 确认，必要时在 `.zshrc` 中加 `alias tldr='tealdeer'`。

### 2.2 首次必做：拉取本地缓存

刚安装完时本地缓存为空，必须先更新一次页面缓存：

```bash
tldr --update
```

---

## 3. 常用命令与参数速查

| 场景 / 目的 | 命令 | 说明 |
| :--- | :--- | :--- |
| 查询命令高频用法 | `tldr <cmd>` | 例如 `tldr tar`、`tldr find`、`tldr rsync` |
| 查询子命令用法 | `tldr <cmd> <subcmd>` | 例如 `tldr git rebase`、`tldr docker run`、`tldr systemctl` |
| 指定目标操作系统平台 | `tldr -p linux <cmd>` | 可选 `linux` / `osx` / `windows` / `common`（Mac 查 Linux 服务器命令必用） |
| 指定显示语言（如中文） | `tldr -L zh <cmd>` | 若对应页面有中文翻译则显示中文，否则自动回退英文 |
| 更新本地页面缓存 | `tldr --update` (`-u`) | 从社区拉取最新 tldr-pages 压缩包 |
| 列出本地所有可查命令 | `tldr --list` (`-l`) | 可配合 `grep` 搜索，如 `tldr -l \| grep git` |
| 查看配置与缓存目录路径 | `tldr --show-paths` | 排查配置不生效、找 `custom_pages_dir` 时必用 |
| 生成默认配置文件 | `tldr --seed-config` | 自动创建 `config.toml` 模板 |
| 清空本地缓存 | `tldr --clear-cache` | 缓存异常时清理后重新 `--update` |
| 输出原始 Markdown | `tldr --raw <cmd>` | 方便重定向或复制进文档 |
| 强制控制彩色输出 | `tldr --color always\|never <cmd>` | 配合管道（如 `less -R`）时有用 |

---

## 4. 常见使用流程

### 流程 A：日常 3 秒速查高频复杂命令

记不清参数组合时，直接用 `tldr` 替代搜索浏览器：

```bash
tldr tar             # 立刻看到 -czf 打包 / -xzf 解压 / -tf 预览
tldr find            # 按名、按时间、按大小查找并配合 -exec
tldr rsync           # 本地/远程增量同步、排除目录、断点续传
tldr ss              # 查看端口监听与连接（替代 netstat）
tldr git worktree    # 直接查 Git 子命令用法
tldr -p linux ps     # 在 macOS 上查 Linux 风格的 ps 参数
```

### 流程 B：配置自动更新缓存与语言偏好

1. 生成配置文件并查看其路径：
   ```bash
   tldr --seed-config
   tldr --show-paths
   ```
2. 编辑生成的 `config.toml`（不同版本与平台路径略有差异，Linux 与新版 macOS 默认多为 `~/.config/tealdeer/config.toml`，旧版 macOS 为 `~/Library/Application Support/tealdeer/config.toml`，以 `tldr --show-paths` 输出为准）：
   ```toml
   [display]
   compact = false        # 设为 true 可输出更紧凑排版
   use_pager = false      # 设为 true 在内容过长时自动调用 pager

   [updates]
   auto_update = true     # 缓存过期时，下次查询前自动同步检查更新
   auto_update_interval_hours = 720  # 每 30 天检查一次更新
   ```
3. 如希望默认优先显示中文，可在 `~/.zshrc` 中设置别名或语言环境（`tealdeer` 遵循 `-L` 参数与标准 `LANG`/`LANGUAGE` 环境变量）：
   ```zsh
   alias tldr='tldr -L zh'
   # 或按需配置 locale：export LANGUAGE="zh"
   ```

### 流程 C：添加团队私有命令页或给官方页打补丁

当团队有内部 CLI 工具（或想把自己的常用命令示例收进 `tldr`）时：

1. 在 `config.toml` 中确认或设置 `custom_pages_dir`（需填写**绝对路径**，不支持 `~`；默认路径可通过 `tldr --show-paths` 查看）：
   ```toml
   [directories]
   custom_pages_dir = "/path/to/your/tealdeer/pages"
   ```
2. **新增全新命令页**（以 `.page` 结尾，如 `mytool.page`）：
   ```markdown
   # mytool

   > 团队内部构建与部署工具。

   - 构建 Release 版本:

   `mytool build --release`

   - 部署到测试环境:

   `mytool deploy --env {{staging}}`
   ```
3. **给已有官方命令追加个人常用示例**（以 `.patch` 结尾，如 `tar.patch`）：
   ```markdown
   - 打包并排除 build 与 .git 目录:

   `tar --exclude='build' --exclude='.git' -czf {{archive.tar.gz}} {{dir}}`
   ```
4. 之后运行 `tldr mytool` 或 `tldr tar` 即可直接看到自定义内容，且不会在 `tldr --update` 时被覆盖。

### 流程 D：配置 Zsh 自动补全（与 Oh My Zsh 联动）

- **macOS (Homebrew)**：`brew install tealdeer` 通常已自动将补全脚本安装到 Homebrew 的 `site-functions`，确保 `~/.zshrc` 中启用了补全即可。
- **Linux 手动配置**：从 `tealdeer` GitHub Release 下载 `completions_zsh`，放置到 `$fpath` 目录（如 `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/completions/_tldr`），执行 `omz reload` 即可按 `Tab` 补全全部 tldr 命令名。

---

## 5. 高频排坑 FAQ

- **Q1：首次运行 `tldr tar` 报错 `Cache not found. Please run with --update.`？**
  - `tealdeer` 默认不随安装包内置离线库，执行一次 `tldr --update` 拉取缓存即可。
- **Q2：内网/代理环境下 `tldr --update` 拉取失败？**
  - 检查终端代理变量 `https_proxy` / `http_proxy`；若目标机器完全断网，可在有网机器执行 `tldr --update` 后，用 `tldr --show-paths` 找到 `Cache dir`，直接打包拷贝到离线机器的对应目录即可离线使用。
- **Q3：Ubuntu 上 `tldr` 响应很慢或不支持 `--seed-config`？**
  - 很可能装的是旧版 Node.js / Python 客户端而非 `tealdeer`。用 `tldr --version` 确认是否包含 `tealdeer` 字样；如不是，卸载旧 `tldr` 后改装 `tealdeer`。
