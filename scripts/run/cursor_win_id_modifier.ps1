# 设置输出编码为 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色定义（兼容 PowerShell 5.1 和 7.x）
$ESC = [char]27
$RED = "$ESC[31m"
$GREEN = "$ESC[32m"
$YELLOW = "$ESC[33m"
$BLUE = "$ESC[34m"
$NC = "$ESC[0m"

# 启动时尝试调整终端窗口大小为 120x40（列x行）；不支持/失败时静默忽略，避免影响脚本主流程
function Try-ResizeTerminalWindow {
    param(
        [int]$Columns = 120,
        [int]$Rows = 40
    )

    # 方式1：通过 PowerShell Host RawUI 调整（传统控制台、ConEmu 等可能支持）
    try {
        $rawUi = $null
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUi = $Host.UI.RawUI
        }

        if ($rawUi) {
            try {
                # BufferSize 必须 >= WindowSize，否则会抛异常
                $bufferSize = $rawUi.BufferSize
                $newBufferSize = New-Object System.Management.Automation.Host.Size (
                    ([Math]::Max($bufferSize.Width, $Columns)),
                    ([Math]::Max($bufferSize.Height, $Rows))
                )
                $rawUi.BufferSize = $newBufferSize
            } catch {
                # 静默忽略
            }

            try {
                $rawUi.WindowSize = New-Object System.Management.Automation.Host.Size ($Columns, $Rows)
            } catch {
                # 静默忽略
            }
        }
    } catch {
        # 静默忽略
    }

    # 方式2：通过 ANSI 转义序列再尝试一次（Windows Terminal 等可能支持）
    try {
        if (-not [Console]::IsOutputRedirected) {
            $escChar = [char]27
            [Console]::Out.Write("$escChar[8;${Rows};${Columns}t")
        }
    } catch {
        # 静默忽略
    }
}

Try-ResizeTerminalWindow -Columns 120 -Rows 40

# 路径解析：优先使用 .NET 获取系统目录，避免环境变量缺失导致路径异常
function Get-FolderPathSafe {
    param(
        [Parameter(Mandatory = $true)][System.Environment+SpecialFolder]$SpecialFolder,
        [Parameter(Mandatory = $true)][string]$EnvVarName,
        [Parameter(Mandatory = $true)][string]$FallbackRelative,
        [Parameter(Mandatory = $true)][string]$Label
    )
    $path = [Environment]::GetFolderPath($SpecialFolder)
    if ([string]::IsNullOrWhiteSpace($path)) {
        $envValue = [Environment]::GetEnvironmentVariable($EnvVarName)
        if (-not [string]::IsNullOrWhiteSpace($envValue)) {
            $path = $envValue
        }
    }
    if ([string]::IsNullOrWhiteSpace($path)) {
        $userProfile = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
        if ([string]::IsNullOrWhiteSpace($userProfile)) {
            $userProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
        }
        if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
            $path = Join-Path $userProfile $FallbackRelative
        }
    }
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Host "$YELLOW⚠️  [路径]$NC $Label 无法解析，将尝试其他方式"
    } else {
        Write-Host "$BLUEℹ️  [路径]$NC ${Label}: $path"
    }
    return $path
}

function Initialize-CursorPaths {
    Write-Host "$BLUEℹ️  [路径]$NC 开始解析 Cursor 相关路径..."
    $global:CursorAppDataRoot = Get-FolderPathSafe `
        -SpecialFolder ([System.Environment+SpecialFolder]::ApplicationData) `
        -EnvVarName "APPDATA" `
        -FallbackRelative "AppData\Roaming" `
        -Label "Roaming AppData"
    $global:CursorLocalAppDataRoot = Get-FolderPathSafe `
        -SpecialFolder ([System.Environment+SpecialFolder]::LocalApplicationData) `
        -EnvVarName "LOCALAPPDATA" `
        -FallbackRelative "AppData\Local" `
        -Label "Local AppData"
    $global:CursorUserProfileRoot = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrWhiteSpace($global:CursorUserProfileRoot)) {
        $global:CursorUserProfileRoot = [Environment]::GetEnvironmentVariable("USERPROFILE")
    }
    if (-not [string]::IsNullOrWhiteSpace($global:CursorUserProfileRoot)) {
        Write-Host "$BLUEℹ️  [路径]$NC 用户目录: $global:CursorUserProfileRoot"
    }
    $global:CursorAppDataDir = if ($global:CursorAppDataRoot) { Join-Path $global:CursorAppDataRoot "Cursor" } else { $null }
    $global:CursorLocalAppDataDir = if ($global:CursorLocalAppDataRoot) { Join-Path $global:CursorLocalAppDataRoot "Cursor" } else { $null }
    $global:CursorStorageDir = if ($global:CursorAppDataDir) { Join-Path $global:CursorAppDataDir "User\globalStorage" } else { $null }
    $global:CursorStorageFile = if ($global:CursorStorageDir) { Join-Path $global:CursorStorageDir "storage.json" } else { $null }
    $global:CursorBackupDir = if ($global:CursorStorageDir) { Join-Path $global:CursorStorageDir "backups" } else { $null }

    if ($global:CursorStorageDir -and -not (Test-Path $global:CursorStorageDir)) {
        Write-Host "$YELLOW⚠️  [路径]$NC 全局配置目录不存在: $global:CursorStorageDir"
    }
    if ($global:CursorStorageFile) {
        if (Test-Path $global:CursorStorageFile) {
            Write-Host "$GREEN✅ [路径]$NC 已找到配置文件: $global:CursorStorageFile"
        } else {
            Write-Host "$YELLOW⚠️  [路径]$NC 配置文件不存在: $global:CursorStorageFile"
        }
    }
}

function Normalize-CursorInstallCandidate {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    $candidate = $Path.Trim().Trim('"')
    if (Test-Path $candidate -PathType Leaf) {
        $candidate = Split-Path -Parent $candidate
    }
    return $candidate
}

function Test-CursorInstallPath {
    param([string]$Path)
    $candidate = Normalize-CursorInstallCandidate -Path $Path
    if (-not $candidate) {
        return $false
    }
    $exePath = Join-Path $candidate "Cursor.exe"
    return (Test-Path $exePath)
}

function Get-CursorInstallPathFromRegistry {
    $results = @()
    $uninstallKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($key in $uninstallKeys) {
        try {
            $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                if (-not $item.DisplayName -or $item.DisplayName -notlike "*Cursor*") {
                    continue
                }
                $candidate = $null
                if ($item.InstallLocation) {
                    $candidate = $item.InstallLocation
                } elseif ($item.DisplayIcon) {
                    $candidate = $item.DisplayIcon.Split(',')[0].Trim('"')
                } elseif ($item.UninstallString) {
                    $candidate = $item.UninstallString.Split(' ')[0].Trim('"')
                }
                if ($candidate) {
                    $results += $candidate
                }
            }
        } catch {
            Write-Host "$YELLOW⚠️  [路径]$NC 读取注册表失败: $key"
        }
    }
    return $results | Where-Object { $_ } | Select-Object -Unique
}

function Request-CursorInstallPathFromUser {
    Write-Host "$YELLOW💡 [提示]$NC 自动检测失败，可手动选择 Cursor 安装目录（包含 Cursor.exe）"
    $selectedPath = $null
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "请选择 Cursor 安装目录（包含 Cursor.exe）"
        $dialog.ShowNewFolderButton = $false
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedPath = $dialog.SelectedPath
        }
    } catch {
        Write-Host "$YELLOW⚠️  [提示]$NC 无法打开选择窗口，将使用命令行输入"
    }
    if (-not $selectedPath) {
        $manualInput = Read-Host "请输入 Cursor 安装目录（包含 Cursor.exe），或直接回车取消"
        if (-not [string]::IsNullOrWhiteSpace($manualInput)) {
            $selectedPath = $manualInput
        }
    }
    if ($selectedPath) {
        $normalized = Normalize-CursorInstallCandidate -Path $selectedPath
        if ($normalized -and (Test-CursorInstallPath -Path $normalized)) {
            Write-Host "$GREEN✅ [发现]$NC 手动指定安装路径: $normalized"
            return $normalized
        }
        Write-Host "$RED❌ [错误]$NC 手动路径无效: $selectedPath"
    }
    return $null
}

function Resolve-CursorInstallPath {
    param([switch]$AllowPrompt)
    if ($global:CursorInstallPath -and (Test-CursorInstallPath -Path $global:CursorInstallPath)) {
        return $global:CursorInstallPath
    }

    Write-Host "$BLUE🔎 [路径]$NC 正在检测 Cursor 安装目录..."
    $candidates = @()
    if ($global:CursorLocalAppDataRoot) {
        $candidates += (Join-Path $global:CursorLocalAppDataRoot "Programs\Cursor")
    }
    $programFiles = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)
    if ($programFiles) {
        $candidates += (Join-Path $programFiles "Cursor")
    }
    $programFilesX86 = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
    if ($programFilesX86) {
        $candidates += (Join-Path $programFilesX86 "Cursor")
    }

    $regCandidates = @(Get-CursorInstallPathFromRegistry)
    if ($regCandidates.Count -gt 0) {
        Write-Host "$BLUEℹ️  [路径]$NC 从注册表发现候选路径: $($regCandidates -join '; ')"
        $candidates += $regCandidates
    }

    $fixedDrives = [IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' }
    foreach ($drive in $fixedDrives) {
        $root = $drive.RootDirectory.FullName
        $candidates += (Join-Path $root "Program Files\Cursor")
        $candidates += (Join-Path $root "Program Files (x86)\Cursor")
        $candidates += (Join-Path $root "Cursor")
    }

    $candidates = $candidates | Where-Object { $_ } | Select-Object -Unique
    $totalCandidates = $candidates.Count
    for ($i = 0; $i -lt $totalCandidates; $i++) {
        $candidate = Normalize-CursorInstallCandidate -Path $candidates[$i]
        $attempt = $i + 1
        if (-not $candidate) {
            continue
        }
        Write-Host "$BLUE⏳ [路径]$NC ($attempt/$totalCandidates) 尝试安装路径: $candidate"
        if (Test-CursorInstallPath -Path $candidate) {
            $global:CursorInstallPath = $candidate
            Write-Host "$GREEN✅ [发现]$NC 找到Cursor安装路径: $candidate"
            return $candidate
        }
    }

    if ($AllowPrompt) {
        $manualPath = Request-CursorInstallPathFromUser
        if ($manualPath) {
            $global:CursorInstallPath = $manualPath
            return $manualPath
        }
    }

    Write-Host "$RED❌ [错误]$NC 未找到Cursor应用安装路径"
    Write-Host "$YELLOW💡 [提示]$NC 请确认Cursor已正确安装或手动指定路径"
    return $null
}

# 配置文件路径（初始化后统一使用全局变量）
Initialize-CursorPaths
$STORAGE_FILE = $global:CursorStorageFile
$BACKUP_DIR = $global:CursorBackupDir

# PowerShell原生方法生成随机字符串
function Generate-RandomString {
    param([int]$Length)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $result
}

