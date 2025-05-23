# 🚀 Cursor 免费试用重置工具

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

> ⚠️ **重要提示**
> 
> 本工具当前支持版本：
> - ✅ Windows: 最新的 0.49.x 版本（已支持）
> - ✅ Mac/Linux: 最新的 0.49.x 版本（已支持，欢迎测试并反馈问题）
 
> 使用前请确认您的 Cursor 版本。

<details open>
<summary><b>📦 版本历史与下载</b></summary>

<div class="version-card" style="background: linear-gradient(135deg, #6e8efb, #a777e3); border-radius: 8px; padding: 15px; margin: 10px 0; color: white;">


[查看完整版本历史]([CursorHistoryDown.md](https://github.com/oslook/cursor-ai-downloads?tab=readme-ov-file))

</div>


</details>

⚠️ **Cursor通用解决方案**
> 1.  关闭Cursor、退出账号、官网Setting删除账号(刷新节点IP：日本、新加坡、 美国、香港，低延迟为主不一定需要但是有条件就换，Windows用户建议刷新DNS缓存：`ipconfig /flushdns`)
> 前往Cursor官网删除当前账号
> 步骤：用户头像->Setting-左下角Advanced▼->Delete Account
>
> 2.  刷新机器码脚本，看下面脚本地址，国内可用
> 
> 3.  重新注册账号、登录、打开Cursor，即可恢复正常使用。
>
> 4.  备用方案：如果步骤 [**3**] 后仍不可用，或者遇到注册账号失败、无法删除账号等问题，这通常意味着您的浏览器被目标网站识别或限制（风控）。此时，请尝试更换浏览器，例如：Edge、Google Chrome、Firefox。（或者，可以尝试使用能够修改或随机化浏览器指纹信息的浏览器）。


关注大佬公众号：煎饼果子卷AI


---

> ⚠️ **MAC地址修改警告**
> 
> Mac用户请注意: 本脚本包含MAC地址修改功能，将会:
> - 修改您的网络接口MAC地址
> - 在修改前备份原始MAC地址
> - 此修改可能会暂时影响网络连接
> - 执行过程中可以选择跳过此步骤

---

### 📝 问题描述

> 当您遇到以下任何消息时：

#### 问题 1: 试用账号限制 <p align="right"><a href="#solution1"><img src="https://img.shields.io/badge/跳转到解决方案-Blue?style=plastic" alt="跳转到顶部"></a></p>

```text
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

#### 问题 2: API密钥限制 <p align="right"><a href="#solution2"><img src="https://img.shields.io/badge/跳转到解决方案-green?style=plastic" alt="跳转到顶部"></a></p>

```text
[New Issue]

Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
Request ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 问题 3: 试用请求限制

> 这表明您在VIP免费试用期间已达到使用限制：

```text
You've reached your trial request limit.
```

#### 问题 4: Claude 3.7 高负载 （High Load）  <p align="right"><a href="#solution4"><img src="https://img.shields.io/badge/跳转到解决方案-purple?style=plastic" alt="跳转到顶部"></a></p>

```text
High Load 
We're experiencing high demand for Claude 3.7 Sonnet right now. Please upgrade to Pro, or switch to the
'default' model, Claude 3.5 sonnet, another model, or try again in a few moments.
```

<br>

<p id="solution2"></p>

#### 解决方案：完全卸载Cursor并重新安装（API密钥问题）

1. 下载 [Geek.exe 卸载工具[免费]](https://geekuninstaller.com/download)
2. 完全卸载Cursor应用
3. 重新安装Cursor应用
4. 继续执行解决方案1

<br>

<p id="solution1"></p>

> 临时解决方案：

#### 解决方案 1: 快速重置（推荐）

1. 关闭Cursor应用
2. 运行机器码重置脚本（见下方安装说明）
3. 重新打开Cursor继续使用

#### 解决方案 2: 切换账号

1. 文件 -> Cursor设置 -> 退出登录
2. 关闭Cursor
3. 运行机器码重置脚本
4. 使用新账号登录

#### 解决方案 3: 网络优化

如果上述解决方案不起作用，请尝试：

- 切换到低延迟节点（推荐区域：日本、新加坡、美国、香港）
- 确保网络稳定性
- 清除浏览器缓存并重试

<p id="solution4"></p>

#### 解决方案 4: Claude 3.7 访问问题（High Load ）

如果您看到Claude 3.7 Sonnet的"High Load"（高负载）消息，这表明Cursor在一天中某些时段限制免费试用账号使用3.7模型。请尝试：

1. 使用Gmail邮箱创建新账号，可能需要通过不同IP地址连接
2. 尝试在非高峰时段访问（通常在早上5-10点或下午3-7点之间限制较少）
3. 考虑升级到Pro版本获取保证访问权限
4. 使用Claude 3.5 Sonnet作为备选方案

> 注意：随着Cursor调整资源分配策略，这些访问模式可能会发生变化。

### 🚀 系统支持

<table>
<tr>
<td>

**Windows** ✅

- x64 & x86

</td>
<td>

**macOS** ✅

- Intel & M-series

</td>
<td>

**Linux** ✅

- x64 & ARM64

</td>
</tr>
</table>

### 🚀 一键解决方案

<details open>
<summary><b>国内用户（推荐）</b></summary>

**macOS**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

**Linux**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

> **Linux 用户请注意：** 该脚本通过检查常用路径（`/usr/bin`, `/usr/local/bin`, `$HOME/.local/bin`, `/opt/cursor`, `/snap/bin`）、使用 `which cursor` 命令以及在 `/usr`、`/opt` 和 `$HOME/.local` 目录内搜索，来尝试定位您的 Cursor 安装。如果 Cursor 安装在其他位置或通过这些方法无法找到，脚本可能会失败。请确保可以通过这些标准位置或方法之一访问到 Cursor。

**Windows**

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
<div align="center">
<img src="img/run_success.png" alt="运行成功" width="600"/>
</div>

</details>
<details open>
<summary><b>Windows 管理员终端运行和手动安装</b></summary>

#### Windows 系统打开管理员终端的方法：

##### 方法一：使用 Win + X 快捷键
```md
1. 按下 Win + X 组合键
2. 在弹出的菜单中选择以下任一选项:
   - "Windows PowerShell (管理员)"
   - "Windows Terminal (管理员)" 
   - "终端(管理员)"
   (具体选项因Windows版本而异)
```

##### 方法二：使用 Win + R 运行命令
```md
1. 按下 Win + R 组合键
2. 在运行框中输入 powershell 或 pwsh
3. 按 Ctrl + Shift + Enter 以管理员身份运行
   或在打开的窗口中输入: Start-Process pwsh -Verb RunAs
4. 在管理员终端中输入以下重置脚本:

irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

##### 方法三：通过搜索启动
>![搜索 PowerShell](img/pwsh_1.png)
>
>在搜索框中输入 pwsh，右键选择"以管理员身份运行"
>![管理员运行](img/pwsh_2.png)

在管理员终端中输入重置脚本:
```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

### 🔧 PowerShell 安装指南

如果您的系统没有安装 PowerShell,可以通过以下方法安装:

#### 方法一：使用 Winget 安装（推荐）

1. 打开命令提示符或 PowerShell
2. 运行以下命令:
```powershell
winget install --id Microsoft.PowerShell --source winget
```

#### 方法二：手动下载安装

1. 下载对应系统的安装包:
   - [PowerShell-7.4.6-win-x64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi) (64位系统)
   - [PowerShell-7.4.6-win-x86.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi) (32位系统)
   - [PowerShell-7.4.6-win-arm64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi) (ARM64系统)

2. 双击下载的安装包,按提示完成安装

> 💡 如果仍然遇到问题,可以参考 [Microsoft 官方安装指南](https://learn.microsoft.com/zh-cn/powershell/scripting/install/installing-powershell-on-windows)

</details>

#### Windows 安装特性:

- 🔍 自动检测并使用 PowerShell 7（如果可用）
- 🛡️ 通过 UAC 提示请求管理员权限
- 📝 如果没有 PS7 则使用 Windows PowerShell
- 💡 如果提权失败会提供手动说明

完成后，脚本将：

1. ✨ 自动安装工具
2. 🔄 立即重置 Cursor 试用期

### 📦 手动安装

> 从 [releases](https://github.com/yuaotian/go-cursor-help/releases/latest) 下载适合您系统的文件

<details>
<summary>Windows 安装包</summary>

- 64 位: `cursor-id-modifier_windows_x64.exe`
- 32 位: `cursor-id-modifier_windows_x86.exe`
</details>

<details>
<summary>macOS 安装包</summary>

- Intel: `cursor-id-modifier_darwin_x64_intel`
- M1/M2: `cursor-id-modifier_darwin_arm64_apple_silicon`
</details>

<details>
<summary>Linux 安装包</summary>

- 64 位: `cursor-id-modifier_linux_x64`
- 32 位: `cursor-id-modifier_linux_x86`
- ARM64: `cursor-id-modifier_linux_arm64`
</details>

### 🔧 技术细节

<details>
<summary><b>注册表修改说明</b></summary>

> ⚠️ **重要提示：本工具会修改系统注册表**

#### 修改内容
- 路径：`计算机\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- 项目：`MachineGuid`

#### 潜在影响
修改此注册表项可能会影响：
- Windows 系统对设备的唯一标识
- 某些软件的设备识别和授权状态
- 基于硬件标识的系统功能

#### 安全措施
1. 自动备份
   - 每次修改前会自动备份原始值
   - 备份保存在：`%APPDATA%\Cursor\User\globalStorage\backups`
   - 备份文件格式：`MachineGuid.backup_YYYYMMDD_HHMMSS`

2. 手动恢复方法
   - 打开注册表编辑器（regedit）
   - 定位到：`计算机\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
   - 右键点击 `MachineGuid`
   - 选择"修改"
   - 粘贴备份文件中的值

#### 注意事项
- 建议在修改前先确认备份文件的存在
- 如遇问题可通过备份文件恢复原始值
- 必须以管理员权限运行才能修改注册表
</details>

<details>
<summary><b>配置文件</b></summary>

程序修改 Cursor 的`storage.json`配置文件，位于：

- Windows: `%APPDATA%\Cursor\User\globalStorage\`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/`
- Linux: `~/.config/Cursor/User/globalStorage/`
</details>

<details>
<summary><b>修改字段</b></summary>

工具会生成新的唯一标识符：

- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`
</details>

<details>
<summary><b>手动禁用自动更新</b></summary>

Windows 用户可以手动禁用自动更新功能：

1. 关闭所有 Cursor 进程
2. 删除目录：`C:\Users\用户名\AppData\Local\cursor-updater`
3. 创建同名文件：`cursor-updater`（不带扩展名）

Linux用户可以尝试在系统中找到类似的`cursor-updater`目录进行相同操作。

MacOS用户按照以下步骤操作：

```bash
# 注意：经测试，此方法仅适用于0.45.11及以下版本，不支持0.46.*版本
# 关闭所有 Cursor 进程
pkill -f "Cursor"

# 备份app-update.yml并创建空的只读文件代替原文件
cd /Applications/Cursor.app/Contents/Resources
mv app-update.yml app-update.yml.bak
touch app-update.yml
chmod 444 app-update.yml

# 打开Cursor设置，将更新模式设置为"无"，该步骤必须执行，否则Cursor依然会自动检查更新
# 步骤：Settings -> Application -> Update, 将Mode设置为none

# 注意: cursor-updater修改方法可能已失效。但为了以防万一，还是删除更新目录并创建阻止文件
rm -rf ~/Library/Application\ Support/Caches/cursor-updater
touch ~/Library/Application\ Support/Caches/cursor-updater
```
</details>

<details>
<summary><b>安全特性</b></summary>

- ✅ 安全的进程终止
- ✅ 原子文件操作
- ✅ 错误处理和恢复
</details>

<details>
<summary><b>重置 Cursor 免费试用</b></summary>

### 使用 `cursor_free_trial_reset.sh` 脚本

#### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_free_trial_reset.sh -o ./cursor_free_trial_reset.sh && sudo bash ./cursor_free_trial_reset.sh && rm ./cursor_free_trial_reset.sh
```

#### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_free_trial_reset.sh | sudo bash
```

#### Windows

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_free_trial_reset.sh | iex
```

</details>

## 联系方式

<div align="center">
<table>
<tr>
<td align="center">
<b>个人微信</b><br>
<img src="img/wx_me.png" width="250" alt="作者微信"><br>
<b>微信：JavaRookie666</b>
</td>
<td align="center">
<b>微信交流群</b><br>
<img src="img/qun13.png" width="500" alt="WeChat"><br>
<small>二维码7天内(5月30日前)有效，过期请加微信</small>
</td>
<td align="center">
<b>公众号</b><br>
<img src="img/wx_public_2.png" width="250" alt="微信公众号"><br>
<small>获取更多AI开发资源</small>
</td>
<td align="center">
<b>微信赞赏</b><br>
<img src="img/wx_zsm2.png" width="500" alt="微信赞赏码"><br>
<small>要到饭咧？啊咧？啊咧？不给也没事~ 请随意打赏</small>
</td>
<td align="center">
<b>支付宝赞赏</b><br>
<img src="img/alipay.png" width="500" alt="支付宝赞赏码"><br>
<small>如果觉得有帮助,来包辣条犒劳一下吧~</small>
</td>
</tr>
</table>
</div>

---

### 📚 推荐阅读

- [Cursor 异常问题收集和解决方案](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI 通用开发助手提示词指南](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## ⭐ 项目统计

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

## 📄 许可证

<details>
<summary><b>MIT 许可证</b></summary>

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

</details>
