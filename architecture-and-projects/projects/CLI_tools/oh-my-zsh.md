# Oh My Zsh 知识与终端提效速查手册

> [返回 CLI 工具总览](README.md)

---

## 1. 工具定位与核心特点

### 1.1 定位：先分清 Zsh 与 Oh My Zsh
- **Zsh（Z Shell）**：命令解释器本体（与 Bash 同层），macOS 默认 Shell，具备更强的补全系统、通配符扩展与可定制性。
- **Oh My Zsh（OMZ）**：社区维护的 **Zsh 配置管理框架**，通过统一的插件（Plugins）与主题（Themes）机制，免去手写几百行 `.zshrc` 的成本。

| 对比维度 | Bash | 原生 Zsh | Zsh + Oh My Zsh |
| :--- | :--- | :--- | :--- |
| 开箱即用体验 | 基础够用 | 需自行配置补全与提示符 | **极佳**，默认配置好历史搜索、目录跳转与主题 |
| 插件生态 | 较弱 | 需手动引入脚本 | **内置 300+ 插件**，一行配置启用 |
| Git 状态感知 | 需手动配置 | 需手动配置 | 默认提示符显示分支/脏状态 + 上百个高频短别名 |
| 启动速度 | 最快 | 快 | 插件过多时可能变慢（建议按需精简） |

### 1.2 核心特点
- **生态丰富**：内置 `git`、`docker`、`z`、`extract` 等高频插件，并无缝接入第三方提效神器（自动建议、实时语法高亮）。
- **配置结构清晰**：框架本体（`~/.oh-my-zsh`）与用户扩展（`$ZSH_CUSTOM`）分离，框架升级不会覆盖你的自定义配置。
- **内置管理 CLI**：自带 `omz` 命令，更新框架、开关插件、切换主题、重载配置均可一条命令完成。

---

## 2. 安装与核心目录结构

### 2.1 安装 Zsh 与 Oh My Zsh

```bash
# Ubuntu / Debian / 容器内先安装 zsh 与基础依赖（macOS 已自带 zsh）
sudo apt update && sudo apt install -y zsh git curl

# 将 zsh 设为默认 Shell（重启终端后生效）
chsh -s "$(which zsh)"

# 安装 Oh My Zsh（官方脚本）
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 2.2 核心目录分工

| 路径 | 职责 | 维护建议 |
| :--- | :--- | :--- |
| `~/.zshrc` | Zsh 交互式主配置文件 | 只放主题名、插件列表、环境变量与少量核心配置 |
| `~/.oh-my-zsh/` | Oh My Zsh 框架源码目录 | **不要直接修改**，交给 `omz update` 管理 |
| `~/.oh-my-zsh/custom/` (`$ZSH_CUSTOM`) | 用户自定义目录 | 第三方插件放 `plugins/`，主题放 `themes/`，个人别名放 `*.zsh`（自动加载） |

---

## 3. 高频必装插件与主题推荐

### 3.1 推荐插件组合（精简高效，不拖慢启动）

| 插件名 | 来源 | 核心作用 |
| :--- | :--- | :--- |
| `git` | 内置 | 提供上百个高频 Git 短别名（`gst`/`gaa`/`gcmsg`/`gsw` 等） |
| `z` | 内置 | 记录高频访问目录，输入 `z cli` 直接模糊跳转到深层目录 |
| `extract` | 内置 | 统一用 `x <压缩包>` 解压 `.tar.gz`/`.zip`/`.7z`/`.rar` 等，不用记参数 |
| `sudo` | 内置 | 敲完命令发现忘了加 `sudo`，**连按两次 `Esc`** 自动在行首补上 `sudo` |
| `colored-man-pages` | 内置 | 给 `man` 手册加上彩色高亮 |
| `zsh-autosuggestions` | 第三方 | 根据历史命令在光标右侧显示灰色补全建议，按 **`→`（右方向键）** 即可采纳 |
| `zsh-syntax-highlighting` | 第三方 | 实时高亮命令行语法（正确命令绿色、错误命令红色、路径带下划线） |

### 3.2 一键安装第三方双神插件并在 `~/.zshrc` 启用

```bash
# 安装 zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 安装 zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