# 🔍 简易 JavaScript 花括号匹配（用于在限定片段内定位函数边界，避免正则跨段误替换）
# 说明：这是一个轻量解析器，足以应对 main.js 中的压缩函数体（含 try/catch、字符串、注释）。
function Find-JsMatchingBraceEnd {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$OpenBraceIndex,
        [int]$MaxScan = 20000
    )

    if ($OpenBraceIndex -lt 0 -or $OpenBraceIndex -ge $Text.Length) {
        return -1
    }

    $limit = [Math]::Min($Text.Length, $OpenBraceIndex + $MaxScan)

    $depth = 1
    $inSingle = $false
    $inDouble = $false
    $inTemplate = $false
    $inLineComment = $false
    $inBlockComment = $false
    $escape = $false

    for ($i = $OpenBraceIndex + 1; $i -lt $limit; $i++) {
        $ch = $Text[$i]
        $next = if ($i + 1 -lt $limit) { $Text[$i + 1] } else { [char]0 }

        if ($inLineComment) {
            if ($ch -eq "`n") { $inLineComment = $false }
            continue
        }
        if ($inBlockComment) {
            if ($ch -eq '*' -and $next -eq '/') { $inBlockComment = $false; $i++; continue }
            continue
        }

        if ($inSingle) {
            if ($escape) { $escape = $false; continue }
            if ($ch -eq '\') { $escape = $true; continue }
            if ($ch -eq "'") { $inSingle = $false }
            continue
        }
        if ($inDouble) {
            if ($escape) { $escape = $false; continue }
            if ($ch -eq '\') { $escape = $true; continue }
            if ($ch -eq '"') { $inDouble = $false }
            continue
        }
        if ($inTemplate) {
            if ($escape) { $escape = $false; continue }
            if ($ch -eq '\') { $escape = $true; continue }
            if ($ch -eq '`') { $inTemplate = $false }
            continue
        }

        # 注释检测（仅在非字符串状态下）
        if ($ch -eq '/' -and $next -eq '/') { $inLineComment = $true; $i++; continue }
        if ($ch -eq '/' -and $next -eq '*') { $inBlockComment = $true; $i++; continue }

        # 字符串/模板字符串
        if ($ch -eq "'") { $inSingle = $true; continue }
        if ($ch -eq '"') { $inDouble = $true; continue }
        if ($ch -eq '`') { $inTemplate = $true; continue }

        # 花括号深度
        if ($ch -eq '{') { $depth++; continue }
        if ($ch -eq '}') {
            $depth--
            if ($depth -eq 0) { return $i }
        }
    }

    return -1
}

# 🔧 修改Cursor内核JS文件实现设备识别绕过（增强版三重方案）
# 方案A: someValue占位符替换 - 稳定锚点，不依赖混淆后的函数名
# 方案B: b6 定点重写 - 机器码源函数直接返回固定值
# 方案C: Loader Stub + 外置 Hook - 主/共享进程仅加载外置 Hook 文件
function Modify-CursorJSFiles {
    Write-Host ""
    Write-Host "$BLUE🔧 [内核修改]$NC 开始修改Cursor内核JS文件实现设备识别绕过..."
    Write-Host "$BLUE💡 [方案]$NC 使用增强版三重方案：占位符替换 + b6 定点重写 + Loader Stub + 外置 Hook"
    Write-Host ""

    # Windows版Cursor应用路径（支持自动检测 + 手动兜底）
    $cursorAppPath = Resolve-CursorInstallPath -AllowPrompt
    if (-not $cursorAppPath) {
        return $false
    }

    # 生成或复用设备标识符（优先使用配置中生成的值）
    $useConfigIds = $false
    if ($global:CursorIds -and $global:CursorIds.machineId -and $global:CursorIds.macMachineId -and $global:CursorIds.devDeviceId -and $global:CursorIds.sqmId) {
        $machineId = [string]$global:CursorIds.machineId
        $macMachineId = [string]$global:CursorIds.macMachineId
        $deviceId = [string]$global:CursorIds.devDeviceId
        $sqmId = [string]$global:CursorIds.sqmId
        # 机器 GUID 用于模拟注册表/原始机器码读取
        $machineGuid = if ($global:CursorIds.machineGuid) { [string]$global:CursorIds.machineGuid } else { [System.Guid]::NewGuid().ToString().ToLower() }
        $sessionId = if ($global:CursorIds.sessionId) { [string]$global:CursorIds.sessionId } else { [System.Guid]::NewGuid().ToString().ToLower() }
        # 使用 UTC 时间生成/规范化 firstSessionDate，避免本地时间却带 Z 的语义错误；同时兼容 ConvertFrom-Json 可能返回 DateTime
        $firstSessionDateValue = if ($global:CursorIds.firstSessionDate) {
            $rawFirstSessionDate = $global:CursorIds.firstSessionDate
            if ($rawFirstSessionDate -is [DateTime]) {
                $rawFirstSessionDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            } elseif ($rawFirstSessionDate -is [DateTimeOffset]) {
                $rawFirstSessionDate.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            } else {
                [string]$rawFirstSessionDate
            }
        } else {
            (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        $macAddress = if ($global:CursorIds.macAddress) { [string]$global:CursorIds.macAddress } else { "00:11:22:33:44:55" }
        $useConfigIds = $true
    } else {
        $randomBytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($randomBytes)
        $machineId = [System.BitConverter]::ToString($randomBytes) -replace '-',''
        $rng.Dispose()
        $deviceId = [System.Guid]::NewGuid().ToString().ToLower()
        $randomBytes2 = New-Object byte[] 32
        $rng2 = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng2.GetBytes($randomBytes2)
        $macMachineId = [System.BitConverter]::ToString($randomBytes2) -replace '-',''
        $rng2.Dispose()
        $sqmId = "{" + [System.Guid]::NewGuid().ToString().ToUpper() + "}"
        # 机器 GUID 用于模拟注册表/原始机器码读取
        $machineGuid = [System.Guid]::NewGuid().ToString().ToLower()
        $sessionId = [System.Guid]::NewGuid().ToString().ToLower()
        # 使用 UTC 时间生成 firstSessionDate，避免本地时间却带 Z 的语义错误
        $firstSessionDateValue = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $macAddress = "00:11:22:33:44:55"
    }

    if ($useConfigIds) {
        Write-Host "$GREEN🔑 [准备]$NC 已使用配置中的设备标识符"
    } else {
        Write-Host "$GREEN🔑 [生成]$NC 已生成新的设备标识符"
    }
    Write-Host "   machineId: $($machineId.Substring(0,16))..."
    Write-Host "   machineGuid: $($machineGuid.Substring(0,16))..."
    Write-Host "   deviceId: $($deviceId.Substring(0,16))..."
    Write-Host "   macMachineId: $($macMachineId.Substring(0,16))..."
    Write-Host "   sqmId: $sqmId"

    # 保存 ID 配置到用户目录（供 Hook 读取）
    # 每次执行都删除旧配置并重新生成，确保获得新的设备标识符
    $idsConfigPath = "$env:USERPROFILE\.cursor_ids.json"
    if (Test-Path $idsConfigPath) {
        Remove-Item -Path $idsConfigPath -Force
        Write-Host "$YELLOW🗑️  [清理]$NC 已删除旧的 ID 配置文件"
    }
    $idsConfig = @{
        machineId = $machineId
        machineGuid = $machineGuid
        macMachineId = $macMachineId
        devDeviceId = $deviceId
        sqmId = $sqmId
        macAddress = $macAddress
        sessionId = $sessionId
        firstSessionDate = $firstSessionDateValue
        createdAt = $firstSessionDateValue
    }
    $idsConfig | ConvertTo-Json | Set-Content -Path $idsConfigPath -Encoding UTF8
    Write-Host "$GREEN💾 [保存]$NC 新的 ID 配置已保存到: $idsConfigPath"

    # 部署外置 Hook 文件（供 Loader Stub 加载，支持多域名备用下载）
    $hookTargetPath = "$env:USERPROFILE\.cursor_hook.js"
    # 兼容：通过 `irm ... | iex` 执行时 $PSScriptRoot 可能为空，Join-Path 会直接报错
    $hookSourceCandidates = @()
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $hookSourceCandidates += (Join-Path $PSScriptRoot "..\hook\cursor_hook.js")
    } elseif ($MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        if (-not [string]::IsNullOrWhiteSpace($scriptDir)) {
            $hookSourceCandidates += (Join-Path $scriptDir "..\hook\cursor_hook.js")
        }
    }
    $cwdPath = $null
    try { $cwdPath = (Get-Location).Path } catch { $cwdPath = $null }
    if (-not [string]::IsNullOrWhiteSpace($cwdPath)) {
        $hookSourceCandidates += (Join-Path $cwdPath "scripts\hook\cursor_hook.js")
    }
    $hookSourcePath = $hookSourceCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    $hookDownloadUrls = @(
        "https://wget.la/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/hook/cursor_hook.js",
        "https://down.npee.cn/?https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/hook/cursor_hook.js",
        "https://xget.xi-xu.me/gh/yuaotian/go-cursor-help/refs/heads/master/scripts/hook/cursor_hook.js",
        "https://gh-proxy.com/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/hook/cursor_hook.js",
        "https://gh.chjina.com/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/hook/cursor_hook.js"
    )
    # 支持通过环境变量覆盖下载节点（逗号分隔）
    if ($env:CURSOR_HOOK_DOWNLOAD_URLS) {
        $hookDownloadUrls = $env:CURSOR_HOOK_DOWNLOAD_URLS -split '\s*,\s*' | Where-Object { $_ }
        Write-Host "$BLUEℹ️  [Hook]$NC 检测到自定义下载节点列表，将优先使用"
    }
    if ($hookSourcePath) {
        try {
            Copy-Item -Path $hookSourcePath -Destination $hookTargetPath -Force
            Write-Host "$GREEN✅ [Hook]$NC 外置 Hook 已部署: $hookTargetPath"
        } catch {
            Write-Host "$YELLOW⚠️  [Hook]$NC 本地 Hook 复制失败，尝试在线下载..."
        }
    }
    if (-not (Test-Path $hookTargetPath)) {
        Write-Host "$BLUEℹ️  [Hook]$NC 正在下载外置 Hook，用于设备标识拦截..."
        $originalProgressPreference = $ProgressPreference
        $ProgressPreference = 'Continue'
        try {
            if ($hookDownloadUrls.Count -eq 0) {
                Write-Host "$YELLOW⚠️  [Hook]$NC 下载节点列表为空，跳过在线下载"
            } else {
                $totalUrls = $hookDownloadUrls.Count
                for ($i = 0; $i -lt $totalUrls; $i++) {
                    $url = $hookDownloadUrls[$i]
                    $attempt = $i + 1
                    Write-Host "$BLUE⏳ [Hook]$NC ($attempt/$totalUrls) 当前下载节点: $url"
                    try {
                        Invoke-WebRequest -Uri $url -OutFile $hookTargetPath -UseBasicParsing -ErrorAction Stop
                        Write-Host "$GREEN✅ [Hook]$NC 外置 Hook 已在线下载: $hookTargetPath"
                        break
                    } catch {
                        Write-Host "$YELLOW⚠️  [Hook]$NC 外置 Hook 下载失败: $url"
                        if (Test-Path $hookTargetPath) {
                            Remove-Item -Path $hookTargetPath -Force
                        }
                    }
                }
            }
        } finally {
            $ProgressPreference = $originalProgressPreference
        }
        if (-not (Test-Path $hookTargetPath)) {
            Write-Host "$YELLOW⚠️  [Hook]$NC 外置 Hook 全部下载失败"
        }
    }

    # 目标JS文件列表（Windows路径，按优先级排序）
    $jsFiles = @(
        "$cursorAppPath\resources\app\out\main.js",
        # 共享进程用于聚合 telemetry，需要同步注入
        "$cursorAppPath\resources\app\out\vs\code\electron-utility\sharedProcess\sharedProcessMain.js"
    )

    $modifiedCount = 0

    # 关闭Cursor进程
    Write-Host "$BLUE🔄 [关闭]$NC 关闭Cursor进程以进行文件修改..."
    Stop-AllCursorProcesses -MaxRetries 3 -WaitSeconds 3 | Out-Null

    # 创建备份目录
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$cursorAppPath\resources\app\out\backups"

    Write-Host "$BLUE💾 [备份]$NC 创建Cursor JS文件备份..."
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        # 检查是否存在原始备份
        $originalBackup = "$backupPath\main.js.original"

        foreach ($file in $jsFiles) {
            if (-not (Test-Path $file)) {
                Write-Host "$YELLOW⚠️  [警告]$NC 文件不存在: $(Split-Path $file -Leaf)"
                continue
            }

            $fileName = Split-Path $file -Leaf
            $fileOriginalBackup = "$backupPath\$fileName.original"

            # 如果原始备份不存在，先创建
            if (-not (Test-Path $fileOriginalBackup)) {
                # 检查当前文件是否已被修改过
                $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match "__cursor_patched__") {
                    Write-Host "$YELLOW⚠️  [警告]$NC 文件已被修改但无原始备份，将使用当前版本作为基础"
                }
                Copy-Item $file $fileOriginalBackup -Force
                Write-Host "$GREEN✅ [备份]$NC 原始备份创建成功: $fileName"
            } else {
                # 从原始备份恢复，确保每次都是干净的注入
                Write-Host "$BLUE🔄 [恢复]$NC 从原始备份恢复: $fileName"
                Copy-Item $fileOriginalBackup $file -Force
            }
        }

        # 创建时间戳备份（记录每次修改前的状态）
        foreach ($file in $jsFiles) {
            if (Test-Path $file) {
                $fileName = Split-Path $file -Leaf
                Copy-Item $file "$backupPath\$fileName.backup_$timestamp" -Force
            }
        }
        Write-Host "$GREEN✅ [备份]$NC 时间戳备份创建成功: $backupPath"
    } catch {
        Write-Host "$RED❌ [错误]$NC 创建备份失败: $($_.Exception.Message)"
        return $false
    }

    # 修改JS文件（每次都重新注入，因为已从原始备份恢复）
    Write-Host "$BLUE🔧 [修改]$NC 开始修改JS文件（使用设备标识符）..."

    foreach ($file in $jsFiles) {
        if (-not (Test-Path $file)) {
            Write-Host "$YELLOW⚠️  [跳过]$NC 文件不存在: $(Split-Path $file -Leaf)"
            continue
        }

        Write-Host "$BLUE📝 [处理]$NC 正在处理: $(Split-Path $file -Leaf)"

        try {
            $content = Get-Content $file -Raw -Encoding UTF8
            $replaced = $false
            $replacedB6 = $false

            # ========== 方法A: someValue占位符替换（稳定锚点） ==========
            # 这些字符串是固定的占位符，不会被混淆器修改，跨版本稳定
            # 重要说明：
            # 当前 Cursor 的 main.js 中占位符通常是以字符串字面量形式出现，例如：
            #   this.machineId="someValue.machineId"
            # 如果直接把 someValue.machineId 替换成 "\"<真实值>\""，会形成 ""<真实值>"" 导致 JS 语法错误（Invalid token）。
            # 因此这里优先替换完整的字符串字面量（包含外层引号），并使用 JSON 字符串字面量确保转义安全。

            # 🔧 新增: firstSessionDate（重置首次会话日期）
            if (-not $firstSessionDateValue) {
                # 使用 UTC 时间生成 firstSessionDate，避免本地时间却带 Z 的语义错误
                $firstSessionDateValue = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }

            $placeholders = @(
                @{ Name = 'someValue.machineId';         Value = [string]$machineId },
                @{ Name = 'someValue.macMachineId';      Value = [string]$macMachineId },
                @{ Name = 'someValue.devDeviceId';       Value = [string]$deviceId },
                @{ Name = 'someValue.sqmId';             Value = [string]$sqmId },
                @{ Name = 'someValue.sessionId';         Value = [string]$sessionId },
                @{ Name = 'someValue.firstSessionDate';  Value = [string]$firstSessionDateValue }
            )

            foreach ($ph in $placeholders) {
                $name = $ph.Name
                $jsonValue = ($ph.Value | ConvertTo-Json -Compress)  # 生成带双引号的 JSON 字符串字面量

                $changed = $false

                # 优先替换带引号的占位符字面量，避免出现 ""abc"" 破坏语法
                $doubleLiteral = '"' + $name + '"'
                if ($content.Contains($doubleLiteral)) {
                    $content = $content.Replace($doubleLiteral, $jsonValue)
                    $changed = $true
                }
                $singleLiteral = "'" + $name + "'"
                if ($content.Contains($singleLiteral)) {
                    $content = $content.Replace($singleLiteral, $jsonValue)
                    $changed = $true
                }

                # 兜底：如果占位符以非字符串字面量形式出现，则替换为 JSON 字符串字面量（自带引号）
                if (-not $changed -and $content.Contains($name)) {
                    $content = $content.Replace($name, $jsonValue)
                    $changed = $true
                }

                if ($changed) {
                    Write-Host "   $GREEN✓$NC [方案A] 替换 $name"
                    $replaced = $true
                }
            }

            # ========== 方法B: b6 定点重写（机器码源函数，仅 main.js） ==========
            # 说明：b6(t) 是 machineId 的核心生成函数，t=true 返回原始值，t=false 返回哈希
            if ((Split-Path $file -Leaf) -eq "main.js") {
                # ✅ 1+3 融合：限定 out-build/vs/base/node/id.js 模块内做特征匹配 + 花括号配对定位函数边界
                # 目的：提升跨版本覆盖率，同时避免正则跨模块误吞导致 main.js 语法损坏。
                try {
                    $moduleMarker = "out-build/vs/base/node/id.js"
                    $markerIndex = $content.IndexOf($moduleMarker)
                    if ($markerIndex -lt 0) {
                        throw "未找到 id.js 模块标记"
                    }

                    $windowLen = [Math]::Min($content.Length - $markerIndex, 200000)
                    $windowText = $content.Substring($markerIndex, $windowLen)

                    $hashRegex = [regex]::new('createHash\(["'']sha256["'']\)')
                    $hashMatches = $hashRegex.Matches($windowText)
                    Write-Host "   $BLUEℹ️  $NC [方案B诊断] id.js偏移=$markerIndex | sha256 createHash 命中=$($hashMatches.Count)"
                    $patched = $false
                    $diagLines = @()
                    # 兼容：PowerShell 可展开字符串中 "$var:" 会被当作作用域/驱动器前缀解析，需用 "${var}" 明确变量边界
                    $candidateNo = 0

                    foreach ($hm in $hashMatches) {
                        $candidateNo++
                        $hashPos = $hm.Index
                        $funcStart = $windowText.LastIndexOf("async function", $hashPos)
                        if ($funcStart -lt 0) {
                            if ($candidateNo -le 3) { $diagLines += "候选#${candidateNo}: 未找到 async function 起点" }
                            continue
                        }

                        $openBrace = $windowText.IndexOf("{", $funcStart)
                        if ($openBrace -lt 0) {
                            if ($candidateNo -le 3) { $diagLines += "候选#${candidateNo}: 未找到函数起始花括号" }
                            continue
                        }

                        $endBrace = Find-JsMatchingBraceEnd -Text $windowText -OpenBraceIndex $openBrace -MaxScan 20000
                        if ($endBrace -lt 0) {
                            if ($candidateNo -le 3) { $diagLines += "候选#${candidateNo}: 花括号配对失败（扫描上限内未闭合）" }
                            continue
                        }

                        $funcText = $windowText.Substring($funcStart, $endBrace - $funcStart + 1)
                        if ($funcText.Length -gt 8000) {
                            if ($candidateNo -le 3) { $diagLines += "候选#${candidateNo}: 函数体过长 len=$($funcText.Length)，已跳过" }
                            continue
                        }

                        $sig = [regex]::Match($funcText, '^async function (\w+)\((\w+)\)')
                        if (-not $sig.Success) {
                            if ($candidateNo -le 3) { $diagLines += "候选#${candidateNo}: 未解析到函数签名（async function name(param)）" }
                            continue
                        }
                        $fn = $sig.Groups[1].Value
                        $param = $sig.Groups[2].Value

                        # 特征校验：sha256 + hex digest + return param ? raw : hash
                        $hasDigest = ($funcText -match '\.digest\(["'']hex["'']\)')
                        $hasReturn = ($funcText -match ('return\s+' + [regex]::Escape($param) + '\?\w+:\w+\}'))
                        if ($candidateNo -le 3) {
                            $diagLines += "候选#${candidateNo}: $fn($param) len=$($funcText.Length) digest=$hasDigest return=$hasReturn"
                        }
                        if (-not $hasDigest) { continue }
                        if (-not $hasReturn) { continue }

                        $replacement = "async function $fn($param){return $param?'$machineGuid':'$machineId';}"
                        $absStart = $markerIndex + $funcStart
                        $absEnd = $markerIndex + $endBrace
                        $content = $content.Substring(0, $absStart) + $replacement + $content.Substring($absEnd + 1)

                        Write-Host "   $BLUEℹ️  $NC [方案B诊断] 命中候选#${candidateNo}：$fn($param) len=$($funcText.Length)"
                        Write-Host "   $GREEN✓$NC [方案B] 已重写 $fn($param) 机器码源函数（融合版特征匹配）"
                        $replacedB6 = $true
                        $patched = $true
                        break
                    }

                    if (-not $patched) {
                        Write-Host "   $YELLOW⚠️  $NC [方案B] 未定位到机器码源函数特征，已跳过"
                        foreach ($d in ($diagLines | Select-Object -First 3)) {
                            Write-Host "      $BLUEℹ️  $NC [方案B诊断] $d"
                        }
                    }
                } catch {
                    Write-Host "   $YELLOW⚠️  $NC [方案B] 定位失败，已跳过：$($_.Exception.Message)"
                }
            }

            # ========== 方法C: Loader Stub 注入 ==========
            # 说明：主/共享进程仅注入加载器，具体 Hook 逻辑由外置 cursor_hook.js 维护

            $injectCode = @"
// ========== Cursor Hook Loader 开始 ==========
;(async function(){/*__cursor_patched__*/
'use strict';
if (globalThis.__cursor_hook_loaded__) return;
globalThis.__cursor_hook_loaded__ = true;

try {
    // 兼容 ESM/CJS：避免使用 import.meta（仅 ESM 支持），统一用动态 import 加载 Hook
    var fsMod = await import('fs');
    var pathMod = await import('path');
    var osMod = await import('os');
    var urlMod = await import('url');

    var fs = fsMod && (fsMod.default || fsMod);
    var path = pathMod && (pathMod.default || pathMod);
    var os = osMod && (osMod.default || osMod);
    var url = urlMod && (urlMod.default || urlMod);

    if (fs && path && os && url && typeof url.pathToFileURL === 'function') {
        var hookPath = path.join(os.homedir(), '.cursor_hook.js');
        if (typeof fs.existsSync === 'function' && fs.existsSync(hookPath)) {
            await import(url.pathToFileURL(hookPath).href);
        }
    }
} catch (e) {
    // 失败静默，避免影响启动
}
})();
// ========== Cursor Hook Loader 结束 ==========

"@

            # 找到版权声明结束位置并在其后注入（仅注入一次，避免多次插入破坏语法）
            if ($content -match "__cursor_patched__") {
                Write-Host "   $YELLOW⚠️  $NC [方案C] 已检测到既有注入标记，跳过重复注入"
            } elseif ($content -match '(\*/\s*\n)') {
                $replacement = '$1' + $injectCode
                $content = [regex]::Replace($content, '(\*/\s*\n)', $replacement, 1)
                Write-Host "   $GREEN✓$NC [方案C] Loader Stub 已注入（版权声明后，仅首次）"
            } else {
                # 如果没有找到版权声明，则注入到文件开头
                $content = $injectCode + $content
                Write-Host "   $GREEN✓$NC [方案C] Loader Stub 已注入（文件开头）"
            }

            # 注入一致性校验：避免重复注入导致语法损坏
            $patchedCount = ([regex]::Matches($content, "__cursor_patched__")).Count
            if ($patchedCount -gt 1) {
                throw "检测到重复注入标记：$patchedCount"
            }

            # 写入修改后的内容
            Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline

            # 汇总本次注入实际生效的方案组合
            $summaryParts = @()
            if ($replaced) { $summaryParts += "someValue替换" }
            if ($replacedB6) { $summaryParts += "b6定点重写" }
            $summaryParts += "Hook加载器"
            $summaryText = ($summaryParts -join " + ")
            Write-Host "$GREEN✅ [成功]$NC 增强版方案修改成功（$summaryText）"
            $modifiedCount++

        } catch {
            Write-Host "$RED❌ [错误]$NC 修改文件失败: $($_.Exception.Message)"
            # 尝试从备份恢复
            $fileName = Split-Path $file -Leaf
            $backupFile = "$backupPath\$fileName.original"
            if (Test-Path $backupFile) {
                Copy-Item $backupFile $file -Force
                Write-Host "$YELLOW🔄 [恢复]$NC 已从备份恢复文件"
            }
        }
    }

    if ($modifiedCount -gt 0) {
        Write-Host ""
        Write-Host "$GREEN🎉 [完成]$NC 成功修改 $modifiedCount 个JS文件"
        Write-Host "$BLUE💾 [备份]$NC 原始文件备份位置: $backupPath"
        Write-Host "$BLUE💡 [说明]$NC 使用增强版三重方案："
        Write-Host "   • 方案A: someValue占位符替换（稳定锚点，跨版本兼容）"
        Write-Host "   • 方案B: b6 定点重写（机器码源函数）"
        Write-Host "   • 方案C: Loader Stub + 外置 Hook（cursor_hook.js）"
        Write-Host "$BLUE📁 [配置]$NC ID 配置文件: $idsConfigPath"
        return $true
    } else {
        Write-Host "$RED❌ [失败]$NC 没有成功修改任何文件"
        return $false
    }
}


# 🚀 新增 Cursor 防掉试用Pro删除文件夹功能
function Remove-CursorTrialFolders {
    Write-Host ""
    Write-Host "$GREEN🎯 [核心功能]$NC 正在执行 Cursor 防掉试用Pro删除文件夹..."
    Write-Host "$BLUE📋 [说明]$NC 此功能将删除指定的Cursor相关文件夹以重置试用状态"
    Write-Host ""

    # 定义需要删除的文件夹路径
    $foldersToDelete = @()

    # Windows Administrator 用户路径
    $adminPaths = @(
        "C:\Users\Administrator\.cursor",
        "C:\Users\Administrator\AppData\Roaming\Cursor"
    )

    # 当前用户路径（使用解析后的用户目录和 AppData）
    $currentUserPaths = @()
    $userProfileRoot = if ($global:CursorUserProfileRoot) { $global:CursorUserProfileRoot } else { [Environment]::GetEnvironmentVariable("USERPROFILE") }
    if ($userProfileRoot) {
        $currentUserPaths += (Join-Path $userProfileRoot ".cursor")
    }
    if ($global:CursorAppDataDir) {
        $currentUserPaths += $global:CursorAppDataDir
    }

    # 合并所有路径
    $foldersToDelete += $adminPaths
    $foldersToDelete += $currentUserPaths

    Write-Host "$BLUE📂 [检测]$NC 将检查以下文件夹："
    foreach ($folder in $foldersToDelete) {
        Write-Host "   📁 $folder"
    }
    Write-Host ""

    $deletedCount = 0
    $skippedCount = 0
    $errorCount = 0

    # 删除指定文件夹
    foreach ($folder in $foldersToDelete) {
        Write-Host "$BLUE🔍 [检查]$NC 检查文件夹: $folder"

        if (Test-Path $folder) {
            try {
                Write-Host "$YELLOW⚠️  [警告]$NC 发现文件夹存在，正在删除..."
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Host "$GREEN✅ [成功]$NC 已删除文件夹: $folder"
                $deletedCount++
            }
            catch {
                Write-Host "$RED❌ [错误]$NC 删除文件夹失败: $folder"
                Write-Host "$RED💥 [详情]$NC 错误信息: $($_.Exception.Message)"
                $errorCount++
            }
        } else {
            Write-Host "$YELLOW⏭️  [跳过]$NC 文件夹不存在: $folder"
            $skippedCount++
        }
        Write-Host ""
    }

    # 显示操作统计
    Write-Host "$GREEN📊 [统计]$NC 操作完成统计："
    Write-Host "   ✅ 成功删除: $deletedCount 个文件夹"
    Write-Host "   ⏭️  跳过处理: $skippedCount 个文件夹"
    Write-Host "   ❌ 删除失败: $errorCount 个文件夹"
    Write-Host ""

    if ($deletedCount -gt 0) {
        Write-Host "$GREEN🎉 [完成]$NC Cursor 防掉试用Pro文件夹删除完成！"

        # 🔧 预创建必要的目录结构，避免权限问题
        Write-Host "$BLUE🔧 [修复]$NC 预创建必要的目录结构以避免权限问题..."

        $cursorAppData = $global:CursorAppDataDir
        $cursorLocalAppData = $global:CursorLocalAppDataDir
        $cursorUserProfile = if ($userProfileRoot) { Join-Path $userProfileRoot ".cursor" } else { "$env:USERPROFILE\.cursor" }

        # 创建主要目录
        try {
            if ($cursorAppData -and -not (Test-Path $cursorAppData)) {
                New-Item -ItemType Directory -Path $cursorAppData -Force | Out-Null
            }
            if ($cursorUserProfile -and -not (Test-Path $cursorUserProfile)) {
                New-Item -ItemType Directory -Path $cursorUserProfile -Force | Out-Null
            }
            Write-Host "$GREEN✅ [完成]$NC 目录结构预创建完成"
        } catch {
            Write-Host "$YELLOW⚠️  [警告]$NC 预创建目录时出现问题: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW🤔 [提示]$NC 未找到需要删除的文件夹，可能已经清理过了"
    }
    Write-Host ""
}

# 🔄 重启Cursor并等待配置文件生成
function Restart-CursorAndWait {
    Write-Host ""
    Write-Host "$GREEN🔄 [重启]$NC 正在重启Cursor以重新生成配置文件..."

    if (-not $global:CursorProcessInfo) {
        Write-Host "$RED❌ [错误]$NC 未找到Cursor进程信息，无法重启"
        return $false
    }

    $cursorPath = $global:CursorProcessInfo.Path

    # 修复：确保路径是字符串类型
    if ($cursorPath -is [array]) {
        $cursorPath = $cursorPath[0]
    }

    # 验证路径不为空
    if ([string]::IsNullOrEmpty($cursorPath)) {
        Write-Host "$RED❌ [错误]$NC Cursor路径为空"
        return $false
    }

    Write-Host "$BLUE📍 [路径]$NC 使用路径: $cursorPath"

    if (-not (Test-Path $cursorPath)) {
        Write-Host "$RED❌ [错误]$NC Cursor可执行文件不存在: $cursorPath"

        # 尝试重新解析安装路径
        $installPath = Resolve-CursorInstallPath -AllowPrompt
        $foundPath = if ($installPath) { Join-Path $installPath "Cursor.exe" } else { $null }
        if ($foundPath -and (Test-Path $foundPath)) {
            Write-Host "$GREEN💡 [发现]$NC 使用备用路径: $foundPath"
        } else {
            $foundPath = $null
        }

        if (-not $foundPath) {
            Write-Host "$RED❌ [错误]$NC 无法找到有效的Cursor可执行文件"
            return $false
        }

        $cursorPath = $foundPath
    }

    try {
        Write-Host "$GREEN🚀 [启动]$NC 正在启动Cursor..."
        $process = Start-Process -FilePath $cursorPath -PassThru -WindowStyle Hidden

        Write-Host "$YELLOW⏳ [等待]$NC 等待20秒让Cursor完全启动并生成配置文件..."
        Start-Sleep -Seconds 20

        # 检查配置文件是否生成
        $configPath = $STORAGE_FILE
        if (-not $configPath) {
            Write-Host "$RED❌ [错误]$NC 无法解析配置文件路径"
            return $false
        }
        $maxWait = 45
        $waited = 0

        while (-not (Test-Path $configPath) -and $waited -lt $maxWait) {
            Write-Host "$YELLOW⏳ [等待]$NC 等待配置文件生成... ($waited/$maxWait 秒)"
            Start-Sleep -Seconds 1
            $waited++
        }

        if (Test-Path $configPath) {
            Write-Host "$GREEN✅ [成功]$NC 配置文件已生成: $configPath"

            # 额外等待确保文件完全写入
            Write-Host "$YELLOW⏳ [等待]$NC 等待5秒确保配置文件完全写入..."
            Start-Sleep -Seconds 5
        } else {
            Write-Host "$YELLOW⚠️  [警告]$NC 配置文件未在预期时间内生成"
            Write-Host "$BLUE💡 [提示]$NC 可能需要手动启动Cursor一次来生成配置文件"
        }

        # 强制关闭Cursor
        Write-Host "$YELLOW🔄 [关闭]$NC 正在关闭Cursor以进行配置修改..."
        if ($process -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit(5000)
        }

        # 确保所有Cursor进程都关闭
        Get-Process -Name "Cursor" -ErrorAction SilentlyContinue | Stop-Process -Force
        Get-Process -Name "cursor" -ErrorAction SilentlyContinue | Stop-Process -Force

        Write-Host "$GREEN✅ [完成]$NC Cursor重启流程完成"
        return $true

    } catch {
        Write-Host "$RED❌ [错误]$NC 重启Cursor失败: $($_.Exception.Message)"
        Write-Host "$BLUE💡 [调试]$NC 错误详情: $($_.Exception.GetType().FullName)"
        return $false
    }
}

# 🔒 强制关闭所有Cursor进程（增强版）
function Stop-AllCursorProcesses {
    param(
        [int]$MaxRetries = 3,
        [int]$WaitSeconds = 5
    )

    Write-Host "$BLUE🔒 [进程检查]$NC 正在检查并关闭所有Cursor相关进程..."

    # 定义所有可能的Cursor进程名称
    $cursorProcessNames = @(
        "Cursor",
        "cursor",
        "Cursor Helper",
        "Cursor Helper (GPU)",
        "Cursor Helper (Plugin)",
        "Cursor Helper (Renderer)",
        "CursorUpdater"
    )

    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        Write-Host "$BLUE🔍 [检查]$NC 第 $retry/$MaxRetries 次进程检查..."

        $foundProcesses = @()
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                $foundProcesses += $processes
                Write-Host "$YELLOW⚠️  [发现]$NC 进程: $processName (PID: $($processes.Id -join ', '))"
            }
        }

        if ($foundProcesses.Count -eq 0) {
            Write-Host "$GREEN✅ [成功]$NC 所有Cursor进程已关闭"
            return $true
        }

        Write-Host "$YELLOW🔄 [关闭]$NC 正在关闭 $($foundProcesses.Count) 个Cursor进程..."

        # 先尝试优雅关闭
        foreach ($process in $foundProcesses) {
            try {
                $process.CloseMainWindow() | Out-Null
                Write-Host "$BLUE  • 优雅关闭: $($process.ProcessName) (PID: $($process.Id))$NC"
            } catch {
                Write-Host "$YELLOW  • 优雅关闭失败: $($process.ProcessName)$NC"
            }
        }

        Start-Sleep -Seconds 3

        # 强制终止仍在运行的进程
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                foreach ($process in $processes) {
                    try {
                        Stop-Process -Id $process.Id -Force
                        Write-Host "$RED  • 强制终止: $($process.ProcessName) (PID: $($process.Id))$NC"
                    } catch {
                        Write-Host "$RED  • 强制终止失败: $($process.ProcessName)$NC"
                    }
                }
            }
        }

        if ($retry -lt $MaxRetries) {
            Write-Host "$YELLOW⏳ [等待]$NC 等待 $WaitSeconds 秒后重新检查..."
            Start-Sleep -Seconds $WaitSeconds
        }
    }

    Write-Host "$RED❌ [失败]$NC 经过 $MaxRetries 次尝试仍有Cursor进程在运行"
    return $false
}

