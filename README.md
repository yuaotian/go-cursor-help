# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>



</div>

> ⚠️ **IMPORTANT NOTICE**
> 
> This tool currently supports:
> - ✅ Windows: Latest 1.0.x versions (Supported)
> - ✅ Mac/Linux: Latest 1.0.x versions (Supported, feedback welcome)
>
> Please check your Cursor version before using this tool.

<details open>
<summary><b>📦 Version History & Downloads</b></summary>

<div class="version-card" style="background: linear-gradient(135deg, #6e8efb, #a777e3); border-radius: 8px; padding: 15px; margin: 10px 0; color: white;">

### 🌟 Latest Versions

[View Full Version History]([CursorHistoryDown.md](https://github.com/oslook/cursor-ai-downloads?tab=readme-ov-file))

</div>



</details>

⚠️ **General Solutions for Cursor**
> 1.  Close Cursor, log out of your account, and delete your account in the official website Settings (refresh IP node: Japan, Singapore, USA, Hong Kong, prioritizing low latency - not necessarily required but change if conditions allow; Windows users are recommended to refresh DNS cache: `ipconfig /flushdns`)
> Go to the Cursor official website to delete your current account
> Steps: User avatar -> Setting -> Advanced▼ in the bottom left -> Delete Account
>
> 2.  Run the machine code refresh script, see the script address below, available in China
> 
> 3.  Re-register an account, log in, and open Cursor to resume normal use.
>
> 4.  Alternative solution: If still unusable after step [**3**], or if you encounter problems such as account registration failure or inability to delete an account, this usually means your browser has been identified or restricted by the target website (risk control). In this case, try switching browsers, such as: Edge, Google Chrome, Firefox. (Or, consider using a browser that can modify or randomize browser fingerprint information).


---

⚠️ **MAC Address Modification Warning**
> 
> For Mac users: This script includes a MAC address modification feature that will:
> - Modify your network interface's MAC address
> - Backup original MAC addresses before modification
> - This modification may temporarily affect network connectivity
> - You can skip this step when prompted during execution
>

<details >
<summary><b>🔒 Disable Auto-Update Feature</b></summary>

> To prevent Cursor from automatically updating to unsupported new versions, you can choose to disable the auto-update feature.

#### Method 1: Using Built-in Script (Recommended)

When running the reset tool, the script will ask if you want to disable auto-updates:
```text
[Question] Do you want to disable Cursor auto-update feature?
0) No - Keep default settings (Press Enter)
1) Yes - Disable auto-update
```

Select  `1`  to automatically complete the disable operation.

#### Method 2: Manual Disable

**Windows:**
1. Close all Cursor processes
2. Delete directory: `%LOCALAPPDATA%\cursor-updater`
3. Create a file with the same name (without extension) in the same location

**macOS:**
```bash
# NOTE: As tested, this method only works for version 0.45.11 and below.
# Close Cursor
pkill -f "Cursor"
# Replacing app-update.yml with a blank/read-only file
cd /Applications/Cursor.app/Contents/Resources
mv app-update.yml app-update.yml.bak
touch app-update.yml
chmod 444 app-update.yml

# Go to Settings -> Application -> Update, set Mode to none.
# This must be done to prevent Cursor from checking for updates.

# NOTE: The cursor-updater modification method may no longer be effective
# In any case, remove update directory and create blocking file
rm -rf ~/Library/Application\ Support/Caches/cursor-updater
touch ~/Library/Application\ Support/Caches/cursor-updater
```

**Linux:**
```bash
# Close Cursor
pkill -f "Cursor"
# Remove update directory and create blocking file
rm -rf ~/.config/cursor-updater
touch ~/.config/cursor-updater
```

> ⚠️ **Note:** After disabling auto-updates, you'll need to manually download and install new versions. It's recommended to update only after confirming the new version is compatible.


</details>

---

### 📝 Description

> When you encounter any of these messages:

#### Issue 1: Trial Account Limit <p align="right"><a href="#issue1"><img src="https://img.shields.io/badge/Move%20to%20Solution-Blue?style=plastic" alt="Back To Top"></a></p>

```text
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

#### Issue 2: API Key Limitation <p align="right"><a href="#issue2"><img src="https://img.shields.io/badge/Move%20to%20Solution-green?style=plastic" alt="Back To Top"></a></p>

```text
[New Issue]

Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
Request ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### Issue 3: Trial Request Limit

> This indicates you've reached the usage limit during the VIP free trial period:

```text
You've reached your trial request limit.
```

#### Issue 4: Claude 3.7 High Load <p align="right"><a href="#issue4"><img src="https://img.shields.io/badge/Move%20to%20Solution-purple?style=plastic" alt="Back To Top"></a></p>

```text
High Load 
We're experiencing high demand for Claude 3.7 Sonnet right now. Please upgrade to Pro, or switch to the
'default' model, Claude 3.5 sonnet, another model, or try again in a few moments.
```

<br>

<p id="issue2"></p>

#### Solution : Uninstall Cursor Completely And Reinstall (API key Issue)

1. Download [Geek.exe Uninstaller[Free]](https://geekuninstaller.com/download)
2. Uninstall Cursor app completely
3. Re-Install Cursor app
4. Continue to Solution 1

<br>

<p id="issue1"></p>

> Temporary Solution:

#### Solution 1: Quick Reset (Recommended)

1. Close Cursor application
2. Run the machine code reset script (see installation instructions below)
3. Reopen Cursor to continue using

#### Solution 2: Account Switch

1. File -> Cursor Settings -> Sign Out
2. Close Cursor
3. Run the machine code reset script
4. Login with a new account

#### Solution 3: Network Optimization

If the above solutions don't work, try:

- Switch to low-latency nodes (Recommended regions: Japan, Singapore, US, Hong Kong)
- Ensure network stability
- Clear browser cache and retry

#### Solution 4: Claude 3.7 Access Issue (High Load)

If you see the "High Load" message for Claude 3.7 Sonnet, this indicates Cursor is limiting free trial accounts from using the 3.7 model during certain times of the day. Try:

1. Switch to a new account created with Gmail, possibly connecting through a different IP address
2. Try accessing during off-peak hours (typically 5-10 AM or 3-7 PM when restrictions are often lighter)
3. Consider upgrading to Pro for guaranteed access
4. Use Claude 3.5 Sonnet as a fallback option

> Note: These access patterns may change as Cursor adjusts their resource allocation policies.

### 💻 System Support

<table>
<tr>
<td>

**Windows** ✅

- x64 (64-bit)
- x86 (32-bit)

</td>
<td>

**macOS** ✅

- Intel (x64)
- Apple Silicon (M1/M2)

</td>
<td>

**Linux** ✅

- x64 (64-bit)
- x86 (32-bit)
- ARM64

</td>
</tr>
</table>



### 🚀 One-Click Solution

<details open>
<summary><b>Global Users</b></summary>

**macOS**

```bash
# Method two
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

**Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash 
```

> **Note for Linux users:** The script attempts to find your Cursor installation by checking common paths (`/usr/bin`, `/usr/local/bin`, `$HOME/.local/bin`, `/opt/cursor`, `/snap/bin`), using the `which cursor` command, and searching within `/usr`, `/opt`, and `$HOME/.local`. If Cursor is installed elsewhere or not found via these methods, the script may fail. Ensure Cursor is accessible via one of these standard locations or methods.

**Windows**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

**Windows (Enhanced Version)**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
> Enhanced Cursor machine code modifier with dual-mode operation and trial reset functionality

<div align="center">
<img src="img/run_success.png" alt="Run Success" width="600"/>
</div>

</details>

<details open>
<summary><b>China Users (Recommended)</b></summary>

**macOS**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

**Linux**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

**Windows**

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

**Windows (Enhanced Version)**

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
> Enhanced Cursor machine code modifier with dual-mode operation and trial reset functionality

</details>

<details open>
<summary><b>Windows Terminal Run and Configuration</b></summary>

#### How to Open Administrator Terminal in Windows:

##### Method 1: Using Win + X Shortcut
```md
1. Press Win + X key combination
2. Select one of these options from the menu:
   - "Windows PowerShell (Administrator)"
   - "Windows Terminal (Administrator)"
   - "Terminal (Administrator)"
   (Options may vary depending on Windows version)
```

##### Method 2: Using Win + R Run Command
```md
1. Press Win + R key combination
2. Type powershell or pwsh in the Run dialog
3. Press Ctrl + Shift + Enter to run as administrator
   or type in the opened window: Start-Process pwsh -Verb RunAs
4. Enter the reset script in the administrator terminal:

irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

For the enhanced version:
```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

##### Method 3: Using Search
>![Search PowerShell](img/pwsh_1.png)
>
>Type pwsh in the search box, right-click and select "Run as administrator"
>![Run as Administrator](img/pwsh_2.png)

Enter the reset script in the administrator terminal:
```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

For the enhanced version:
```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

### 🔧 PowerShell Installation Guide 

If PowerShell is not installed on your system, you can install it using one of these methods:

#### Method 1: Install via Winget (Recommended)

1. Open Command Prompt or PowerShell
2. Run the following command:
```powershell
winget install --id Microsoft.PowerShell --source winget
```

#### Method 2: Manual Installation

1. Download the installer for your system:
   - [PowerShell-7.4.6-win-x64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi) (64-bit systems)
   - [PowerShell-7.4.6-win-x86.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi) (32-bit systems)
   - [PowerShell-7.4.6-win-arm64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi) (ARM64 systems)

2. Double-click the downloaded installer and follow the installation prompts

> 💡 If you encounter any issues, please refer to the [Microsoft Official Installation Guide](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)

</details>

#### Windows 安装特性:

- 🔍 Automatically detects and uses PowerShell 7 if available
- 🛡️ Requests administrator privileges via UAC prompt
- 📝 Falls back to Windows PowerShell if PS7 isn't found
- 💡 Provides manual instructions if elevation fails

That's it! The script will:

1. ✨ Install the tool automatically
2. 🔄 Reset your Cursor trial immediately

### 📦 Manual Installation

> Download the appropriate file for your system from [releases](https://github.com/yuaotian/go-cursor-help/releases/latest)

<details>
<summary>Windows Packages</summary>

- 64-bit: `cursor-id-modifier_windows_x64.exe`
- 32-bit: `cursor-id-modifier_windows_x86.exe`
</details>

<details>
<summary>macOS Packages</summary>

- Intel: `cursor-id-modifier_darwin_x64_intel`
- M1/M2: `cursor-id-modifier_darwin_arm64_apple_silicon`
</details>

<details>
<summary>Linux Packages</summary>

- 64-bit: `cursor-id-modifier_linux_x64`
- 32-bit: `cursor-id-modifier_linux_x86`
- ARM64: `cursor-id-modifier_linux_arm64`
</details>

### 🔧 Technical Details

<details>
<summary><b>Configuration Files</b></summary>

The program modifies Cursor's `storage.json` config file located at:

- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`
</details>

<details>
<summary><b>Modified Fields</b></summary>

The tool generates new unique identifiers for:

- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`
</details>

<details>
<summary><b>Manual Auto-Update Disable</b></summary>

Windows users can manually disable the auto-update feature:

1. Close all Cursor processes
2. Delete directory: `C:\Users\username\AppData\Local\cursor-updater`
3. Create a file with the same name: `cursor-updater` (without extension)

macOS/Linux users can try to locate similar `cursor-updater` directory in their system and perform the same operation.

</details>

<details>
<summary><b>Safety Features</b></summary>

- ✅ Safe process termination
- ✅ Atomic file operations
- ✅ Error handling and recovery
</details>

<details>
<summary><b>Registry Modification Notice</b></summary>

> ⚠️ **Important: This tool modifies the Windows Registry**

#### Modified Registry
- Path: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- Key: `MachineGuid`

#### Potential Impact
Modifying this registry key may affect:
- Windows system's unique device identification
- Device recognition and authorization status of certain software
- System features based on hardware identification

#### Safety Measures
1. Automatic Backup
   - Original value is automatically backed up before modification
   - Backup location: `%APPDATA%\Cursor\User\globalStorage\backups`
   - Backup file format: `MachineGuid.backup_YYYYMMDD_HHMMSS`

2. Manual Recovery Steps
   - Open Registry Editor (regedit)
   - Navigate to: `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
   - Right-click on `MachineGuid`
   - Select "Modify"
   - Paste the value from backup file

#### Important Notes
- Verify backup file existence before modification
- Use backup file to restore original value if needed
- Administrator privileges required for registry modification
</details>

---

### 📚 Recommended Reading

- [Cursor Issues Collection and Solutions](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI Universal Development Assistant Prompt Guide](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## 💬 Feedback & Suggestions

We value your feedback on the new enhanced script! If you've tried the `cursor_win_id_modifier.ps1` script, please share your experience:

- 🐛 **Bug Reports**: Found any issues? Let us know!
- 💡 **Feature Suggestions**: Have ideas for improvements?
- ⭐ **Success Stories**: Share how the tool helped you!
- 🔧 **Technical Feedback**: Performance, compatibility, or usability insights

Your feedback helps us improve the tool for everyone. Feel free to open an issue or contribute to the project!

---

##  Support

<div align="center">
<b>If you find this helpful, consider buying me a spicy gluten snack (Latiao) as appreciation~ 💁☕️</b>
<table>
<tr>

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
<td align="center">
<b>Alipay</b><br>
<img src="img/alipay_scan_pay.jpg" width="500" alt="Alipay"><br>
<em>1 Latiao = 1 AI thought cycle</em>
</td>
<td align="center">
<b>WeChat</b><br>
<img src="img/qun-16.png" width="500" alt="WeChat"><br>
<em>二维码7天内(8月4日前前)有效，过期请加微信</em>
</td>
<!-- <td align="center">
<b>ETC</b><br>
<img src="img/etc.png" width="100" alt="ETC Address"><br>
ETC: 0xa2745f4CD5d32310AC01694ABDB28bA32D125a6b
</td>
<td align="center"> -->
</td>
</tr>
</table>
</div>

---

## ⭐ Project Stats

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

## 📄 License

<details>
<summary><b>MIT License</b></summary>

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