在 `~/.zshrc` 中修改 `plugins=(...)`（注意：**`zsh-syntax-highlighting` 必须放在列表最后**）：

```zsh
plugins=(
  git
  z
  extract
  sudo
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)
```

修改后执行 `omz reload`（或 `source ~/.zshrc`）生效。

### 3.3 主题推荐
- **`robbyrussell`**（默认）：极简轻量、无需特殊字体、响应最快，适合服务器与 Docker 容器。
- **`agnoster`**：经典箭头状态栏（需安装 Nerd Font 字体，否则箭头显示乱码）。
- **`powerlevel10k`**：颜值与性能兼顾的旗舰主题，支持 `p10k configure` 交互式向导与即时提示（Instant Prompt）。

---

## 4. 常用命令与快捷键速查

### 4.1 `omz` 框架管理命令

| 目的 | 命令 |
| :--- | :--- |
| 更新 Oh My Zsh | `omz update` |
| 重载当前 Zsh 配置 | `omz reload` |
| 查看所有可用/已启用插件 | `omz plugin list` |
| 查看某插件说明文档（README）与别名列表 | `omz plugin info <plugin>` |
| 快速启用 / 禁用插件 | `omz plugin enable <name>` / `omz plugin disable <name>` |
| 切换主题 | `omz theme set <theme>` |
| 查看 Oh My Zsh 版本与日志 | `omz version` / `omz changelog` |

### 4.2 `git` 插件高频短别名速查

启用内置 `git` 插件后，日常 90% 的 Git 操作可缩短为 2~4 个字母（随时可用 `alias | grep git` 查全集）：

| 短别名 | 对应原命令 | 用途 |
| :--- | :--- | :--- |
| `gst` | `git status` | 查看状态 |
| `ga` / `gaa` / `gapa` | `git add` / `git add --all` / `git add --patch` | 暂存改动 |
| `gcmsg "msg"` | `git commit -m "msg"` | 提交代码 |
| `gcam "msg"` | `git commit -a -m "msg"` | 暂存已追踪文件并提交 |
| `gc!` | `git commit --verbose --amend` | 修改上次提交 |
| `gd` / `gds` | `git diff` / `git diff --staged` | 查看工作区/暂存区差异 |
| `gsw` / `gswc` | `git switch` / `git switch -c` | 切换 / 新建并切换分支 |
| `gb` / `gba` | `git branch` / `git branch -a` | 查看本地/全部分支 |
| `gl` / `gp` | `git pull` / `git push` | 拉取 / 推送 |
| `gpf` | `git push --force-with-lease` | 安全强推 |
| `glog` / `glol` | `git log --oneline --decorate --graph` / 含相对时间与作者的图形日志 | 图形化单行日志 |
| `grb` / `grbi` | `git rebase` / `git rebase -i` | 变基 / 交互式变基 |
| `gsta` / `gstp` | `git stash push` / `git stash pop` | 暂存 / 弹出暂存 |

### 4.3 Zsh 高频终端快捷键与内置技巧

| 快捷键 / 命令 | 效果 |
| :--- | :--- |
| `→`（右方向键） | 采纳 `zsh-autosuggestions` 的整条灰色建议 |
| `Ctrl + R` | 反向模糊搜索历史命令 |
| `↑` / `↓` | 已有前缀时，按前缀过滤历史命令（输入 `git ` 再按 `↑` 只看 `git` 历史） |
| `Ctrl + A` / `Ctrl + E` | 光标跳至行首 / 行尾 |
| `Ctrl + W` / `Ctrl + U` | 删除光标前一个词 / 删除光标前整行 |
| `Ctrl + L` | 清屏（等价于 `clear`） |
| `Esc` `Esc` | 行首补全 `sudo`（需启用 `sudo` 插件） |
| `take <dir>` | 创建目录并立即 `cd` 进去（`mkdir -p && cd`） |
| `..` / `...` / `-` | 返回上一级 / 上两级 / 上一个所在目录 |
| 先输入 `d`，再直接输入 `1`..`9` | 查看最近访问目录栈，直接敲序号一键跳转 |
| `!!` / `!$` | 引用上一条完整命令 / 上一条命令的最后一个参数 |