# 🔐 检查文件权限和锁定状态
function Test-FileAccessibility {
    param(
        [string]$FilePath
    )

    Write-Host "$BLUE🔐 [权限检查]$NC 检查文件访问权限: $(Split-Path $FilePath -Leaf)"

    if (-not (Test-Path $FilePath)) {
        Write-Host "$RED❌ [错误]$NC 文件不存在"
        return $false
    }

    # 检查文件是否被锁定
    try {
        $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
        $fileStream.Close()
        Write-Host "$GREEN✅ [权限]$NC 文件可读写，无锁定"
        return $true
    } catch [System.IO.IOException] {
        Write-Host "$RED❌ [锁定]$NC 文件被其他进程锁定: $($_.Exception.Message)"
        return $false
    } catch [System.UnauthorizedAccessException] {
        Write-Host "$YELLOW⚠️  [权限]$NC 文件权限受限，尝试修改权限..."

        # 尝试修改文件权限
        try {
            $file = Get-Item $FilePath
            if ($file.IsReadOnly) {
                $file.IsReadOnly = $false
                Write-Host "$GREEN✅ [修复]$NC 已移除只读属性"
            }

            # 再次测试
            $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
            $fileStream.Close()
            Write-Host "$GREEN✅ [权限]$NC 权限修复成功"
            return $true
        } catch {
            Write-Host "$RED❌ [权限]$NC 无法修复权限: $($_.Exception.Message)"
            return $false
        }
    } catch {
        Write-Host "$RED❌ [错误]$NC 未知错误: $($_.Exception.Message)"
        return $false
    }
}

