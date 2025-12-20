# 🚀 Cursor 無料試用リセットツール

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md) | [🌏 日本語](README_JP.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

<div align="center">

## 💰 Cursor 公式チャージ済みアカウント

⚡️ **月額使い捨て | 専用アカウント | 最高のコスパ**

| プラン | 価格 | 定価 | 特典内容 |
|:---:|:---:|:---:|:---|
| **Pro** | ¥65/月 | $20 (約¥145) | $20 基本枠 + ボーナス ≈ 総額 $65 |
| **Pro+** | ¥265/月 | $60 (約¥435) | $70 基本枠 + ボーナス ≈ 総額 $130 |
| **Ultra** | ¥888/月 | $200 (約¥1450) | $400 基本枠 + 大量ボーナス |

> 📖 [公式料金ドキュメント](https://cursor.com/cn/docs/account/pricing) | 注: Cursor枠 = 基本枠 + 超過分 + 月末リセット

⚠️ **購入時の注意**：正規チャージ、専用アカウント | 7日間保証、日割り返金 | 3台まで | 在庫品は27〜30日有効

📱 **連絡先**：Telegram: [@yuaotian](https://t.me/yuaotian) | WeChat: `JavaRookie666`

---

### 📢 広告スペース

> 🔥 **広告枠募集中** - パートナーシップのお問い合わせ歓迎
>
> 📧 連絡先: Telegram [@yuaotian](https://t.me/yuaotian) | WeChat: `JavaRookie666`

---

</div>

> ⚠️ **重要なお知らせ**
> 
> このツールは現在以下のバージョンをサポートしています：
> - ✅ Windows: 最新の1.0.xバージョン（サポート済み）
> - ✅ Mac/Linux: 最新の1.0.xバージョン（サポート済み、フィードバック歓迎）
>
> このツールを使用する前に、Cursorのバージョンを確認してください。

<details open>
<summary><b>📦 バージョン履歴とダウンロード</b></summary>

<div class="version-card" style="background: linear-gradient(135deg, #6e8efb, #a777e3); border-radius: 8px; padding: 15px; margin: 10px 0; color: white;">

### 🌟 最新バージョン

[完全なバージョン履歴を見る]([CursorHistoryDown.md](https://github.com/oslook/cursor-ai-downloads?tab=readme-ov-file))

</div>

</details>

⚠️ **Cursorの一般的な解決策**
> 1.  Cursorを閉じ、アカウントからログアウトし、公式サイトの設定からアカウントを削除します（IPノードを更新：日本、シンガポール、アメリカ、香港など、低遅延を優先。必須ではありませんが条件が整えば変更してください。Windowsユーザーの場合はDNSキャッシュの更新をお勧めします：`ipconfig /flushdns`）
> Cursor公式サイトで現在のアカウントを削除します
> 手順：ユーザーアイコン->設定->左下のAdvanced▼->Delete Account
>
> 2.  マシンコードリセットスクリプトを実行します。下記のスクリプトアドレスを参照してください。
> 
> 3.  アカウントを再登録し、ログインして、Cursorを開くと、正常に使用できるようになります。
>
> 4.  代替案：ステップ[**3**]の後でもまだ使用できない場合、またはアカウント登録に失敗したり、アカウントを削除できないなどの問題が発生した場合、これは通常、ブラウザがターゲットサイトに識別または制限されている（リスク管理）ことを意味します。この場合、Edge、Google Chrome、Firefoxなど別のブラウザを試してみてください（または、ブラウザのフィンガープリント情報を変更またはランダム化できるブラウザの使用を検討してください）。


---

⚠️ **MACアドレス変更警告**
> 
> Macユーザーの皆様へ: このスクリプトにはMACアドレス変更機能が含まれています。以下の操作が行われます：
> - ネットワークインターフェースのMACアドレスを変更します
> - 変更前に元のMACアドレスをバックアップします
> - この変更により一時的にネットワーク接続が影響を受ける可能性があります
> - 実行中にこのステップをスキップすることができます
>

<details >
<summary><b>🔒 自動更新機能の無効化</b></summary>

> Cursorがサポートされていない新しいバージョンに自動的に更新されるのを防ぐために、自動更新機能を無効にすることができます。

#### 方法1: 組み込みスクリプトを使用する（推奨）

リセットツールを実行するとき、スクリプトは自動更新を無効にするかどうかを尋ねます：
```text
[質問] Cursorの自動更新機能を無効にしますか？
0) いいえ - デフォルト設定を維持（Enterキーを押す）
1) はい - 自動更新を無効にする
```

`1`を選択して無効化操作を自動的に完了します。

#### 方法2: 手動で無効化

**Windows:**
1. すべてのCursorプロセスを閉じます
2. ディレクトリを削除します： `%LOCALAPPDATA%\cursor-updater`
3. 同じ名前のファイルを作成します（拡張子なし）

**macOS:**
```bash
# 注意: テスト済みでは、この方法はバージョン0.45.11およびそれ以前のバージョンでのみ機能します。
# Cursorを閉じます
pkill -f "Cursor"
# app-update.ymlを空の読み取り専用ファイルに置き換えます
cd /Applications/Cursor.app/Contents/Resources
mv app-update.yml app-update.yml.bak
touch app-update.yml
chmod 444 app-update.yml

# 設定 -> アプリケーション -> 更新、モードをnoneに設定します。
# これを行わないと、Cursorは更新をチェックし続けます。

# 注意: cursor-updaterの変更方法はもはや有効ではないかもしれません
# いずれにせよ、更新ディレクトリを削除し、ブロックファイルを作成します
rm -rf ~/Library/Application\ Support/Caches/cursor-updater
touch ~/Library/Application\ Support/Caches/cursor-updater
```

**Linux:**
```bash
# Cursorを閉じます
pkill -f "Cursor"
# 更新ディレクトリを削除し、ブロックファイルを作成します
rm -rf ~/.config/cursor-updater
touch ~/.config/cursor-updater
```

> ⚠️ **注意:** 自動更新を無効にした後、新しいバージョンを手動でダウンロードしてインストールする必要があります。新しいバージョンが互換性があることを確認した後に更新することをお勧めします。

</details>

---

### 📝 説明

> これらのメッセージのいずれかに遭遇した場合：

#### 問題1: 試用アカウント制限 <p align="right"><a href="#issue1"><img src="https://img.shields.io/badge/Move%20to%20Solution-Blue?style=plastic" alt="Back To Top"></a></p>

```text
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

#### 問題2: APIキー制限 <p align="right"><a href="#issue2"><img src="https://img.shields.io/badge/Move%20to%20Solution-green?style=plastic" alt="Back To Top"></a></p>

```text
[New Issue]

Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
Request ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 問題3: 試用リクエスト制限

> これは、VIP無料試用期間中に使用制限に達したことを示しています：

```text
You've reached your trial request limit.
```

#### 問題4: Claude 3.7 高負荷 <p align="right"><a href="#issue4"><img src="https://img.shields.io/badge/Move%20to%20Solution-purple?style=plastic" alt="Back To Top"></a></p>

```text
High Load 
We're experiencing high demand for Claude 3.7 Sonnet right now. Please upgrade to Pro, or switch to the
'default' model, Claude 3.5 sonnet, another model, or try again in a few moments.
```

<br>

<p id="issue2"></p>

#### 解決策 : Cursorを完全にアンインストールして再インストールする（APIキーの問題）

1. [Geek.exeアンインストーラー[無料]](https://geekuninstaller.com/download)をダウンロードします
2. Cursorアプリを完全にアンインストールします
3. Cursorアプリを再インストールします
4. 解決策1を続行します

<br>

<p id="issue1"></p>

> 一時的な解決策：

#### 解決策1: クイックリセット（推奨）

1. Cursorアプリケーションを閉じます
2. マシンコードリセットスクリプトを実行します（以下のインストール手順を参照）
3. Cursorを再度開いて使用を続けます

#### 解決策2: アカウントの切り替え

1. ファイル -> Cursor設定 -> サインアウト
2. Cursorを閉じます
3. マシンコードリセットスクリプトを実行します
4. 新しいアカウントでログインします

#### 解決策3: ネットワークの最適化

上記の解決策が機能しない場合は、次のことを試してください：

- 低遅延ノードに切り替えます（推奨地域：日本、シンガポール、米国、香港）
- ネットワークの安定性を確保します
- ブラウザのキャッシュをクリアして再試行します

#### 解決策4: Claude 3.7 アクセス問題（高負荷）

Claude 3.7 Sonnetの"High Load"メッセージが表示された場合、これはCursorが特定の時間帯に無料試用アカウントの3.7モデルの使用を制限していることを示しています。次のことを試してください：

1. Gmailで作成した新しいアカウントに切り替えます。異なるIPアドレスを使用して接続することをお勧めします
2. 非ピーク時間帯にアクセスを試みます（通常、5-10 AMまたは3-7 PMの間に制限が少ないです）
3. Proにアップグレードしてアクセスを保証します
4. Claude 3.5 Sonnetを代替オプションとして使用します

> 注意: Cursorがリソース配分ポリシーを調整するにつれて、これらのアクセスパターンは変更される可能性があります。

### 💻 システムサポート

<table>
<tr>
<td>

**Windows** ✅

- x64 (64ビット)
- x86 (32ビット)

</td>
<td>

**macOS** ✅

- Intel (x64)
- Apple Silicon (M1/M2)

</td>
<td>

**Linux** ✅

- x64 (64ビット)
- x86 (32ビット)
- ARM64

</td>
</tr>
</table>



### 🚀 ワンクリックソリューション

<details open>
<summary><b>グローバルユーザー</b></summary>

**macOS**

```bash
# 方法2
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

**Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash 
```

**Windows**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

**Windows (強化版)**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
> デュアルモード操作とトライアルリセット機能を備えた強化版Cursorマシンコード修正ツール

<div align="center">
<img src="img/run_success.png" alt="Run Success" width="600"/>
</div>

</details>

<details open>
<summary><b>中国ユーザー（推奨）</b></summary>

**macOS**

```bash
curl -fsSL https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh -o ./cursor_mac_id_modifier.sh && sudo bash ./cursor_mac_id_modifier.sh && rm ./cursor_mac_id_modifier.sh
```

**Linux**

```bash
curl -fsSL https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

> **Linuxユーザーへの注意：** スクリプトは、一般的なパス（`/usr/bin`, `/usr/local/bin`, `$HOME/.local/bin`, `/opt/cursor`, `/snap/bin`）の確認、`which cursor` コマンドの使用、および `/usr`、`/opt`、`$HOME/.local` ディレクトリ内の検索によって、Cursor のインストールを見つけようとします。Cursorが他の場所にインストールされているか、これらの方法で見つからない場合、スクリプトは失敗する可能性があります。これらの標準的な場所または方法のいずれかを通じてCursorにアクセスできることを確認してください。

**Windows**

```powershell
irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

**Windows (強化版)**

```powershell
irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```
> デュアルモード操作とトライアルリセット機能を備えた強化版Cursorマシンコード修正ツール

</details>

<details open>
<summary><b>Windowsターミナルの実行と構成</b></summary>

#### Windowsで管理者ターミナルを開く方法：

##### 方法1: Win + Xショートカットを使用する
```md
1. Win + Xキーの組み合わせを押します
2. メニューから次のオプションのいずれかを選択します：
   - "Windows PowerShell (管理者)"
   - "Windows Terminal (管理者)"
   - "ターミナル (管理者)"
   （Windowsのバージョンによってオプションが異なる場合があります）
```

##### 方法2: Win + R実行コマンドを使用する
```md
1. Win + Rキーの組み合わせを押します
2. 実行ダイアログにpowershellまたはpwshと入力します
3. Ctrl + Shift + Enterを押して管理者として実行します
   または開いたウィンドウに次のように入力します： Start-Process pwsh -Verb RunAs
4. 管理者ターミナルにリセットスクリプトを入力します：

irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

強化版スクリプト：
```powershell
irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

##### 方法3: 検索を使用する
>![PowerShellを検索](img/pwsh_1.png)
>
>検索ボックスにpwshと入力し、右クリックして「管理者として実行」を選択します
>![管理者として実行](img/pwsh_2.png)

管理者ターミナルにリセットスクリプトを入力します：
```powershell
irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

強化版スクリプト：
```powershell
irm https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

### 🔧 PowerShellインストールガイド

システムにPowerShellがインストールされていない場合は、次の方法でインストールできます：

#### 方法1: Wingetを使用してインストール（推奨）

1. コマンドプロンプトまたはPowerShellを開きます
2. 次のコマンドを実行します：
```powershell
winget install --id Microsoft.PowerShell --source winget
```

#### 方法2: 手動でインストール

1. システムに適したインストーラーをダウンロードします：
   - [PowerShell-7.4.6-win-x64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi)（64ビットシステム用）
   - [PowerShell-7.4.6-win-x86.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi)（32ビットシステム用）
   - [PowerShell-7.4.6-win-arm64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi)（ARM64システム用）

2. ダウンロードしたインストーラーをダブルクリックし、インストールの指示に従います

> 💡 問題が発生した場合は、[Microsoft公式インストールガイド](https://learn.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell-on-windows)を参照してください

</details>

#### Windowsインストール機能：

- 🔍 PowerShell 7が利用可能な場合は自動的に検出して使用します
- 🛡️ UACプロンプトを介して管理者権限を要求します
- 📝 PS7が見つからない場合はWindows PowerShellにフォールバックします
- 💡 権限昇格に失敗した場合は手動の指示を提供します

これで完了です！スクリプトは次のことを行います：

1. ✨ ツールを自動的にインストールします
2. 🔄 Cursorの試用期間を即座にリセットします

### 📦 手動インストール

> [リリース](https://github.com/yuaotian/go-cursor-help/releases/latest)からシステムに適したファイルをダウンロードします

<details>
<summary>Windowsパッケージ</summary>

- 64ビット: `cursor-id-modifier_windows_x64.exe`
- 32ビット: `cursor-id-modifier_windows_x86.exe`
</details>

<details>
<summary>macOSパッケージ</summary>

- Intel: `cursor-id-modifier_darwin_x64_intel`
- M1/M2: `cursor-id-modifier_darwin_arm64_apple_silicon`
</details>

<details>
<summary>Linuxパッケージ</summary>

- 64ビット: `cursor-id-modifier_linux_x64`
- 32ビット: `cursor-id-modifier_linux_x86`
- ARM64: `cursor-id-modifier_linux_arm64`
</details>

### 🔧 技術的詳細

<details>
<summary><b>構成ファイル</b></summary>

プログラムはCursorの`storage.json`構成ファイルを変更します。場所は次のとおりです：

- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`
</details>

<details>
<summary><b>変更されたフィールド</b></summary>

ツールは次の新しい一意の識別子を生成します：

- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`
</details>

<details>
<summary><b>手動自動更新無効化</b></summary>

Windowsユーザーは自動更新機能を手動で無効にすることができます：

1. すべてのCursorプロセスを閉じます
2. ディレクトリを削除します： `C:\Users\username\AppData\Local\cursor-updater`
3. 同じ名前のファイルを作成します： `cursor-updater`（拡張子なし）

macOS/Linuxユーザーはシステム内で同様の`cursor-updater`ディレクトリを見つけて同じ操作を行うことができます。

</details>

<details>
<summary><b>安全機能</b></summary>

- ✅ 安全なプロセス終了
- ✅ アトミックファイル操作
- ✅ エラーハンドリングとリカバリ
</details>

<details>
<summary><b>レジストリ変更通知</b></summary>

> ⚠️ **重要: このツールはWindowsレジストリを変更します**

#### 変更されたレジストリ
- パス: `コンピュータ\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
- キー: `MachineGuid`

#### 潜在的な影響
このレジストリキーを変更すると、次のことに影響を与える可能性があります：
- Windowsシステムの一意のデバイス識別
- 特定のソフトウェアのデバイス認識と認証状態
- ハードウェア識別に基づくシステム機能

#### 安全対策
1. 自動バックアップ
   - 変更前に元の値が自動的にバックアップされます
   - バックアップ場所： `%APPDATA%\Cursor\User\globalStorage\backups`
   - バックアップファイル形式： `MachineGuid.backup_YYYYMMDD_HHMMSS`

2. 手動復元手順
   - レジストリエディタ（regedit）を開きます
   - 次の場所に移動します： `コンピュータ\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`
   - `MachineGuid`を右クリックします
   - 「修正」を選択します
   - バックアップファイルの値を貼り付けます

#### 重要な注意事項
- 変更前にバックアップファイルの存在を確認します
- 必要に応じてバックアップファイルを使用して元の値を復元します
- レジストリの変更には管理者権限が必要です
</details>

---

### 📚 推奨読書

- [Cursorの問題収集と解決策](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AIユニバーサル開発アシスタントプロンプトガイド](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

##  サポート

<div align="center">
<b>このツールが役立つと感じた場合、スパイシーグルテンのおやつ（Latiao）を買っていただけると嬉しいです~ 💁☕️</b>
<table>
<tr>

<td align="center">
<b>WeChat Pay</b><br>
<img src="img/wx_zsm2.png" width="500" alt="WeChat Pay"><br>
<small>要到饭咧？啊咧？啊咧？不给也没事~ 请随意打赏</small>
</td>
<td align="center">
<b>Alipay</b><br>
<img src="img/alipay.png" width="500" alt="Alipay"><br>
<small>如果觉得有帮助,来包辣条犒劳一下吧~</small>
</td>
<td align="center">
<b>Alipay</b><br>
<img src="img/alipay_scan_pay.jpg" width="500" alt="Alipay"><br>
<em>1 Latiao = 1 AI thought cycle</em>
</td>
<td align="center">
<b>WeChat</b><br>
<img src="img/qun-20.jpg" width="500" alt="WeChat"><br>
<em>二维码7天内(11月25日前前)有效，过期请加微信或者公众号`煎饼果子卷AI`</em>
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

## 💬 フィードバック＆提案

新しい強化スクリプトに関するフィードバックをお待ちしています！`cursor_win_id_modifier.ps1` スクリプトをお試しいただいた方は、ぜひご体験をお聞かせください：

- 🐛 **バグレポート**：問題を発見されましたか？お知らせください！
- 💡 **機能提案**：改善のアイデアはありますか？
- ⭐ **成功事例**：ツールがどのようにお役に立ったかお聞かせください！
- 🔧 **技術的フィードバック**：パフォーマンス、互換性、使いやすさに関するご意見

皆様のフィードバックは、すべてのユーザーのためにツールを改善するのに役立ちます。お気軽にissueを開いたり、プロジェクトに貢献してください！

---

## ⭐ プロジェクト統計

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

## 📄 ライセンス

<details>
<summary><b>MITライセンス</b></summary>

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
