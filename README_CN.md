# 🚀 Cursor 免费试用重置工具

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

## 🎯 工具功能

**Cursor 免费试用重置工具** 通过修改设备标识符来重置您的 Cursor AI 编辑器试用期。当您看到那些烦人的试用限制消息时，这个工具能给您一个全新的开始！

### 🚨 常见问题解决

<details>
<summary>🔴 <strong>"Too many free trial accounts used on this machine"</strong></summary>

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

**✅ 解决方案：** 使用我们的工具重置您机器的设备标识符！

</details>

<details>
<summary>🟡 <strong>"Composer relies on custom models..."</strong></summary>

```
Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
```

**✅ 解决方案：** 
1. 使用 [Geek 卸载工具](https://geekuninstaller.com/download) 完全卸载 Cursor
2. 重新安装 Cursor
3. 运行我们的重置工具

</details>

<details>
<summary>🟣 <strong>Claude 3.7 "High Load" 高负载</strong></summary>

```
We're experiencing high demand for Claude 3.7 Sonnet right now. 
Please upgrade to Pro, or switch to the 'default' model...
```

**✅ 解决方案：** 重置试用期并在非高峰时段尝试（早上5-10点或下午3-7点）

</details>

---

## 🖥️ 平台支持

<table align="center">
<tr>
<td align="center">

### 🐧 **Linux**
✅ 所有发行版<br>
✅ x64, x86, ARM64<br>
✅ 自动检测安装

</td>
<td align="center">

### 🍎 **macOS**
✅ Intel & Apple Silicon<br>
✅ 权限自动修复<br>
✅ Python3 集成

</td>
<td align="center">

### 🪟 **Windows**
✅ x64, x86, ARM64<br>
✅ 注册表修改<br>
✅ PowerShell 7 就绪

</td>
</tr>
</table>

---

## ⚡ 快速开始（一键解决方案）

### 🇨🇳 国内用户（推荐，加速访问）

<details open>
<summary><strong>🐧 Linux</strong></summary>

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

</details>

<details open>
<summary><strong>🍎 macOS</strong></summary>

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

</details>

<details open>
<summary><strong>🪟 Windows</strong></summary>

**在 PowerShell 管理员模式下运行：**

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

### 🌍 海外用户

<details>
<summary><strong>🐧 Linux</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash 
```

</details>

<details>
<summary><strong>🍎 macOS</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

</details>

<details>
<summary><strong>🪟 Windows</strong></summary>

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

---

## 🛠️ Windows 管理员权限运行方法

### 🪟 Windows 操作方法

<details>
<summary><strong>方法一：Win + X 快捷键</strong></summary>

1. 按下 `Win + X` 组合键
2. 选择 "Windows PowerShell (管理员)" 或 "终端(管理员)"
3. 粘贴上面的命令

</details>

<details>
<summary><strong>方法二：搜索方法</strong></summary>

1. 在开始菜单搜索 "PowerShell"
2. 右键点击 → "以管理员身份运行"
3. 粘贴命令

![搜索 PowerShell](img/pwsh_1.png)
![管理员运行](img/pwsh_2.png)

</details>

<details>
<summary><strong>方法三：Win + R</strong></summary>

1. 按下 `Win + R`
2. 输入 `powershell`
3. 按 `Ctrl + Shift + Enter`

</details>

### 🔧 PowerShell 安装（如需要）

**选项1：使用 Winget**
```powershell
winget install --id Microsoft.PowerShell --source winget
```

**选项2：手动下载**
- [PowerShell 7.4.6 x64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi)
- [PowerShell 7.4.6 x86](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi)
- [PowerShell 7.4.6 ARM64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi)

---

## 🔧 高级功能

### 🔒 自动更新禁用

脚本可以自动禁用 Cursor 的自动更新功能以防止版本冲突：

**Windows：** 在 `%LOCALAPPDATA%\cursor-updater` 创建阻止文件
**macOS：** 修改 `app-update.yml` 并创建阻止文件
**Linux：** 在 `~/.config/cursor-updater` 创建阻止文件

### 🛡️ 安全特性

- ✅ **自动备份** - 修改前自动备份所有原始文件
- ✅ **进程管理** - 安全停止和重启 Cursor 进程
- ✅ **权限处理** - 自动修复文件权限（macOS）
- ✅ **错误恢复** - 出错时自动恢复备份
- ✅ **多方法兼容** - 使用多种技术确保最大兼容性

### 🔍 修改内容

<details>
<summary><strong>配置文件</strong></summary>

**位置：**
- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`

**修改字段：**
- `telemetry.machineId`
- `telemetry.macMachineId` 
- `telemetry.devDeviceId`
- `telemetry.sqmId`

</details>

<details>
<summary><strong>JavaScript 文件（高级）</strong></summary>

工具会向 Cursor 的 JavaScript 文件注入代码以覆盖设备 ID 函数：
- `extensionHostProcess.js`
- `main.js`
- `cliProcessMain.js`

</details>

<details>
<summary><strong>Windows 注册表（仅 Windows）</strong></summary>

**修改注册表：**
- 路径: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- 键: `MachineGuid`

**⚠️ 重要：** 原始值会自动备份到 `%APPDATA%\Cursor\User\globalStorage\backups`

</details>

---

## 🎉 成功截图

<div align="center">
<img src="img/run_success.png" alt="成功截图" width="600"/>
</div>

---

## 🆘 故障排除

### ❓ 常见问题

**Q: 脚本提示 "Permission denied"**
A: 确保使用 `sudo`（Linux/macOS）或管理员权限（Windows）运行

**Q: Cursor 仍显示试用限制**
A: 尝试完整重置选项并完全重启 Cursor

**Q: 脚本找不到 Cursor 安装**
A: 确保 Cursor 安装在标准位置或从 [cursor.sh](https://cursor.sh/) 安装

**Q: macOS 上的 Python3 错误**
A: 使用 `brew install python3` 安装 Python3

### 🔄 通用解决步骤

1. **完全关闭 Cursor**
2. **删除账户** 从 Cursor 网站（设置 → 高级 → 删除账户）
3. **运行我们的重置工具**
4. **注册新账户**
5. **重启 Cursor**

---

## 💡 专业提示

- 🌐 **网络优化：** 使用低延迟节点（日本、新加坡、美国、香港）
- 🕐 **时机选择：** 在非高峰时段尝试访问 Claude 3.7
- 🔄 **浏览器切换：** 如果账户问题持续，尝试不同浏览器
- 📱 **IP 刷新：** 如可能考虑刷新您的 IP
- 🧹 **DNS 缓存：** Windows 用户可运行 `ipconfig /flushdns`

---

## 📚 相关资源

- [Cursor 异常问题收集和解决方案](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI 通用开发助手提示词指南](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## 💬 反馈与支持

觉得有帮助？我们很乐意听到您的反馈！

- 🐛 **错误报告：** 在 GitHub 上开启 issue
- 💡 **功能请求：** 分享您的想法
- ⭐ **成功案例：** 告诉我们它如何帮助了您
- 🔧 **技术反馈：** 欢迎性能见解

---

## ☕ 支持项目

<div align="center">

**如果这个工具帮到了您，请考虑请我们喝杯咖啡！ ☕**

<table>
<tr>
<td align="center">
<b>个人微信</b><br>
<img src="img/wx_me.png" width="200" alt="作者微信"><br>
<small>微信：JavaRookie666</small>
</td>
<td align="center">
<b>微信赞赏</b><br>
<img src="img/wx_zsm2.png" width="200" alt="微信赞赏码"><br>
<small>要到饭咧？啊咧？啊咧？不给也没事~</small>
</td>
<td align="center">
<b>支付宝赞赏</b><br>
<img src="img/alipay.png" width="200" alt="支付宝赞赏码"><br>
<small>如果觉得有帮助，来包辣条犒劳一下吧~</small>
</td>
<td align="center">
<b>公众号</b><br>
<img src="img/wx_public_2.png" width="200" alt="微信公众号"><br>
<small>获取更多AI开发资源</small>
</td>
<td align="center">
<b>微信交流群</b><br>
<img src="img/qun-15.jpg" width="200" alt="WeChat"><br>
<small>二维码7天内有效，过期请加微信</small>
</td>
</tr>
</table>

</div>

---

## 📊 项目统计

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

---

## 📄 许可证

<details>
<summary><b>MIT 许可证</b></summary>

```
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

</details>

---

<div align="center">

**⭐ 如果这个项目帮到了您，请给个 Star！ ⭐**

**用 ❤️ 为 Cursor 社区制作**

</div>