# 🧹 Cursor 初始化清理功能（从旧版本移植）
function Invoke-CursorInitialization {
    Write-Host ""
    Write-Host "$GREEN🧹 [初始化]$NC 正在执行 Cursor 初始化清理..."
    $BASE_PATH = if ($global:CursorAppDataDir) { Join-Path $global:CursorAppDataDir "User" } else { $null }
    if (-not $BASE_PATH) {
        Write-Host "$RED❌ [错误]$NC 无法解析 Cursor 用户目录，初始化清理终止"
        return
    }

    $filesToDelete = @(
        (Join-Path -Path $BASE_PATH -ChildPath "globalStorage\state.vscdb"),
        (Join-Path -Path $BASE_PATH -ChildPath "globalStorage\state.vscdb.backup")
    )

    $folderToCleanContents = Join-Path -Path $BASE_PATH -ChildPath "History"
    $folderToDeleteCompletely = Join-Path -Path $BASE_PATH -ChildPath "workspaceStorage"

    Write-Host "$BLUE🔍 [调试]$NC 基础路径: $BASE_PATH"

    # 删除指定文件
    foreach ($file in $filesToDelete) {
        Write-Host "$BLUE🔍 [检查]$NC 检查文件: $file"
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Host "$GREEN✅ [成功]$NC 已删除文件: $file"
            }
            catch {
                Write-Host "$RED❌ [错误]$NC 删除文件 $file 失败: $($_.Exception.Message)"
            }
        } else {
            Write-Host "$YELLOW⚠️  [跳过]$NC 文件不存在，跳过删除: $file"
        }
    }

    # 清空指定文件夹内容
    Write-Host "$BLUE🔍 [检查]$NC 检查待清空文件夹: $folderToCleanContents"
    if (Test-Path $folderToCleanContents) {
        try {
            Get-ChildItem -Path $folderToCleanContents -Recurse | Remove-Item -Force -Recurse -ErrorAction Stop
            Write-Host "$GREEN✅ [成功]$NC 已清空文件夹内容: $folderToCleanContents"
        }
        catch {
            Write-Host "$RED❌ [错误]$NC 清空文件夹 $folderToCleanContents 失败: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW⚠️  [跳过]$NC 文件夹不存在，跳过清空: $folderToCleanContents"
    }

    # 完全删除指定文件夹
    Write-Host "$BLUE🔍 [检查]$NC 检查待删除文件夹: $folderToDeleteCompletely"
    if (Test-Path $folderToDeleteCompletely) {
        try {
            Remove-Item -Path $folderToDeleteCompletely -Recurse -Force -ErrorAction Stop
            Write-Host "$GREEN✅ [成功]$NC 已删除文件夹: $folderToDeleteCompletely"
        }
        catch {
            Write-Host "$RED❌ [错误]$NC 删除文件夹 $folderToDeleteCompletely 失败: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW⚠️  [跳过]$NC 文件夹不存在，跳过删除: $folderToDeleteCompletely"
    }

    Write-Host "$GREEN✅ [完成]$NC Cursor 初始化清理完成"
    Write-Host ""
}

# 🔧 修改系统注册表 MachineGuid（从旧版本移植）
function Update-MachineGuid {
    try {
        Write-Host "$BLUE🔧 [注册表]$NC 正在修改系统注册表 MachineGuid..."

        # 检查注册表路径是否存在，不存在则创建
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            Write-Host "$YELLOW⚠️  [警告]$NC 注册表路径不存在: $registryPath，正在创建..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "$GREEN✅ [信息]$NC 注册表路径创建成功"
        }

        # 获取当前的 MachineGuid，如果不存在则使用空字符串作为默认值
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Host "$GREEN✅ [信息]$NC 当前注册表值："
                Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
                Write-Host "    MachineGuid    REG_SZ    $originalGuid"
            } else {
                Write-Host "$YELLOW⚠️  [警告]$NC MachineGuid 值不存在，将创建新值"
            }
        } catch {
            Write-Host "$YELLOW⚠️  [警告]$NC 读取注册表失败: $($_.Exception.Message)"
            Write-Host "$YELLOW⚠️  [警告]$NC 将尝试创建新的 MachineGuid 值"
        }

        # 创建备份文件（仅当原始值存在时）
        $backupFile = $null
        if ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            Write-Host "$BLUE💾 [备份]$NC 正在备份注册表..."
            $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru

            if ($backupResult.ExitCode -eq 0) {
                Write-Host "$GREEN✅ [备份]$NC 注册表项已备份到：$backupFile"
            } else {
                Write-Host "$YELLOW⚠️  [警告]$NC 备份创建失败，继续执行..."
                $backupFile = $null
            }
        }

        # 生成新GUID
        $newGuid = [System.Guid]::NewGuid().ToString()
        Write-Host "$BLUE🔄 [生成]$NC 新的 MachineGuid: $newGuid"

        # 更新或创建注册表值
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop

        # 验证更新
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "注册表验证失败：更新后的值 ($verifyGuid) 与预期值 ($newGuid) 不匹配"
        }

        Write-Host "$GREEN✅ [成功]$NC 注册表更新成功："
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED❌ [错误]$NC 注册表操作失败：$($_.Exception.Message)"

        # 尝试恢复备份（如果存在）
        if ($backupFile -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW🔄 [恢复]$NC 正在从备份恢复..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru

            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN✅ [恢复成功]$NC 已还原原始注册表值"
            } else {
                Write-Host "$RED❌ [错误]$NC 恢复失败，请手动导入备份文件：$backupFile"
            }
        } else {
            Write-Host "$YELLOW⚠️  [警告]$NC 未找到备份文件或备份创建失败，无法自动恢复"
        }

        return $false
    }
}

