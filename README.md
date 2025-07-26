# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

## 🎯 What This Tool Does

**Cursor Free Trial Reset Tool** helps you reset your Cursor AI editor trial by modifying device identifiers. When you see those annoying trial limit messages, this tool gives you a fresh start!

### 🚨 Common Issues This Fixes

<details>
<summary>🔴 <strong>"Too many free trial accounts used on this machine"</strong></summary>

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

**✅ Solution:** Use our tool to reset your machine's device identifiers!

</details>

<details>
<summary>🟡 <strong>"Composer relies on custom models..."</strong></summary>

```
Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
```

**✅ Solution:** 
1. Completely uninstall Cursor using [Geek Uninstaller](https://geekuninstaller.com/download)
2. Reinstall Cursor
3. Run our reset tool

</details>

<details>
<summary>🟣 <strong>"High Load" for Claude 3.7</strong></summary>

```
We're experiencing high demand for Claude 3.7 Sonnet right now. 
Please upgrade to Pro, or switch to the 'default' model...
```

**✅ Solution:** Reset your trial and try during off-peak hours (5-10 AM or 3-7 PM)

</details>

---

## 🖥️ Platform Support

<table align="center">
<tr>
<td align="center">

### 🐧 **Linux**
✅ All distributions<br>
✅ x64, x86, ARM64<br>
✅ Auto-detection

</td>
<td align="center">

### 🍎 **macOS**
✅ Intel & Apple Silicon<br>
✅ Permission auto-fix<br>
✅ Python3 integration

</td>
<td align="center">

### 🪟 **Windows**
✅ x64, x86, ARM64<br>
✅ Registry modification<br>
✅ PowerShell 7 ready

</td>
</tr>
</table>

---

## ⚡ Quick Start (One-Click Solution)

### 🌍 Global Users

<details open>
<summary><strong>🐧 Linux</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash 
```

</details>

<details open>
<summary><strong>🍎 macOS</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

</details>

<details open>
<summary><strong>🪟 Windows</strong></summary>

**Run in PowerShell as Administrator:**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

### 🇨🇳 China Users (Accelerated)

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

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

---

## 🛠️ How to Run as Administrator

### 🪟 Windows Methods

<details>
<summary><strong>Method 1: Win + X Shortcut</strong></summary>

1. Press `Win + X`
2. Select "Windows PowerShell (Administrator)" or "Terminal (Administrator)"
3. Paste the command above

</details>

<details>
<summary><strong>Method 2: Search Method</strong></summary>

1. Search for "PowerShell" in Start Menu
2. Right-click → "Run as administrator"
3. Paste the command

![PowerShell Search](img/pwsh_1.png)
![Run as Administrator](img/pwsh_2.png)

</details>

<details>
<summary><strong>Method 3: Win + R</strong></summary>

1. Press `Win + R`
2. Type `powershell`
3. Press `Ctrl + Shift + Enter`

</details>

### 🔧 PowerShell Installation (if needed)

**Option 1: Using Winget**
```powershell
winget install --id Microsoft.PowerShell --source winget
```

**Option 2: Manual Download**
- [PowerShell 7.4.6 x64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi)
- [PowerShell 7.4.6 x86](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi)
- [PowerShell 7.4.6 ARM64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi)

---

## 🔧 Advanced Features

### 🔒 Auto-Update Disable

The script can automatically disable Cursor's auto-update feature to prevent version conflicts:

**Windows:** Creates blocking file at `%LOCALAPPDATA%\cursor-updater`
**macOS:** Modifies `app-update.yml` and creates blocking files
**Linux:** Creates blocking file at `~/.config/cursor-updater`

### 🛡️ Safety Features

- ✅ **Automatic Backups** - All original files are backed up before modification
- ✅ **Process Management** - Safely stops and restarts Cursor processes  
- ✅ **Permission Handling** - Automatically fixes file permissions (macOS)
- ✅ **Error Recovery** - Restores backups if something goes wrong
- ✅ **Multi-Method Approach** - Uses multiple techniques for maximum compatibility

### 🔍 What Gets Modified

<details>
<summary><strong>Configuration Files</strong></summary>

**Location:**
- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`

**Modified Fields:**
- `telemetry.machineId`
- `telemetry.macMachineId` 
- `telemetry.devDeviceId`
- `telemetry.sqmId`

</details>

<details>
<summary><strong>JavaScript Files (Advanced)</strong></summary>

The tool injects code into Cursor's JavaScript files to override device ID functions:
- `extensionHostProcess.js`
- `main.js`
- `cliProcessMain.js`

</details>

<details>
<summary><strong>Windows Registry (Windows Only)</strong></summary>

**Modified Registry:**
- Path: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- Key: `MachineGuid`

**⚠️ Important:** Original values are automatically backed up to `%APPDATA%\Cursor\User\globalStorage\backups`

</details>

---

## 🎉 Success Screenshot

<div align="center">
<img src="img/run_success.png" alt="Success Screenshot" width="600"/>
</div>

---

## 🆘 Troubleshooting

### ❓ Common Issues

**Q: Script says "Permission denied"**
A: Make sure you're running with `sudo` (Linux/macOS) or as Administrator (Windows)

**Q: Cursor still shows trial limit**
A: Try the full reset option and restart Cursor completely

**Q: Script can't find Cursor installation**
A: Ensure Cursor is installed in standard locations or install from [cursor.sh](https://cursor.sh/)

**Q: Python3 error on macOS**
A: Install Python3 with `brew install python3`

### 🔄 General Solution Steps

1. **Close Cursor completely**
2. **Delete account** from Cursor website (Settings → Advanced → Delete Account)
3. **Run our reset tool**
4. **Register new account**
5. **Restart Cursor**

---

## 💡 Pro Tips

- 🌐 **Network Optimization:** Use low-latency nodes (Japan, Singapore, US, Hong Kong)
- 🕐 **Timing:** Try accessing Claude 3.7 during off-peak hours
- 🔄 **Browser Switching:** If account issues persist, try different browsers
- 📱 **IP Refresh:** Consider refreshing your IP if possible
- 🧹 **DNS Cache:** Windows users can run `ipconfig /flushdns`

---

## 📚 Additional Resources

- [Cursor Issues Collection & Solutions](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI Development Assistant Guide](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## 💬 Feedback & Support

Found this helpful? We'd love to hear from you!

- 🐛 **Bug Reports:** Open an issue on GitHub
- 💡 **Feature Requests:** Share your ideas
- ⭐ **Success Stories:** Tell us how it helped
- 🔧 **Technical Feedback:** Performance insights welcome

---

## ☕ Support the Project

<div align="center">

**If this tool saved your day, consider buying us a coffee! ☕**

<table>
<tr>
<td align="center">
<b>WeChat Pay</b><br>
<img src="img/wx_zsm2.png" width="200" alt="WeChat Pay"><br>
<small>微信赞赏</small>
</td>
<td align="center">
<b>Alipay</b><br>
<img src="img/alipay.png" width="200" alt="Alipay"><br>
<small>支付宝赞赏</small>
</td>
<td align="center">
<b>International</b><br>
<img src="img/alipay_scan_pay.jpg" width="200" alt="International"><br>
<small>International Users</small>
</td>
</tr>
</table>

</div>

---

## 📊 Project Stats

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

---

## 📄 License

<details>
<summary><b>MIT License</b></summary>

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

**⭐ Star this repo if it helped you! ⭐**

**Made with ❤️ for the Cursor community**

</div>