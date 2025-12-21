# ========================================
# Cursor Hook 注入脚本 (Windows)
# ========================================
#
# 🎯 功能：将 cursor_hook.js 注入到 Cursor 的 main.js 文件顶部
# 
# 📦 使用方式：
# 1. 以管理员权限运行 PowerShell
# 2. 执行: .\inject_hook_win.ps1
#
# ⚠️ 注意事项：
# - 会自动备份原始 main.js 文件
# - 支持回滚到原始版本
# - Cursor 更新后需要重新注入
#
# ========================================

param(
    [switch]$Rollback,  # 回滚到原始版本
    [switch]$Force,     # 强制重新注入
    [switch]$Debug      # 启用调试模式
)

# 颜色定义
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# 日志函数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO"  { Write-Host "$GREEN[INFO]$NC $Message" }
        "WARN"  { Write-Host "$YELLOW[WARN]$NC $Message" }
        "ERROR" { Write-Host "$RED[ERROR]$NC $Message" }
        "DEBUG" { if ($Debug) { Write-Host "$BLUE[DEBUG]$NC $Message" } }
    }
}

# 获取 Cursor 安装路径
function Get-CursorPath {
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\resources\app\out\main.js",
        "$env:LOCALAPPDATA\Programs\Cursor\resources\app\out\main.js",
        "C:\Program Files\Cursor\resources\app\out\main.js",
        "C:\Program Files (x86)\Cursor\resources\app\out\main.js"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

# 获取 Hook 脚本路径
function Get-HookScriptPath {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $hookPath = Join-Path $scriptDir "cursor_hook.js"
    
    if (Test-Path $hookPath) {
        return $hookPath
    }
    
    # 尝试从当前目录查找
    $currentDir = Get-Location
    $hookPath = Join-Path $currentDir "cursor_hook.js"
    
    if (Test-Path $hookPath) {
        return $hookPath
    }
    
    return $null
}

# 检查是否已注入
function Test-AlreadyInjected {
    param([string]$MainJsPath)
    
    $content = Get-Content $MainJsPath -Raw -Encoding UTF8
    return $content -match "__cursor_patched__"
}

# 备份原始文件
function Backup-MainJs {
    param([string]$MainJsPath)
    
    $backupDir = Join-Path (Split-Path -Parent $MainJsPath) "backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $backupDir "main.js.backup_$timestamp"
    
    # 检查是否有原始备份
    $originalBackup = Join-Path $backupDir "main.js.original"
    if (-not (Test-Path $originalBackup)) {
        Copy-Item $MainJsPath $originalBackup -Force
        Write-Log "已创建原始备份: $originalBackup"
    }
    
    Copy-Item $MainJsPath $backupPath -Force
    Write-Log "已创建时间戳备份: $backupPath"
    
    return $originalBackup
}

# 回滚到原始版本
function Restore-MainJs {
    param([string]$MainJsPath)
    
    $backupDir = Join-Path (Split-Path -Parent $MainJsPath) "backups"
    $originalBackup = Join-Path $backupDir "main.js.original"
    
    if (Test-Path $originalBackup) {
        Copy-Item $originalBackup $MainJsPath -Force
        Write-Log "已回滚到原始版本" "INFO"
        return $true
    } else {
        Write-Log "未找到原始备份文件" "ERROR"
        return $false
    }
}

# 注入 Hook 代码
function Inject-Hook {
    param(
        [string]$MainJsPath,
        [string]$HookScriptPath
    )
    
    # 读取 Hook 脚本内容
    $hookContent = Get-Content $HookScriptPath -Raw -Encoding UTF8
    
    # 读取 main.js 内容
    $mainContent = Get-Content $MainJsPath -Raw -Encoding UTF8
    
    # 查找注入点：在 Sentry 初始化代码之后
    # Sentry 初始化代码特征: _sentryDebugIds
    $sentryPattern = '(?<=\}\(\);)\s*(?=var\s+\w+\s*=\s*function)'
    
    if ($mainContent -match $sentryPattern) {
        # 在 Sentry 初始化之后注入
        $injectionPoint = $mainContent.IndexOf('}();') + 4
        $newContent = $mainContent.Substring(0, $injectionPoint) + "`n`n// ========== Cursor Hook 注入开始 ==========`n" + $hookContent + "`n// ========== Cursor Hook 注入结束 ==========`n`n" + $mainContent.Substring($injectionPoint)
    } else {
        # 如果找不到 Sentry，直接在文件开头注入（在版权声明之后）
        $copyrightEnd = $mainContent.IndexOf('*/') + 2
        if ($copyrightEnd -gt 2) {
            $newContent = $mainContent.Substring(0, $copyrightEnd) + "`n`n// ========== Cursor Hook 注入开始 ==========`n" + $hookContent + "`n// ========== Cursor Hook 注入结束 ==========`n`n" + $mainContent.Substring($copyrightEnd)
        } else {
            $newContent = "// ========== Cursor Hook 注入开始 ==========`n" + $hookContent + "`n// ========== Cursor Hook 注入结束 ==========`n`n" + $mainContent
        }
    }
    
    # 写入修改后的内容
    Set-Content -Path $MainJsPath -Value $newContent -Encoding UTF8 -NoNewline

    return $true
}

# 关闭 Cursor 进程
function Stop-CursorProcess {
    $cursorProcesses = Get-Process -Name "Cursor*" -ErrorAction SilentlyContinue

    if ($cursorProcesses) {
        Write-Log "发现 Cursor 进程正在运行，正在关闭..."
        $cursorProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Log "Cursor 进程已关闭"
    }
}

# 主函数
function Main {
    Write-Host ""
    Write-Host "$BLUE========================================$NC"
    Write-Host "$BLUE   Cursor Hook 注入工具 (Windows)      $NC"
    Write-Host "$BLUE========================================$NC"
    Write-Host ""

    # 获取 Cursor main.js 路径
    $mainJsPath = Get-CursorPath
    if (-not $mainJsPath) {
        Write-Log "未找到 Cursor 安装路径" "ERROR"
        Write-Log "请确保 Cursor 已正确安装" "ERROR"
        exit 1
    }
    Write-Log "找到 Cursor main.js: $mainJsPath"

    # 回滚模式
    if ($Rollback) {
        Write-Log "执行回滚操作..."
        Stop-CursorProcess
        if (Restore-MainJs -MainJsPath $mainJsPath) {
            Write-Log "回滚成功！" "INFO"
        } else {
            Write-Log "回滚失败！" "ERROR"
            exit 1
        }
        exit 0
    }

    # 检查是否已注入
    if ((Test-AlreadyInjected -MainJsPath $mainJsPath) -and -not $Force) {
        Write-Log "Hook 已经注入，无需重复操作" "WARN"
        Write-Log "如需强制重新注入，请使用 -Force 参数" "INFO"
        exit 0
    }

    # 获取 Hook 脚本路径
    $hookScriptPath = Get-HookScriptPath
    if (-not $hookScriptPath) {
        Write-Log "未找到 cursor_hook.js 文件" "ERROR"
        Write-Log "请确保 cursor_hook.js 与此脚本在同一目录" "ERROR"
        exit 1
    }
    Write-Log "找到 Hook 脚本: $hookScriptPath"

    # 关闭 Cursor 进程
    Stop-CursorProcess

    # 备份原始文件
    Write-Log "正在备份原始文件..."
    $backupPath = Backup-MainJs -MainJsPath $mainJsPath

    # 注入 Hook 代码
    Write-Log "正在注入 Hook 代码..."
    try {
        if (Inject-Hook -MainJsPath $mainJsPath -HookScriptPath $hookScriptPath) {
            Write-Log "Hook 注入成功！" "INFO"
        } else {
            Write-Log "Hook 注入失败！" "ERROR"
            exit 1
        }
    } catch {
        Write-Log "注入过程中发生错误: $_" "ERROR"
        Write-Log "正在回滚..." "WARN"
        Restore-MainJs -MainJsPath $mainJsPath
        exit 1
    }

    Write-Host ""
    Write-Host "$GREEN========================================$NC"
    Write-Host "$GREEN   ✅ Hook 注入完成！                   $NC"
    Write-Host "$GREEN========================================$NC"
    Write-Host ""
    Write-Log "现在可以启动 Cursor 了"
    Write-Log "ID 配置文件位置: $env:USERPROFILE\.cursor_ids.json"
    Write-Host ""
    Write-Host "$YELLOW提示:$NC"
    Write-Host "  - 如需回滚，请运行: .\inject_hook_win.ps1 -Rollback"
    Write-Host "  - 如需强制重新注入，请运行: .\inject_hook_win.ps1 -Force"
    Write-Host "  - 如需启用调试日志，请运行: .\inject_hook_win.ps1 -Debug"
    Write-Host ""
}

# 执行主函数
Main