# 🚫 禁用 Cursor 自动更新（Windows）
function Disable-CursorAutoUpdate {
    Write-Host ""
    Write-Host "$BLUE🚫 [禁用更新]$NC 正在尝试禁用 Cursor 自动更新..."

    # 检测 Cursor 安装路径（支持自动检测 + 手动兜底）
    $cursorAppPath = Resolve-CursorInstallPath -AllowPrompt
    if (-not $cursorAppPath) {
        Write-Host "$YELLOW⚠️  [警告]$NC 未找到 Cursor 安装路径，跳过禁用更新"
        return $false
    }

    # 更新配置文件（JSON/YAML）
    # 兼容修复：PowerShell 不支持把 (if ... ) 当作表达式写进数组里，会报 “if 不是 cmdlet”
    $updateFiles = @()
    $updateFiles += "$cursorAppPath\resources\app-update.yml"
    $updateFiles += "$cursorAppPath\resources\app\update-config.json"
    if ($global:CursorAppDataDir) {
        $updateFiles += (Join-Path $global:CursorAppDataDir "update-config.json")
        $updateFiles += (Join-Path $global:CursorAppDataDir "settings.json")
    }
    $updateFiles = $updateFiles | Where-Object { $_ }

    foreach ($file in $updateFiles) {
        if (-not (Test-Path $file)) { continue }

        try {
            Copy-Item $file "$file.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
        } catch {
            Write-Host "$YELLOW⚠️  [警告]$NC 备份失败: $file"
        }

        if ($file -like "*.yml") {
            Set-Content -Path $file -Value "# update disabled by script $(Get-Date)" -Encoding UTF8
            Write-Host "$GREEN✅ [完成]$NC 已处理更新配置: $file"
            continue
        }

        if ($file -like "*update-config.json") {
            $config = @{ autoCheck = $false; autoDownload = $false }
            $config | ConvertTo-Json -Depth 5 | Set-Content -Path $file -Encoding UTF8
            Write-Host "$GREEN✅ [完成]$NC 已处理更新配置: $file"
            continue
        }

        if ($file -like "*settings.json") {
            try {
                $settings = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            } catch {
                $settings = @{}
            }
            if ($settings -is [hashtable]) {
                $settings["update.mode"] = "none"
            } else {
                $settings | Add-Member -MemberType NoteProperty -Name "update.mode" -Value "none" -Force
            }
            $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
            Write-Host "$GREEN✅ [完成]$NC 已处理更新配置: $file"
            continue
        }
    }

    # 尝试禁用更新器可执行文件
    $updaterCandidates = @()
    $updaterCandidates += "$cursorAppPath\Update.exe"
    if ($global:CursorLocalAppDataDir) {
        $updaterCandidates += (Join-Path $global:CursorLocalAppDataDir "Update.exe")
    }
    $updaterCandidates += "$cursorAppPath\CursorUpdater.exe"
    $updaterCandidates = $updaterCandidates | Where-Object { $_ }

    foreach ($updater in $updaterCandidates) {
        if (-not (Test-Path $updater)) { continue }
        $backup = "$updater.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        try {
            Move-Item -Path $updater -Destination $backup -Force
            Write-Host "$GREEN✅ [完成]$NC 已禁用更新器: $updater"
        } catch {
            Write-Host "$YELLOW⚠️  [警告]$NC 更新器禁用失败: $updater"
        }
    }

    return $true
}

# 检查配置文件和环境
function Test-CursorEnvironment {
    param(
        [string]$Mode = "FULL"
    )

    Write-Host ""
    Write-Host "$BLUE🔍 [环境检查]$NC 正在检查Cursor环境..."

    $configPath = $STORAGE_FILE
    $cursorAppData = $global:CursorAppDataDir
    $issues = @()

    # 检查配置文件
    if (-not $configPath) {
        $issues += "无法解析配置文件路径"
    } elseif (-not (Test-Path $configPath)) {
        $issues += "配置文件不存在: $configPath"
    } else {
        try {
            $content = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
            $config = $content | ConvertFrom-Json -ErrorAction Stop
            Write-Host "$GREEN✅ [检查]$NC 配置文件格式正确"
        } catch {
            $issues += "配置文件格式错误: $($_.Exception.Message)"
        }
    }

    # 检查Cursor目录结构
    if (-not $cursorAppData -or -not (Test-Path $cursorAppData)) {
        $issues += "Cursor应用数据目录不存在: $cursorAppData"
    }

    # 检查Cursor安装
    $cursorPaths = @()
    $installPath = Resolve-CursorInstallPath
    if ($installPath) {
        $cursorPaths = @(Join-Path $installPath "Cursor.exe")
    }

    $cursorFound = $false
    foreach ($path in $cursorPaths) {
        if (Test-Path $path) {
            Write-Host "$GREEN✅ [检查]$NC 找到Cursor安装: $path"
            $cursorFound = $true
            break
        }
    }

    if (-not $cursorFound) {
        $issues += "未找到Cursor安装，请确认Cursor已正确安装"
    }

    # 返回检查结果
    if ($issues.Count -eq 0) {
        Write-Host "$GREEN✅ [环境检查]$NC 所有检查通过"
        return @{ Success = $true; Issues = @() }
    } else {
        Write-Host "$RED❌ [环境检查]$NC 发现 $($issues.Count) 个问题："
        foreach ($issue in $issues) {
            Write-Host "$RED  • ${issue}$NC"
        }
        return @{ Success = $false; Issues = $issues }
    }
}