---

## 5. 常见使用流程

### 流程 A：新机器 / 新容器 5 分钟初始化标准 Zsh 环境

```bash
# 1. 非交互安装 Oh My Zsh（安装脚本执行后不自动切换 Shell，适合脚本与 Dockerfile）
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 2. 拉取两个核心第三方插件
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# 3A. 非交互 / Dockerfile 场景：直接写入 ~/.zshrc（此时不在 Zsh 内，无法调用 omz 函数）
sed -i 's/^plugins=(git)/plugins=(git z extract sudo colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# 3B. 交互式终端场景：先进入 Zsh，再用 omz 启用插件（默认已含 git，且 enable 会自动重载）
# exec zsh
# omz plugin enable z extract sudo colored-man-pages zsh-autosuggestions zsh-syntax-highlighting
```

### 流程 B：优雅管理个人别名与环境脚本（不污染 `.zshrc`）

Oh My Zsh 会自动加载 `$ZSH_CUSTOM/*.zsh` 下的所有脚本，推荐按主题拆分：

```bash
# 新建个人别名文件
cat <<'EOF' > "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/my_aliases.zsh"
alias ll='ls -alh'
alias gs='git status -sb'
alias cls='clear'
EOF

omz reload
```

### 流程 C：排查 Zsh 启动变慢

1. 先测当前冷启动耗时：
   ```bash
   time zsh -i -c exit
   ```
2. 若超过 `0.5s`，在 `~/.zshrc` **最顶部**临时加 `zmodload zsh/zprof`，**最底部**加 `zprof`，新开终端即可看到各模块耗时排行榜。
3. 常见元凶：未延迟加载的 `nvm` / `conda` 初始化脚本、启用了过多用不到的插件（如 `kubectl`/`aws` 动态补全）。移除无用插件或对 `nvm` 做懒加载即可恢复毫秒级启动。

---

## 6. 高频排坑 FAQ

- **Q1：提示符出现方框 `□` 或乱码图标？**
  - 使用了需要图标字体的主题（如 `agnoster`、`powerlevel10k`）。在终端软件（iTerm2 / VSCode 集成终端）中将字体设置为任意 **Nerd Font**（如 `MesloLGS NF`、`JetBrainsMono Nerd Font`），或切回默认 `robbyrussell` 主题。
- **Q2：新开终端报 `zsh compinit: insecure directories` 警告？**
  - 目录权限过宽（多见于 macOS Homebrew 或多人共用目录）。执行 `compaudit | xargs chmod g-w,o-w` 修复权限后重启终端。
- **Q3：`zsh-syntax-highlighting` 不生效或报错？**
  - 确认它在 `~/.zshrc` 的 `plugins=(...)` 中位于**最后一个位置**，且目录名与插件名完全一致。
- **Q4：Docker 容器里执行 `chsh -s $(which zsh)` 需要密码或未生效？**
  - 在 `Dockerfile` 中以 `root` 身份执行 `RUN usermod -s /bin/zsh <user>`（或创建用户时 `useradd -s /bin/zsh`）修改用户默认登录 Shell（注意 `SHELL ["/bin/zsh", "-c"]` 仅作用于构建期 `RUN`）；若配合 VSCode DevContainer，可在 `.devcontainer/devcontainer.json` 的 `customizations.vscode.settings` 下设置 `"terminal.integrated.defaultProfile.linux": "zsh"`。
