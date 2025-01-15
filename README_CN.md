# 🚀 Cursor 免费试用重置工具

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

### 📝 问题描述

> 当看到以下提示时重置Cursor试用期：

```text
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

> 如果看到以下提示：这表示在VIP免费试用期间已达到使用次数限制。
```text
You've reached your trial request limit.
```
> 临时解决方案：

#### 方案一：快速重置（推荐）
1. 关闭 Cursor 应用
2. 执行重置机器码脚本（见下方安装说明）
3. 重新打开 Cursor 即可继续使用

#### 方案二：账号切换
1. 文件 -> Cursor Settings -> 注销当前账号
2. 关闭 Cursor
3. 执行重置机器码脚本
4. 使用新账号重新登录

#### 方案三：网络优化
如果上述方案仍无法解决，可尝试：
- 切换至低延迟节点（推荐区域：日本、新加坡、美国、香港）
- 确保网络稳定性
- 清除浏览器缓存后重试

### 🚀 系统支持

<table>
<tr>
<td>

**Windows** ✅
- 通用版本

</td>
<td>

**macOS** ✅
- 通用版本

</td>
<td>

**Linux** ✅
- 通用版本

</td>
</tr>
</table>

### 🚀 一键解决方案

<details open>
<summary><b>海外用户</b></summary>

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.sh | sudo bash
```

**Windows**
```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.ps1 | iex
```
</details>

<details open>
<summary><b>国内用户（推荐）</b></summary>

**macOS**
```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh | sudo bash
```

**Linux**
```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

**Windows**
```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
</details>

### 💻 如何打开Windows管理员终端

> **Windows系统打开管理员终端的方法：**
> 1. 使用快捷键 `Win + X`
> 2. 在弹出的菜单中选择:
>    - "Windows PowerShell (管理员)" 
>    - "Windows Terminal (管理员)"
>    - "终端(管理员)"
>    (根据系统版本可能显示不同选项)

#### Windows 安装特性:
- 🔍 自动检测并使用 PowerShell 7（如果可用）
- 🛡️ 通过 UAC 提示请求管理员权限
- 📝 如果没有 PS7 则使用 Windows PowerShell
- 💡 如果提权失败会提供手动说明

完成后，脚本将：
1. ✨ 自动安装工具
2. 🔄 立即重置Cursor试用期

### 📦 手动安装

> 从 [releases](https://github.com/yuaotian/go-cursor-help/releases/latest) 下载适合您系统的文件

<details>
<summary>下载链接</summary>

- Windows: `go-cursor-help_windows`
- macOS: `go-cursor-help_macos`
- Linux: `go-cursor-help_linux`
</details>

### 🔧 技术细节

<details>
<summary><b>配置文件</b></summary>

程序修改Cursor的`storage.json`配置文件，位于：

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
</details>

<details>
<summary><b>手动禁用自动更新</b></summary>

Windows用户可以手动禁用自动更新功能：
1. 关闭所有Cursor进程
2. 删除目录：`C:\Users\用户名\AppData\Local\cursor-updater`
3. 创建同名文件：`cursor-updater`（不带扩展名）

macOS/Linux用户可以尝试在系统中找到类似的`cursor-updater`目录进行相同操作。
</details>

<details>
<summary><b>安全特性</b></summary>

- ✅ 安全的进程终止
- ✅ 原子文件操作
- ✅ 错误处理和恢复
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
<img src="img/wx_group.png" width="250" alt="微信群二维码"><br>
<small>7天内(1月15日前)有效，群满可以加公众号关注最新动态</small>
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
<img src="img/alipay.png" width="300" alt="支付宝赞赏码"><br>
<small>如果觉得有帮助,来包辣条犒劳一下吧~</small>
</td>
</tr>
</table>
</div>

---

### 📚 推荐阅读
- [Cursor异常问题收集和解决方案](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI通用开发助手提示词指南](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

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