# �🛠️ 修改机器码配置（增强版）
function Modify-MachineCodeConfig {
    param(
        [string]$Mode = "FULL"
    )

    Write-Host ""
    Write-Host "$GREEN🛠️  [配置]$NC 正在修改机器码配置..."

    $configPath = $STORAGE_FILE
    if (-not $configPath) {
        Write-Host "$RED❌ [错误]$NC 无法解析配置文件路径"
        return $false
    }

    # 增强的配置文件检查
    if (-not (Test-Path $configPath)) {
        Write-Host "$RED❌ [错误]$NC 配置文件不存在: $configPath"
        Write-Host ""
        Write-Host "$YELLOW💡 [解决方案]$NC 请尝试以下步骤："
        Write-Host "$BLUE  1️⃣  手动启动Cursor应用程序$NC"
        Write-Host "$BLUE  2️⃣  等待Cursor完全加载（约30秒）$NC"
        Write-Host "$BLUE  3️⃣  关闭Cursor应用程序$NC"
        Write-Host "$BLUE  4️⃣  重新运行此脚本$NC"
        Write-Host ""
        Write-Host "$YELLOW⚠️  [备选方案]$NC 如果问题持续："
        Write-Host "$BLUE  • 选择脚本的'重置环境+修改机器码'选项$NC"
        Write-Host "$BLUE  • 该选项会自动生成配置文件$NC"
        Write-Host ""

        # 提供用户选择
        $userChoice = Read-Host "是否现在尝试启动Cursor生成配置文件？(y/n)"
        if ($userChoice -match "^(y|yes)$") {
            Write-Host "$BLUE🚀 [尝试]$NC 正在尝试启动Cursor..."
            return Start-CursorToGenerateConfig
        }

        return $false
    }

    # 在仅修改机器码模式下也要确保进程完全关闭
    if ($Mode -eq "MODIFY_ONLY") {
        Write-Host "$BLUE🔒 [安全检查]$NC 即使在仅修改模式下，也需要确保Cursor进程完全关闭"
        if (-not (Stop-AllCursorProcesses -MaxRetries 3 -WaitSeconds 3)) {
            Write-Host "$RED❌ [错误]$NC 无法关闭所有Cursor进程，修改可能失败"
            $userChoice = Read-Host "是否强制继续？(y/n)"
            if ($userChoice -notmatch "^(y|yes)$") {
                return $false
            }
        }
    }

    # 检查文件权限和锁定状态
    if (-not (Test-FileAccessibility -FilePath $configPath)) {
        Write-Host "$RED❌ [错误]$NC 无法访问配置文件，可能被锁定或权限不足"
        return $false
    }

    # 验证配置文件格式并显示结构
    try {
        Write-Host "$BLUE🔍 [验证]$NC 检查配置文件格式..."
        $originalContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
        $config = $originalContent | ConvertFrom-Json -ErrorAction Stop
        Write-Host "$GREEN✅ [验证]$NC 配置文件格式正确"

        # 显示当前配置文件中的相关属性
        Write-Host "$BLUE📋 [当前配置]$NC 检查现有的遥测属性："
        $telemetryProperties = @('telemetry.machineId', 'telemetry.macMachineId', 'telemetry.devDeviceId', 'telemetry.sqmId')
        foreach ($prop in $telemetryProperties) {
            if ($config.PSObject.Properties[$prop]) {
                $value = $config.$prop
                $displayValue = if ($value.Length -gt 20) { "$($value.Substring(0,20))..." } else { $value }
                Write-Host "$GREEN  ✓ ${prop}$NC = $displayValue"
            } else {
                Write-Host "$YELLOW  - ${prop}$NC (不存在，将创建)"
            }
        }
        Write-Host ""
    } catch {
        Write-Host "$RED❌ [错误]$NC 配置文件格式错误: $($_.Exception.Message)"
        Write-Host "$YELLOW💡 [建议]$NC 配置文件可能已损坏，建议选择'重置环境+修改机器码'选项"
        return $false
    }

    # 实现原子性文件操作和重试机制
    $maxRetries = 3
    $retryCount = 0

    while ($retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host ""
        Write-Host "$BLUE🔄 [尝试]$NC 第 $retryCount/$maxRetries 次修改尝试..."

        try {
            # 显示操作进度
            Write-Host "$BLUE⏳ [进度]$NC 1/6 - 生成新的设备标识符..."

            # 生成新的ID
            $MAC_MACHINE_ID = [System.Guid]::NewGuid().ToString()
            $UUID = [System.Guid]::NewGuid().ToString()
            $prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
            $prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
            $randomBytes = New-Object byte[] 32
            $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
            $rng.GetBytes($randomBytes)
            $randomPart = [System.BitConverter]::ToString($randomBytes) -replace '-',''
            $rng.Dispose()
            $MACHINE_ID = "${prefixHex}${randomPart}"
            $SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"
            # 🔧 新增: serviceMachineId (用于 storage.serviceMachineId)
            $SERVICE_MACHINE_ID = [System.Guid]::NewGuid().ToString()
            # 🔧 新增: firstSessionDate (重置首次会话日期，使用 UTC 时间避免本地时间却带 Z 的语义错误)
            $FIRST_SESSION_DATE = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $SESSION_ID = [System.Guid]::NewGuid().ToString()

            # 共享ID（用于配置与JS注入保持一致）
            $global:CursorIds = @{
                machineId        = $MACHINE_ID
                macMachineId     = $MAC_MACHINE_ID
                devDeviceId      = $UUID
                sqmId            = $SQM_ID
                firstSessionDate = $FIRST_SESSION_DATE
                sessionId        = $SESSION_ID
                macAddress       = "00:11:22:33:44:55"
            }

            Write-Host "$GREEN✅ [进度]$NC 1/7 - 设备标识符生成完成"

            Write-Host "$BLUE⏳ [进度]$NC 2/7 - 创建备份目录..."

            # 备份原始值（增强版）
            $backupDir = $BACKUP_DIR
            if (-not $backupDir) {
                throw "无法解析备份目录路径"
            }
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction Stop | Out-Null
            }

            $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')_retry$retryCount"
            $backupPath = "$backupDir\$backupName"

            Write-Host "$BLUE⏳ [进度]$NC 3/7 - 备份原始配置..."
            Copy-Item $configPath $backupPath -ErrorAction Stop

            # 验证备份是否成功
            if (Test-Path $backupPath) {
                $backupSize = (Get-Item $backupPath).Length
                $originalSize = (Get-Item $configPath).Length
                if ($backupSize -eq $originalSize) {
                    Write-Host "$GREEN✅ [进度]$NC 3/7 - 配置备份成功: $backupName"
                } else {
                    Write-Host "$YELLOW⚠️  [警告]$NC 备份文件大小不匹配，但继续执行"
                }
            } else {
                throw "备份文件创建失败"
            }

            Write-Host "$BLUE⏳ [进度]$NC 4/7 - 读取原始配置到内存..."

            # 原子性操作：读取原始内容到内存
            $originalContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
            $config = $originalContent | ConvertFrom-Json -ErrorAction Stop

            Write-Host "$BLUE⏳ [进度]$NC 5/7 - 在内存中更新配置..."

            # 更新配置值（安全方式，确保属性存在）
            # 🔧 修复: 添加 storage.serviceMachineId 和 telemetry.firstSessionDate
            $propertiesToUpdate = @{
                'telemetry.machineId' = $MACHINE_ID
                'telemetry.macMachineId' = $MAC_MACHINE_ID
                'telemetry.devDeviceId' = $UUID
                'telemetry.sqmId' = $SQM_ID
                'storage.serviceMachineId' = $SERVICE_MACHINE_ID
                'telemetry.firstSessionDate' = $FIRST_SESSION_DATE
            }

            foreach ($property in $propertiesToUpdate.GetEnumerator()) {
                $key = $property.Key
                $value = $property.Value

                # 使用 Add-Member 或直接赋值的安全方式
                if ($config.PSObject.Properties[$key]) {
                    # 属性存在，直接更新
                    $config.$key = $value
                    Write-Host "$BLUE  ✓ 更新属性: ${key}$NC"
                } else {
                    # 属性不存在，添加新属性
                    $config | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
                    Write-Host "$BLUE  + 添加属性: ${key}$NC"
                }
            }

            Write-Host "$BLUE⏳ [进度]$NC 6/7 - 原子性写入新配置文件..."

            # 原子性操作：删除原文件，写入新文件
            $tempPath = "$configPath.tmp"
            $updatedJson = $config | ConvertTo-Json -Depth 10

            # 写入临时文件
            [System.IO.File]::WriteAllText($tempPath, $updatedJson, [System.Text.Encoding]::UTF8)

            # 验证临时文件
            $tempContent = Get-Content $tempPath -Raw -Encoding UTF8 -ErrorAction Stop
            $tempConfig = $tempContent | ConvertFrom-Json -ErrorAction Stop

            # 🔧 关键修复：PowerShell 的 ConvertFrom-Json 会把 ISO-8601 日期字符串自动解析为 DateTime
            # 为避免“期望值(字符串) vs 实际值(DateTime)”导致的误判，这里对比前做一次值归一化
            $toComparableString = {
                param([object]$v)
                if ($null -eq $v) { return $null }
                if ($v -is [DateTime]) { return $v.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") }
                if ($v -is [DateTimeOffset]) { return $v.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") }
                return [string]$v
            }

            # 验证所有属性是否正确写入
            $tempVerificationPassed = $true
            foreach ($property in $propertiesToUpdate.GetEnumerator()) {
                $key = $property.Key
                $expectedValue = $property.Value
                $actualValue = $tempConfig.$key

                $expectedComparable = & $toComparableString $expectedValue
                $actualComparable = & $toComparableString $actualValue

                if ($actualComparable -ne $expectedComparable) {
                    $tempVerificationPassed = $false
                    Write-Host "$RED  ✗ 临时文件验证失败: ${key}$NC"
                    $expectedType = if ($null -eq $expectedValue) { '<null>' } else { $expectedValue.GetType().FullName }
                    $actualType = if ($null -eq $actualValue) { '<null>' } else { $actualValue.GetType().FullName }
                    Write-Host "$YELLOW    [调试] 类型: 期望=${expectedType}; 实际=${actualType}$NC"
                    Write-Host "$YELLOW    [调试] 值(归一化): 期望=${expectedComparable}; 实际=${actualComparable}$NC"
                    break
                }
            }

            if (-not $tempVerificationPassed) {
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                throw "临时文件验证失败"
            }

            # 原子性替换：删除原文件，重命名临时文件
            Remove-Item $configPath -Force
            Move-Item $tempPath $configPath

            # 设置文件为只读（可选）
            $file = Get-Item $configPath
            $file.IsReadOnly = $false  # 保持可写，便于后续修改

            # 最终验证修改结果
            Write-Host "$BLUE⏳ [进度]$NC 7/7 - 验证新配置文件..."

            $verifyContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
            $verifyConfig = $verifyContent | ConvertFrom-Json -ErrorAction Stop

            $verificationPassed = $true
            $verificationResults = @()

            # 安全验证每个属性
            foreach ($property in $propertiesToUpdate.GetEnumerator()) {
                $key = $property.Key
                $expectedValue = $property.Value
                $actualValue = $verifyConfig.$key

                $expectedComparable = & $toComparableString $expectedValue
                $actualComparable = & $toComparableString $actualValue

                if ($actualComparable -eq $expectedComparable) {
                    $verificationResults += "✓ ${key}: 验证通过"
                } else {
                    $expectedType = if ($null -eq $expectedValue) { '<null>' } else { $expectedValue.GetType().FullName }
                    $actualType = if ($null -eq $actualValue) { '<null>' } else { $actualValue.GetType().FullName }
                    $verificationResults += "✗ ${key}: 验证失败 (期望类型: ${expectedType}, 实际类型: ${actualType}; 期望: ${expectedComparable}, 实际: ${actualComparable})"
                    $verificationPassed = $false
                }
            }

            # 显示验证结果
            Write-Host "$BLUE📋 [验证详情]$NC"
            foreach ($result in $verificationResults) {
                Write-Host "   $result"
            }

            if ($verificationPassed) {
                Write-Host "$GREEN✅ [成功]$NC 第 $retryCount 次尝试修改成功！"
                Write-Host ""
                Write-Host "$GREEN🎉 [完成]$NC 机器码配置修改完成！"
                Write-Host "$BLUE📋 [详情]$NC 已更新以下标识符："
                Write-Host "   🔹 machineId: $MACHINE_ID"
                Write-Host "   🔹 macMachineId: $MAC_MACHINE_ID"
                Write-Host "   🔹 devDeviceId: $UUID"
                Write-Host "   🔹 sqmId: $SQM_ID"
                Write-Host "   🔹 serviceMachineId: $SERVICE_MACHINE_ID"
                Write-Host "   🔹 firstSessionDate: $FIRST_SESSION_DATE"
                Write-Host ""
                Write-Host "$GREEN💾 [备份]$NC 原配置已备份至: $backupName"

                # 🔧 新增: 修改 machineid 文件
                Write-Host "$BLUE🔧 [machineid]$NC 正在修改 machineid 文件..."
                $machineIdFilePath = if ($global:CursorAppDataDir) { Join-Path $global:CursorAppDataDir "machineid" } else { $null }
                if (-not $machineIdFilePath) {
                    Write-Host "$YELLOW⚠️  [machineid]$NC 无法解析 machineid 文件路径，跳过修改"
                } else {
                    try {
                        if (Test-Path $machineIdFilePath) {
                            # 备份原始 machineid 文件
                            $machineIdBackup = "$backupDir\machineid.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                            Copy-Item $machineIdFilePath $machineIdBackup -Force
                            Write-Host "$GREEN💾 [备份]$NC machineid 文件已备份: $machineIdBackup"
                        }
                        # 写入新的 serviceMachineId 到 machineid 文件
                        [System.IO.File]::WriteAllText($machineIdFilePath, $SERVICE_MACHINE_ID, [System.Text.Encoding]::UTF8)
                        Write-Host "$GREEN✅ [machineid]$NC machineid 文件修改成功: $SERVICE_MACHINE_ID"

                        # 设置 machineid 文件为只读
                        $machineIdFile = Get-Item $machineIdFilePath
                        $machineIdFile.IsReadOnly = $true
                        Write-Host "$GREEN🔒 [保护]$NC machineid 文件已设置为只读"
                    } catch {
                        Write-Host "$YELLOW⚠️  [machineid]$NC machineid 文件修改失败: $($_.Exception.Message)"
                        Write-Host "$BLUE💡 [提示]$NC 可手动修改文件: $machineIdFilePath"
                    }
                }

                # 🔧 新增: 修改 .updaterId 文件（更新器设备标识符）
                Write-Host "$BLUE🔧 [updaterId]$NC 正在修改 .updaterId 文件..."
                $updaterIdFilePath = if ($global:CursorAppDataDir) { Join-Path $global:CursorAppDataDir ".updaterId" } else { $null }
                if (-not $updaterIdFilePath) {
                    Write-Host "$YELLOW⚠️  [updaterId]$NC 无法解析 .updaterId 文件路径，跳过修改"
                } else {
                    try {
                        if (Test-Path $updaterIdFilePath) {
                            # 备份原始 .updaterId 文件
                            $updaterIdBackup = "$backupDir\.updaterId.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                            Copy-Item $updaterIdFilePath $updaterIdBackup -Force
                            Write-Host "$GREEN💾 [备份]$NC .updaterId 文件已备份: $updaterIdBackup"
                        }
                        # 生成新的 updaterId（UUID格式）
                        $newUpdaterId = [System.Guid]::NewGuid().ToString()
                        [System.IO.File]::WriteAllText($updaterIdFilePath, $newUpdaterId, [System.Text.Encoding]::UTF8)
                        Write-Host "$GREEN✅ [updaterId]$NC .updaterId 文件修改成功: $newUpdaterId"

                        # 设置 .updaterId 文件为只读
                        $updaterIdFile = Get-Item $updaterIdFilePath
                        $updaterIdFile.IsReadOnly = $true
                        Write-Host "$GREEN🔒 [保护]$NC .updaterId 文件已设置为只读"
                    } catch {
                        Write-Host "$YELLOW⚠️  [updaterId]$NC .updaterId 文件修改失败: $($_.Exception.Message)"
                        Write-Host "$BLUE💡 [提示]$NC 可手动修改文件: $updaterIdFilePath"
                    }
                }

                # 🔒 添加配置文件保护机制
                Write-Host "$BLUE🔒 [保护]$NC 正在设置配置文件保护..."
                try {
                    $configFile = Get-Item $configPath
                    $configFile.IsReadOnly = $true
                    Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                    Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
                } catch {
                    Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                    Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
                }
                Write-Host "$BLUE 🔒 [安全]$NC 建议重启Cursor以确保配置生效"
                return $true
            } else {
                Write-Host "$RED❌ [失败]$NC 第 $retryCount 次尝试验证失败"
                if ($retryCount -lt $maxRetries) {
                    Write-Host "$BLUE🔄 [恢复]$NC 恢复备份，准备重试..."
                    Copy-Item $backupPath $configPath -Force
                    Start-Sleep -Seconds 2
                    continue  # 继续下一次重试
                } else {
                    Write-Host "$RED❌ [最终失败]$NC 所有重试都失败，恢复原始配置"
                    Copy-Item $backupPath $configPath -Force
                    return $false
                }
            }

        } catch {
            Write-Host "$RED❌ [异常]$NC 第 $retryCount 次尝试出现异常: $($_.Exception.Message)"
            Write-Host "$BLUE💡 [调试信息]$NC 错误类型: $($_.Exception.GetType().FullName)"

            # 清理临时文件
            if (Test-Path "$configPath.tmp") {
                Remove-Item "$configPath.tmp" -Force -ErrorAction SilentlyContinue
            }

            if ($retryCount -lt $maxRetries) {
                Write-Host "$BLUE🔄 [恢复]$NC 恢复备份，准备重试..."
                if (Test-Path $backupPath) {
                    Copy-Item $backupPath $configPath -Force
                }
                Start-Sleep -Seconds 3
                continue  # 继续下一次重试
            } else {
                Write-Host "$RED❌ [最终失败]$NC 所有重试都失败"
                # 尝试恢复备份
                if (Test-Path $backupPath) {
                    Write-Host "$BLUE🔄 [恢复]$NC 正在恢复备份配置..."
                    try {
                        Copy-Item $backupPath $configPath -Force
                        Write-Host "$GREEN✅ [恢复]$NC 已恢复原始配置"
                    } catch {
                        Write-Host "$RED❌ [错误]$NC 恢复备份失败: $($_.Exception.Message)"
                    }
                }
                return $false
            }
        }
    }

    # 如果到达这里，说明所有重试都失败了
    Write-Host "$RED❌ [最终失败]$NC 经过 $maxRetries 次尝试仍无法完成修改"
    return $false

}

#  启动Cursor生成配置文件
function Start-CursorToGenerateConfig {
    Write-Host "$BLUE🚀 [启动]$NC 正在尝试启动Cursor生成配置文件..."

    # 查找Cursor可执行文件（支持自动检测 + 手动兜底）
    $installPath = Resolve-CursorInstallPath -AllowPrompt
    $cursorPath = if ($installPath) { Join-Path $installPath "Cursor.exe" } else { $null }

    if (-not $cursorPath) {
        Write-Host "$RED❌ [错误]$NC 未找到Cursor安装，请确认Cursor已正确安装"
        return $false
    }

    try {
        Write-Host "$BLUE📍 [路径]$NC 使用Cursor路径: $cursorPath"

        # 启动Cursor
        $process = Start-Process -FilePath $cursorPath -PassThru -WindowStyle Normal
        Write-Host "$GREEN🚀 [启动]$NC Cursor已启动，PID: $($process.Id)"

        Write-Host "$YELLOW⏳ [等待]$NC 请等待Cursor完全加载（约30秒）..."
        Write-Host "$BLUE💡 [提示]$NC 您可以在Cursor完全加载后手动关闭它"

        # 等待配置文件生成
        $configPath = $STORAGE_FILE
        if (-not $configPath) {
            Write-Host "$RED❌ [错误]$NC 无法解析配置文件路径"
            return $false
        }
        $maxWait = 60
        $waited = 0

        while (-not (Test-Path $configPath) -and $waited -lt $maxWait) {
            Start-Sleep -Seconds 2
            $waited += 2
            if ($waited % 10 -eq 0) {
                Write-Host "$YELLOW⏳ [等待]$NC 等待配置文件生成... ($waited/$maxWait 秒)"
            }
        }

        if (Test-Path $configPath) {
            Write-Host "$GREEN✅ [成功]$NC 配置文件已生成！"
            Write-Host "$BLUE💡 [提示]$NC 现在可以关闭Cursor并重新运行脚本"
            return $true
        } else {
            Write-Host "$YELLOW⚠️  [超时]$NC 配置文件未在预期时间内生成"
            Write-Host "$BLUE💡 [建议]$NC 请手动操作Cursor（如创建新文件）以触发配置生成"
            return $false
        }

    } catch {
        Write-Host "$RED❌ [错误]$NC 启动Cursor失败: $($_.Exception.Message)"
        return $false
    }
}

# 检查管理员权限
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[错误]$NC 请以管理员身份运行此脚本"
    Write-Host "请右键点击脚本，选择'以管理员身份运行'"
    Read-Host "按回车键退出"
    exit 1
}

