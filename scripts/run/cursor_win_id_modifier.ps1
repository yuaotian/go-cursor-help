# 设置输出编码为 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色定义
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# 配置文件路径
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

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

    # 当前用户路径
    $currentUserPaths = @(
        "$env:USERPROFILE\.cursor",
        "$env:APPDATA\Cursor"
    )

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
    } else {
        Write-Host "$YELLOW🤔 [提示]$NC 未找到需要删除的文件夹，可能已经清理过了"
    }
    Write-Host ""
}

# 📝 原有的 Cursor 初始化函数（已暂时禁用）
function Cursor-初始化-已禁用 {
    Write-Host "$YELLOW⚠️  [提示]$NC 原有的机器码修改功能已暂时禁用"
    Write-Host "$BLUE📋 [说明]$NC 当前版本专注于删除文件夹功能，机器码修改功能已屏蔽"
    Write-Host ""
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
Write-Host "$YELLOW💰   [小小广告]  出售CursorPro教育号一年质保三个月，有需要找我(86)，WeChat：JavaRookie666  $NC"
Write-Host "$BLUE================================$NC"

# 获取并显示 Cursor 版本
function Get-CursorVersion {
    try {
        # 主要检测路径
        $packagePath = "$env:LOCALAPPDATA\\Programs\\cursor\\resources\\app\\package.json"
        
        if (Test-Path $packagePath) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[信息]$NC 当前安装的 Cursor 版本: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # 备用路径检测
        $altPath = "$env:LOCALAPPDATA\\cursor\\resources\\app\\package.json"
        if (Test-Path $altPath) {
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
Write-Host "$BLUE📋 [功能说明]$NC 本工具专注于删除Cursor试用相关文件夹，暂时屏蔽机器码修改功能"
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

# 🔄 处理进程关闭
function Close-CursorProcess {
    param($processName)

    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW⚠️  [警告]$NC 发现 $processName 正在运行"
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
    }
}

# 🚀 关闭所有 Cursor 进程
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

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

# 📝 以下机器码修改相关功能已暂时屏蔽
Write-Host "$YELLOW⚠️  [提示]$NC 机器码修改功能已暂时屏蔽，专注于文件夹删除功能"
Write-Host "$BLUE📋 [说明]$NC 如需恢复机器码修改功能，请联系开发者"
Write-Host ""

<#
# 🚫 已屏蔽：创建备份目录
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# 🚫 已屏蔽：备份现有配置
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN📁 [备份]$NC 正在备份配置文件..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# 🚫 已屏蔽：生成新的 ID
Write-Host "$GREEN🔄 [生成]$NC 正在生成新的 ID..."
#>

<#
# 🚫 已屏蔽：随机ID生成函数
function Get-RandomHex {
    param (
        [int]$length
    )

    $bytes = New-Object byte[] ($length)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $hexString = [System.BitConverter]::ToString($bytes) -replace '-',''
    $rng.Dispose()
    return $hexString
}

# 🚫 已屏蔽：改进 ID 生成函数
function New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -replace '[xy]', {
        param($match)
        $r = [Random]::new().Next(16)
        $v = if ($match.Value -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
        return $v.ToString("x")
    }
    return $result
}

# 🚫 已屏蔽：在生成 ID 时使用新函数
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
# 将 auth0|user_ 转换为字节数组的十六进制
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
# 生成32字节(64个十六进制字符)的随机数作为 machineId 的随机部分
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"
#>

<#
# 🚫 已屏蔽：在Update-MachineGuid函数前添加权限检查
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED❌ [错误]$NC 请使用管理员权限运行此脚本"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
#>

<#
# 🚫 已屏蔽：Update-MachineGuid 函数
function Update-MachineGuid-已屏蔽 {
    Write-Host "$YELLOW⚠️  [提示]$NC 注册表修改功能已暂时屏蔽"
    Write-Host "$BLUE📋 [说明]$NC 当前版本专注于删除文件夹功能"
    return $false
}
#>

<#
# 🚫 已屏蔽：创建或更新配置文件
Write-Host "$YELLOW⚠️  [提示]$NC 配置文件修改功能已暂时屏蔽"
Write-Host "$BLUE📋 [说明]$NC 当前版本专注于删除文件夹功能，不修改配置文件"
#>

# 🎉 显示操作完成信息
Write-Host ""
Write-Host "$GREEN🎉 [完成]$NC Cursor 防掉试用Pro删除操作已完成！"
Write-Host ""

# 📱 显示公众号信息
Write-Host "$GREEN================================$NC"
Write-Host "$YELLOW📱  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  $NC"
Write-Host "$GREEN================================$NC"
Write-Host ""
Write-Host "$GREEN🚀 [提示]$NC 现在可以重新启动 Cursor 尝试使用了！"
Write-Host ""

# 🚫 自动更新功能已暂时屏蔽
Write-Host "$YELLOW⚠️  [提示]$NC 自动更新禁用功能已暂时屏蔽"
Write-Host "$BLUE📋 [说明]$NC 当前版本专注于删除文件夹功能"
Write-Host ""

# 🎉 脚本执行完成
Write-Host "$GREEN🎉 [完成]$NC 所有操作已完成！"
Write-Host ""
Write-Host "$BLUE💡 [提示]$NC 如果需要恢复机器码修改功能，请联系开发者"
Write-Host "$YELLOW⚠️  [注意]$NC 重启 Cursor 后生效"
Write-Host ""
Write-Host "$GREEN🚀 [下一步]$NC 现在可以启动 Cursor 尝试使用了！"
Write-Host ""
Read-Host "按回车键退出"
exit 0