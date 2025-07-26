# 🚀 Cursor 無料試用リセットツール

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

## 🎯 ツールの機能

**Cursor 無料試用リセットツール** は、デバイス識別子を変更することで Cursor AI エディターの試用期間をリセットします。煩わしい試用制限メッセージが表示されたとき、このツールで新たなスタートを切ることができます！

### 🚨 解決する一般的な問題

<details>
<summary>🔴 <strong>"Too many free trial accounts used on this machine"</strong></summary>

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

**✅ 解決策：** 私たちのツールを使用してマシンのデバイス識別子をリセット！

</details>

<details>
<summary>🟡 <strong>"Composer relies on custom models..."</strong></summary>

```
Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
```

**✅ 解決策：** 
1. [Geek アンインストーラー](https://geekuninstaller.com/download) を使用して Cursor を完全にアンインストール
2. Cursor を再インストール
3. 私たちのリセットツールを実行

</details>

<details>
<summary>🟣 <strong>Claude 3.7 "High Load" 高負荷</strong></summary>

```
We're experiencing high demand for Claude 3.7 Sonnet right now. 
Please upgrade to Pro, or switch to the 'default' model...
```

**✅ 解決策：** 試用期間をリセットし、オフピーク時間（午前5-10時または午後3-7時）に試行

</details>

---

## 🖥️ プラットフォームサポート

<table align="center">
<tr>
<td align="center">

### 🐧 **Linux**
✅ 全ディストリビューション<br>
✅ x64, x86, ARM64<br>
✅ 自動検出

</td>
<td align="center">

### 🍎 **macOS**
✅ Intel & Apple Silicon<br>
✅ 権限自動修復<br>
✅ Python3 統合

</td>
<td align="center">

### 🪟 **Windows**
✅ x64, x86, ARM64<br>
✅ レジストリ変更<br>
✅ PowerShell 7 対応

</td>
</tr>
</table>

---

## ⚡ クイックスタート（ワンクリックソリューション）

### 🌍 グローバルユーザー

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

**PowerShell を管理者として実行：**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

### 🇨🇳 中国ユーザー（高速化）

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

## 🛠️ 管理者として実行する方法

### 🪟 Windows の方法

<details>
<summary><strong>方法1: Win + X ショートカット</strong></summary>

1. `Win + X` を押す
2. "Windows PowerShell (管理者)" または "ターミナル (管理者)" を選択
3. 上記のコマンドを貼り付け

</details>

<details>
<summary><strong>方法2: 検索方法</strong></summary>

1. スタートメニューで "PowerShell" を検索
2. 右クリック → "管理者として実行"
3. コマンドを貼り付け

![PowerShell を検索](img/pwsh_1.png)
![管理者として実行](img/pwsh_2.png)

</details>

<details>
<summary><strong>方法3: Win + R</strong></summary>

1. `Win + R` を押す
2. `powershell` と入力
3. `Ctrl + Shift + Enter` を押す

</details>

### 🔧 PowerShell インストール（必要な場合）

**オプション1: Winget を使用**
```powershell
winget install --id Microsoft.PowerShell --source winget
```

**オプション2: 手動ダウンロード**
- [PowerShell 7.4.6 x64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi)
- [PowerShell 7.4.6 x86](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi)
- [PowerShell 7.4.6 ARM64](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi)

---

## 🔧 高度な機能

### 🔒 自動更新の無効化

スクリプトは Cursor の自動更新機能を自動的に無効にしてバージョン競合を防ぎます：

**Windows:** `%LOCALAPPDATA%\cursor-updater` にブロックファイルを作成
**macOS:** `app-update.yml` を変更しブロックファイルを作成
**Linux:** `~/.config/cursor-updater` にブロックファイルを作成

### 🛡️ 安全機能

- ✅ **自動バックアップ** - 変更前に全ての元ファイルを自動バックアップ
- ✅ **プロセス管理** - Cursor プロセスを安全に停止・再起動
- ✅ **権限処理** - ファイル権限を自動修復（macOS）
- ✅ **エラー回復** - 問題発生時に自動でバックアップを復元
- ✅ **マルチメソッド対応** - 最大互換性のため複数の技術を使用

### 🔍 変更内容

<details>
<summary><strong>設定ファイル</strong></summary>

**場所:**
- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`

**変更フィールド:**
- `telemetry.machineId`
- `telemetry.macMachineId` 
- `telemetry.devDeviceId`
- `telemetry.sqmId`

</details>

<details>
<summary><strong>JavaScript ファイル（高度）</strong></summary>

ツールは Cursor の JavaScript ファイルにコードを注入してデバイス ID 関数を上書きします：
- `extensionHostProcess.js`
- `main.js`
- `cliProcessMain.js`

</details>

<details>
<summary><strong>Windows レジストリ（Windows のみ）</strong></summary>

**変更レジストリ:**
- パス: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- キー: `MachineGuid`

**⚠️ 重要:** 元の値は `%APPDATA%\Cursor\User\globalStorage\backups` に自動バックアップされます

</details>

---

## 🎉 成功スクリーンショット

<div align="center">
<img src="img/run_success.png" alt="成功スクリーンショット" width="600"/>
</div>

---

## 🆘 トラブルシューティング

### ❓ よくある問題

**Q: スクリプトが "Permission denied" と表示される**
A: `sudo`（Linux/macOS）または管理者権限（Windows）で実行していることを確認

**Q: Cursor がまだ試用制限を表示する**
A: フルリセットオプションを試し、Cursor を完全に再起動

**Q: スクリプトが Cursor インストールを見つけられない**
A: Cursor が標準的な場所にインストールされているか、[cursor.sh](https://cursor.sh/) からインストールしているか確認

**Q: macOS で Python3 エラー**
A: `brew install python3` で Python3 をインストール

### 🔄 一般的な解決手順

1. **Cursor を完全に閉じる**
2. **アカウントを削除** Cursor ウェブサイトから（設定 → 高度 → アカウント削除）
3. **リセットツールを実行**
4. **新しいアカウントを登録**
5. **Cursor を再起動**

---

## 💡 プロのヒント

- 🌐 **ネットワーク最適化:** 低遅延ノードを使用（日本、シンガポール、米国、香港）
- 🕐 **タイミング:** オフピーク時間に Claude 3.7 にアクセスを試行
- 🔄 **ブラウザ切り替え:** アカウント問題が続く場合は異なるブラウザを試行
- 📱 **IP リフレッシュ:** 可能であれば IP をリフレッシュすることを検討
- 🧹 **DNS キャッシュ:** Windows ユーザーは `ipconfig /flushdns` を実行可能

---

## 📚 追加リソース

- [Cursor 問題収集と解決策](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI 開発アシスタントガイド](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## 💬 フィードバック＆サポート

役に立ちましたか？ぜひお聞かせください！

- 🐛 **バグレポート:** GitHub で issue を開く
- 💡 **機能リクエスト:** アイデアを共有
- ⭐ **成功事例:** どのように役立ったかお教えください
- 🔧 **技術フィードバック:** パフォーマンスの洞察を歓迎

---

## ☕ プロジェクトをサポート

<div align="center">

**このツールがお役に立ちましたら、コーヒーをおごってください！ ☕**

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
<small>海外ユーザー</small>
</td>
</tr>
</table>

</div>

---

## 📊 プロジェクト統計

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

---

## 📄 ライセンス

<details>
<summary><b>MIT ライセンス</b></summary>

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

**⭐ このプロジェクトが役に立ったら Star をください！ ⭐**

**Cursor コミュニティのために ❤️ で作成**

</div>