# 显示 Logo
Clear-Host
Write-Host @"

    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN🚀   Cursor 防掉试用Pro删除工具          $NC"
Write-Host "$YELLOW📱  关注公众号【煎饼果子卷AI】 $NC"
Write-Host "$YELLOW🤝  一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  $NC"
Write-Host "$YELLOW💡  [重要提示] 本工具免费，如果对您有帮助，请关注公众号【煎饼果子卷AI】  $NC"
Write-Host ""
Write-Host "$YELLOW⚡  [小小广告] Cursor官网正规成品号：Unlimited ♾️ ¥1050 | 7天周卡 $100 ¥210 | 7天周卡 $500 ¥1050 | 7天周卡 $1000 ¥2450 | 全部7天质保 | ，WeChat：JavaRookie666  $NC"
Write-Host "$BLUE================================$NC"

# 🎯 用户选择菜单
Write-Host ""
Write-Host "$GREEN🎯 [选择模式]$NC 请选择您要执行的操作："
Write-Host ""
Write-Host "$BLUE  1️⃣  仅修改机器码$NC"
Write-Host "$YELLOW      • 执行机器码修改功能$NC"
Write-Host "$YELLOW      • 执行注入破解JS代码到核心文件$NC"
Write-Host "$YELLOW      • 跳过文件夹删除/环境重置步骤$NC"
Write-Host "$YELLOW      • 保留现有Cursor配置和数据$NC"
Write-Host ""
Write-Host "$BLUE  2️⃣  重置环境+修改机器码$NC"
Write-Host "$RED      • 执行完全环境重置（删除Cursor文件夹）$NC"
Write-Host "$RED      • ⚠️  配置将丢失，请注意备份$NC"
Write-Host "$YELLOW      • 按照机器代码修改$NC"
Write-Host "$YELLOW      • 执行注入破解JS代码到核心文件$NC"
Write-Host "$YELLOW      • 这相当于当前的完整脚本行为$NC"
Write-Host ""

# 获取用户选择
do {
    $userChoice = Read-Host "请输入选择 (1 或 2)"
    if ($userChoice -eq "1") {
        Write-Host "$GREEN✅ [选择]$NC 您选择了：仅修改机器码"
        $executeMode = "MODIFY_ONLY"
        break
    } elseif ($userChoice -eq "2") {
        Write-Host "$GREEN✅ [选择]$NC 您选择了：重置环境+修改机器码"
        Write-Host "$RED⚠️  [重要警告]$NC 此操作将删除所有Cursor配置文件！"
        $confirmReset = Read-Host "确认执行完全重置？(输入 yes 确认，其他任意键取消)"
        if ($confirmReset -eq "yes") {
            $executeMode = "RESET_AND_MODIFY"
            break
        } else {
            Write-Host "$YELLOW👋 [取消]$NC 用户取消重置操作"
            continue
        }
    } else {
        Write-Host "$RED❌ [错误]$NC 无效选择，请输入 1 或 2"
    }
} while ($true)

Write-Host ""

# 📋 根据选择显示执行流程说明
if ($executeMode -eq "MODIFY_ONLY") {
    Write-Host "$GREEN📋 [执行流程]$NC 仅修改机器码模式将按以下步骤执行："
    Write-Host "$BLUE  1️⃣  检测Cursor配置文件$NC"
    Write-Host "$BLUE  2️⃣  备份现有配置文件$NC"
    Write-Host "$BLUE  3️⃣  修改机器码配置$NC"
    Write-Host "$BLUE  4️⃣  显示操作完成信息$NC"
    Write-Host ""
    Write-Host "$YELLOW⚠️  [注意事项]$NC"
    Write-Host "$YELLOW  • 不会删除任何文件夹或重置环境$NC"
    Write-Host "$YELLOW  • 保留所有现有配置和数据$NC"
    Write-Host "$YELLOW  • 原配置文件会自动备份$NC"
} else {
    Write-Host "$GREEN📋 [执行流程]$NC 重置环境+修改机器码模式将按以下步骤执行："
    Write-Host "$BLUE  1️⃣  检测并关闭Cursor进程$NC"
    Write-Host "$BLUE  2️⃣  保存Cursor程序路径信息$NC"
    Write-Host "$BLUE  3️⃣  删除指定的Cursor试用相关文件夹$NC"
    Write-Host "$BLUE      📁 C:\Users\Administrator\.cursor$NC"
    Write-Host "$BLUE      📁 C:\Users\Administrator\AppData\Roaming\Cursor$NC"
    Write-Host "$BLUE      📁 C:\Users\%USERNAME%\.cursor$NC"
    Write-Host "$BLUE      📁 C:\Users\%USERNAME%\AppData\Roaming\Cursor$NC"
    Write-Host "$BLUE  3.5️⃣ 预创建必要目录结构，避免权限问题$NC"
    Write-Host "$BLUE  4️⃣  重新启动Cursor让其生成新的配置文件$NC"
    Write-Host "$BLUE  5️⃣  等待配置文件生成完成（最多45秒）$NC"
    Write-Host "$BLUE  6️⃣  关闭Cursor进程$NC"
    Write-Host "$BLUE  7️⃣  修改新生成的机器码配置文件$NC"
    Write-Host "$BLUE  8️⃣  显示操作完成统计信息$NC"
    Write-Host ""
    Write-Host "$YELLOW⚠️  [注意事项]$NC"
    Write-Host "$YELLOW  • 脚本执行过程中请勿手动操作Cursor$NC"
    Write-Host "$YELLOW  • 建议在执行前关闭所有Cursor窗口$NC"
    Write-Host "$YELLOW  • 执行完成后需要重新启动Cursor$NC"
    Write-Host "$YELLOW  • 原配置文件会自动备份到backups文件夹$NC"
}
Write-Host ""

# 🤔 用户确认
Write-Host "$GREEN🤔 [确认]$NC 请确认您已了解上述执行流程"
$confirmation = Read-Host "是否继续执行？(输入 y 或 yes 继续，其他任意键退出)"
if ($confirmation -notmatch "^(y|yes)$") {
    Write-Host "$YELLOW👋 [退出]$NC 用户取消执行，脚本退出"
    Read-Host "按回车键退出"
    exit 0
}
Write-Host "$GREEN✅ [确认]$NC 用户确认继续执行"
Write-Host ""

# 获取并显示 Cursor 版本
function Get-CursorVersion {
    try {
        # 主要检测路径（基于安装路径解析）
        $installPath = Resolve-CursorInstallPath
        $packagePath = if ($installPath) { Join-Path $installPath "resources\app\package.json" } else { $null }
        if ($packagePath -and (Test-Path $packagePath)) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[信息]$NC 当前安装的 Cursor 版本: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # 备用路径检测（兼容旧目录结构）
        $altPath = if ($global:CursorLocalAppDataRoot) { Join-Path $global:CursorLocalAppDataRoot "cursor\resources\app\package.json" } else { $null }
        if ($altPath -and (Test-Path $altPath)) {
            $packageJson = Get-Content $altPath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[信息]$NC 当前安装的 Cursor 版本: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        Write-Host "$YELLOW[警告]$NC 无法检测到 Cursor 版本"
        Write-Host "$YELLOW[提示]$NC 请确保 Cursor 已正确安装"
        return $null
    }
    catch {
        Write-Host "$RED[错误]$NC 获取 Cursor 版本失败: $_"
        return $null
    }
}

# 获取并显示版本信息
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW💡 [重要提示]$NC 最新的 1.0.x 版本已支持"

Write-Host ""

# 🔍 检查并关闭 Cursor 进程
Write-Host "$GREEN🔍 [检查]$NC 正在检查 Cursor 进程..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE🔍 [调试]$NC 正在获取 $processName 进程详细信息："
    Get-WmiObject Win32_Process -Filter "name='$processName'" |
        Select-Object ProcessId, ExecutablePath, CommandLine |
        Format-List
}

# 定义最大重试次数和等待时间
$MAX_RETRIES = 5
$WAIT_TIME = 1

# 🔄 处理进程关闭并保存进程信息
function Close-CursorProcessAndSaveInfo {
    param($processName)

    $global:CursorProcessInfo = $null

    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "$YELLOW⚠️  [警告]$NC 发现 $processName 正在运行"

        # 💾 保存进程信息用于后续重启 - 修复：确保获取单个进程路径
        $firstProcess = if ($processes -is [array]) { $processes[0] } else { $processes }
        $processPath = $firstProcess.Path

        # 确保路径是字符串而不是数组
        if ($processPath -is [array]) {
            $processPath = $processPath[0]
        }

        $global:CursorProcessInfo = @{
            ProcessName = $firstProcess.ProcessName
            Path = $processPath
            StartTime = $firstProcess.StartTime
        }
        Write-Host "$GREEN💾 [保存]$NC 已保存进程信息: $($global:CursorProcessInfo.Path)"

        Get-ProcessDetails $processName

        Write-Host "$YELLOW🔄 [操作]$NC 尝试关闭 $processName..."
        Stop-Process -Name $processName -Force

        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }

            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED❌ [错误]$NC 在 $MAX_RETRIES 次尝试后仍无法关闭 $processName"
                Get-ProcessDetails $processName
                Write-Host "$RED💥 [错误]$NC 请手动关闭进程后重试"
                Read-Host "按回车键退出"
                exit 1
            }
            Write-Host "$YELLOW⏳ [等待]$NC 等待进程关闭，尝试 $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN✅ [成功]$NC $processName 已成功关闭"
    } else {
        Write-Host "$BLUE💡 [提示]$NC 未发现 $processName 进程运行"
        # 尝试找到Cursor的安装路径
        $installPath = Resolve-CursorInstallPath
        $candidatePath = if ($installPath) { Join-Path $installPath "Cursor.exe" } else { $null }
        if ($candidatePath -and (Test-Path $candidatePath)) {
            $global:CursorProcessInfo = @{
                ProcessName = "Cursor"
                Path = $candidatePath
                StartTime = $null
            }
            Write-Host "$GREEN💾 [发现]$NC 找到Cursor安装路径: $candidatePath"
        }

        if (-not $global:CursorProcessInfo) {
            Write-Host "$YELLOW⚠️  [警告]$NC 未找到Cursor安装路径，将使用默认路径"
            $defaultInstallPath = if ($global:CursorLocalAppDataRoot) { Join-Path $global:CursorLocalAppDataRoot "Programs\cursor\Cursor.exe" } else { "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" }
            $global:CursorProcessInfo = @{
                ProcessName = "Cursor"
                Path = $defaultInstallPath
                StartTime = $null
            }
        }
    }
}

# �️ 确保备份目录存在
if (-not $BACKUP_DIR) {
    Write-Host "$YELLOW⚠️  [警告]$NC 无法解析备份目录路径，跳过创建"
} elseif (-not (Test-Path $BACKUP_DIR)) {
    try {
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        Write-Host "$GREEN✅ [备份目录]$NC 备份目录创建成功: $BACKUP_DIR"
    } catch {
        Write-Host "$YELLOW⚠️  [警告]$NC 备份目录创建失败: $($_.Exception.Message)"
    }
}

# �🚀 根据用户选择执行相应功能
if ($executeMode -eq "MODIFY_ONLY") {
    Write-Host "$GREEN🚀 [开始]$NC 开始执行仅修改机器码功能..."

    # 先进行环境检查
    $envCheck = Test-CursorEnvironment -Mode "MODIFY_ONLY"
    if (-not $envCheck.Success) {
        Write-Host ""
        Write-Host "$RED❌ [环境检查失败]$NC 无法继续执行，发现以下问题："
        foreach ($issue in $envCheck.Issues) {
            Write-Host "$RED  • ${issue}$NC"
        }
        Write-Host ""
        Write-Host "$YELLOW💡 [建议]$NC 请选择以下操作："
        Write-Host "$BLUE  1️⃣  选择'重置环境+修改机器码'选项（推荐）$NC"
        Write-Host "$BLUE  2️⃣  手动启动Cursor一次，然后重新运行脚本$NC"
        Write-Host "$BLUE  3️⃣  检查Cursor是否正确安装$NC"
        Write-Host ""
        Read-Host "按回车键退出"
        exit 1
    }

    # 执行机器码修改
    $configSuccess = Modify-MachineCodeConfig -Mode "MODIFY_ONLY"

    if ($configSuccess) {
        Write-Host ""
        Write-Host "$GREEN🎉 [配置文件]$NC 机器码配置文件修改完成！"

        # 添加注册表修改
        Write-Host "$BLUE🔧 [注册表]$NC 正在修改系统注册表..."
        $registrySuccess = Update-MachineGuid

        # 🔧 新增：JavaScript注入功能（设备识别绕过增强）
        Write-Host ""
        Write-Host "$BLUE🔧 [设备识别绕过]$NC 正在执行JavaScript注入功能..."
        Write-Host "$BLUE💡 [说明]$NC 此功能将直接修改Cursor内核JS文件，实现更深层的设备识别绕过"
        $jsSuccess = Modify-CursorJSFiles

        if ($registrySuccess) {
            Write-Host "$GREEN✅ [注册表]$NC 系统注册表修改成功"

            if ($jsSuccess) {
                Write-Host "$GREEN✅ [JavaScript注入]$NC JavaScript注入功能执行成功"
                Write-Host ""
                Write-Host "$GREEN🎉 [完成]$NC 所有机器码修改完成（增强版）！"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下修改："
                Write-Host "$GREEN  ✓ Cursor 配置文件 (storage.json)$NC"
                Write-Host "$GREEN  ✓ 系统注册表 (MachineGuid)$NC"
                Write-Host "$GREEN  ✓ JavaScript内核注入（设备识别绕过）$NC"
            } else {
                Write-Host "$YELLOW⚠️  [JavaScript注入]$NC JavaScript注入功能执行失败，但其他功能成功"
                Write-Host ""
                Write-Host "$GREEN🎉 [完成]$NC 所有机器码修改完成！"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下修改："
                Write-Host "$GREEN  ✓ Cursor 配置文件 (storage.json)$NC"
                Write-Host "$GREEN  ✓ 系统注册表 (MachineGuid)$NC"
                Write-Host "$YELLOW  ⚠ JavaScript内核注入（部分失败）$NC"
            }

            # 🔒 添加配置文件保护机制
            Write-Host "$BLUE🔒 [保护]$NC 正在设置配置文件保护..."
            try {
                $configPath = $STORAGE_FILE
                if (-not $configPath) {
                    throw "无法解析配置文件路径"
                }
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
        } else {
            Write-Host "$YELLOW⚠️  [注册表]$NC 注册表修改失败，但配置文件修改成功"

            if ($jsSuccess) {
                Write-Host "$GREEN✅ [JavaScript注入]$NC JavaScript注入功能执行成功"
                Write-Host ""
                Write-Host "$YELLOW🎉 [部分完成]$NC 配置文件和JavaScript注入完成，注册表修改失败"
                Write-Host "$BLUE💡 [建议]$NC 可能需要管理员权限来修改注册表"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下修改："
                Write-Host "$GREEN  ✓ Cursor 配置文件 (storage.json)$NC"
                Write-Host "$YELLOW  ⚠ 系统注册表 (MachineGuid) - 失败$NC"
                Write-Host "$GREEN  ✓ JavaScript内核注入（设备识别绕过）$NC"
            } else {
                Write-Host "$YELLOW⚠️  [JavaScript注入]$NC JavaScript注入功能执行失败"
                Write-Host ""
                Write-Host "$YELLOW🎉 [部分完成]$NC 配置文件修改完成，注册表和JavaScript注入失败"
                Write-Host "$BLUE💡 [建议]$NC 可能需要管理员权限来修改注册表"
            }

            # 🔒 即使注册表修改失败，也要保护配置文件
            Write-Host "$BLUE🔒 [保护]$NC 正在设置配置文件保护..."
            try {
                $configPath = $STORAGE_FILE
                if (-not $configPath) {
                    throw "无法解析配置文件路径"
                }
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
        }

        Write-Host ""
        Write-Host "$BLUE🚫 [禁用更新]$NC 正在禁用 Cursor 自动更新..."
        if (Disable-CursorAutoUpdate) {
            Write-Host "$GREEN✅ [禁用更新]$NC 自动更新已处理"
        } else {
            Write-Host "$YELLOW⚠️  [禁用更新]$NC 未能确认禁用更新，可能需要手动处理"
        }

        Write-Host "$BLUE💡 [提示]$NC 现在可以启动Cursor使用新的机器码配置"
    } else {
        Write-Host ""
        Write-Host "$RED❌ [失败]$NC 机器码修改失败！"
        Write-Host "$YELLOW💡 [建议]$NC 请尝试'重置环境+修改机器码'选项"
    }
} else {
    # 完整的重置环境+修改机器码流程
    Write-Host "$GREEN🚀 [开始]$NC 开始执行重置环境+修改机器码功能..."

    # 🚀 关闭所有 Cursor 进程并保存信息
    Close-CursorProcessAndSaveInfo "Cursor"
    if (-not $global:CursorProcessInfo) {
        Close-CursorProcessAndSaveInfo "cursor"
    }

    # 🚨 重要警告提示
    Write-Host ""
    Write-Host "$RED🚨 [重要警告]$NC ============================================"
    Write-Host "$YELLOW⚠️  [风控提醒]$NC Cursor 风控机制非常严格！"
    Write-Host "$YELLOW⚠️  [必须删除]$NC 必须完全删除指定文件夹，不能有任何残留设置"
    Write-Host "$YELLOW⚠️  [防掉试用]$NC 只有彻底清理才能有效防止掉试用Pro状态"
    Write-Host "$RED🚨 [重要警告]$NC ============================================"
    Write-Host ""

    # 🎯 执行 Cursor 防掉试用Pro删除文件夹功能
    Write-Host "$GREEN🚀 [开始]$NC 开始执行核心功能..."
    Remove-CursorTrialFolders



    # 🔄 重启Cursor让其重新生成配置文件
    Restart-CursorAndWait

    # 🛠️ 修改机器码配置
    $configSuccess = Modify-MachineCodeConfig
    
    # 🧹 执行 Cursor 初始化清理
    Invoke-CursorInitialization

    if ($configSuccess) {
        Write-Host ""
        Write-Host "$GREEN🎉 [配置文件]$NC 机器码配置文件修改完成！"

        # 添加注册表修改
        Write-Host "$BLUE🔧 [注册表]$NC 正在修改系统注册表..."
        $registrySuccess = Update-MachineGuid

        # 🔧 新增：JavaScript注入功能（设备识别绕过增强）
        Write-Host ""
        Write-Host "$BLUE🔧 [设备识别绕过]$NC 正在执行JavaScript注入功能..."
        Write-Host "$BLUE💡 [说明]$NC 此功能将直接修改Cursor内核JS文件，实现更深层的设备识别绕过"
        $jsSuccess = Modify-CursorJSFiles

        if ($registrySuccess) {
            Write-Host "$GREEN✅ [注册表]$NC 系统注册表修改成功"

            if ($jsSuccess) {
                Write-Host "$GREEN✅ [JavaScript注入]$NC JavaScript注入功能执行成功"
                Write-Host ""
                Write-Host "$GREEN🎉 [完成]$NC 所有操作完成（增强版）！"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下操作："
                Write-Host "$GREEN  ✓ 删除 Cursor 试用相关文件夹$NC"
                Write-Host "$GREEN  ✓ Cursor 初始化清理$NC"
                Write-Host "$GREEN  ✓ 重新生成配置文件$NC"
                Write-Host "$GREEN  ✓ 修改机器码配置$NC"
                Write-Host "$GREEN  ✓ 修改系统注册表$NC"
                Write-Host "$GREEN  ✓ JavaScript内核注入（设备识别绕过）$NC"
            } else {
                Write-Host "$YELLOW⚠️  [JavaScript注入]$NC JavaScript注入功能执行失败，但其他功能成功"
                Write-Host ""
                Write-Host "$GREEN🎉 [完成]$NC 所有操作完成！"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下操作："
                Write-Host "$GREEN  ✓ 删除 Cursor 试用相关文件夹$NC"
                Write-Host "$GREEN  ✓ Cursor 初始化清理$NC"
                Write-Host "$GREEN  ✓ 重新生成配置文件$NC"
                Write-Host "$GREEN  ✓ 修改机器码配置$NC"
                Write-Host "$GREEN  ✓ 修改系统注册表$NC"
                Write-Host "$YELLOW  ⚠ JavaScript内核注入（部分失败）$NC"
            }

            # 🔒 添加配置文件保护机制
            Write-Host "$BLUE🔒 [保护]$NC 正在设置配置文件保护..."
            try {
                $configPath = $STORAGE_FILE
                if (-not $configPath) {
                    throw "无法解析配置文件路径"
                }
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
        } else {
            Write-Host "$YELLOW⚠️  [注册表]$NC 注册表修改失败，但其他操作成功"

            if ($jsSuccess) {
                Write-Host "$GREEN✅ [JavaScript注入]$NC JavaScript注入功能执行成功"
                Write-Host ""
                Write-Host "$YELLOW🎉 [部分完成]$NC 大部分操作完成，注册表修改失败"
                Write-Host "$BLUE💡 [建议]$NC 可能需要管理员权限来修改注册表"
                Write-Host "$BLUE📋 [详情]$NC 已完成以下操作："
                Write-Host "$GREEN  ✓ 删除 Cursor 试用相关文件夹$NC"
                Write-Host "$GREEN  ✓ Cursor 初始化清理$NC"
                Write-Host "$GREEN  ✓ 重新生成配置文件$NC"
                Write-Host "$GREEN  ✓ 修改机器码配置$NC"
                Write-Host "$YELLOW  ⚠ 修改系统注册表 - 失败$NC"
                Write-Host "$GREEN  ✓ JavaScript内核注入（设备识别绕过）$NC"
            } else {
                Write-Host "$YELLOW⚠️  [JavaScript注入]$NC JavaScript注入功能执行失败"
                Write-Host ""
                Write-Host "$YELLOW🎉 [部分完成]$NC 大部分操作完成，注册表和JavaScript注入失败"
                Write-Host "$BLUE💡 [建议]$NC 可能需要管理员权限来修改注册表"
            }

            # 🔒 即使注册表修改失败，也要保护配置文件
            Write-Host "$BLUE🔒 [保护]$NC 正在设置配置文件保护..."
            try {
                $configPath = $STORAGE_FILE
                if (-not $configPath) {
                    throw "无法解析配置文件路径"
                }
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
        }

        Write-Host ""
        Write-Host "$BLUE🚫 [禁用更新]$NC 正在禁用 Cursor 自动更新..."
        if (Disable-CursorAutoUpdate) {
            Write-Host "$GREEN✅ [禁用更新]$NC 自动更新已处理"
        } else {
            Write-Host "$YELLOW⚠️  [禁用更新]$NC 未能确认禁用更新，可能需要手动处理"
        }
    } else {
        Write-Host ""
        Write-Host "$RED❌ [失败]$NC 机器码配置修改失败！"
        Write-Host "$YELLOW💡 [建议]$NC 请检查错误信息并重试"
    }
}


# 📱 显示公众号信息
Write-Host ""
Write-Host "$GREEN================================$NC"
Write-Host "$YELLOW📱  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  $NC"
Write-Host "$YELLOW⚡   [小小广告] Cursor官网正规成品号：Unlimited ♾️ ¥1050 | 7天周卡 $100 ¥210 | 7天周卡 $500 ¥1050 | 7天周卡 $1000 ¥2450 | 全部7天质保 | ，WeChat：JavaRookie666  $NC"
Write-Host "$GREEN================================$NC"
Write-Host ""

# 🎉 脚本执行完成
Write-Host "$GREEN🎉 [脚本完成]$NC 感谢使用 Cursor 机器码修改工具！"
Write-Host "$BLUE💡 [提示]$NC 如有问题请参考公众号或重新运行脚本"
Write-Host ""
Read-Host "按回车键退出"

