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

        # 🔧 预创建必要的目录结构，避免权限问题
        Write-Host "$BLUE🔧 [修复]$NC 预创建必要的目录结构以避免权限问题..."

        $cursorAppData = "$env:APPDATA\Cursor"
        $cursorLocalAppData = "$env:LOCALAPPDATA\cursor"
        $cursorUserProfile = "$env:USERPROFILE\.cursor"

        # 创建主要目录
        try {
            if (-not (Test-Path $cursorAppData)) {
                New-Item -ItemType Directory -Path $cursorAppData -Force | Out-Null
            }
            if (-not (Test-Path $cursorUserProfile)) {
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

        # 尝试使用备用路径
        $backupPaths = @(
            "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
            "$env:PROGRAMFILES\Cursor\Cursor.exe",
            "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
        )

        $foundPath = $null
        foreach ($backupPath in $backupPaths) {
            if (Test-Path $backupPath) {
                $foundPath = $backupPath
                Write-Host "$GREEN💡 [发现]$NC 使用备用路径: $foundPath"
                break
            }
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
        $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
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

# � 检查配置文件和环境
function Test-CursorEnvironment {
    param(
        [string]$Mode = "FULL"
    )

    Write-Host ""
    Write-Host "$BLUE🔍 [环境检查]$NC 正在检查Cursor环境..."

    $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    $cursorAppData = "$env:APPDATA\Cursor"
    $issues = @()

    # 检查配置文件
    if (-not (Test-Path $configPath)) {
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
    if (-not (Test-Path $cursorAppData)) {
        $issues += "Cursor应用数据目录不存在: $cursorAppData"
    }

    # 检查Cursor安装
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:PROGRAMFILES\Cursor\Cursor.exe",
        "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
    )

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
            Write-Host "$RED  • $issue$NC"
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

    $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"

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

    # 验证配置文件格式
    try {
        Write-Host "$BLUE🔍 [验证]$NC 检查配置文件格式..."
        $originalContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
        $config = $originalContent | ConvertFrom-Json -ErrorAction Stop
        Write-Host "$GREEN✅ [验证]$NC 配置文件格式正确"
    } catch {
        Write-Host "$RED❌ [错误]$NC 配置文件格式错误: $($_.Exception.Message)"
        Write-Host "$YELLOW💡 [建议]$NC 配置文件可能已损坏，建议选择'重置环境+修改机器码'选项"
        return $false
    }

    try {
        # 显示操作进度
        Write-Host "$BLUE⏳ [进度]$NC 1/5 - 生成新的设备标识符..."

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
        $MACHINE_ID = "$prefixHex$randomPart"
        $SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

        Write-Host "$GREEN✅ [进度]$NC 1/5 - 设备标识符生成完成"

        Write-Host "$BLUE⏳ [进度]$NC 2/5 - 创建备份目录..."

        # 备份原始值（增强版）
        $backupDir = "$env:APPDATA\Cursor\User\globalStorage\backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction Stop | Out-Null
        }

        $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $backupPath = "$backupDir\$backupName"

        Write-Host "$BLUE⏳ [进度]$NC 3/5 - 备份原始配置..."
        Copy-Item $configPath $backupPath -ErrorAction Stop

        # 验证备份是否成功
        if (Test-Path $backupPath) {
            $backupSize = (Get-Item $backupPath).Length
            $originalSize = (Get-Item $configPath).Length
            if ($backupSize -eq $originalSize) {
                Write-Host "$GREEN✅ [进度]$NC 3/5 - 配置备份成功: $backupName"
            } else {
                Write-Host "$YELLOW⚠️  [警告]$NC 备份文件大小不匹配，但继续执行"
            }
        } else {
            throw "备份文件创建失败"
        }

        Write-Host "$BLUE⏳ [进度]$NC 4/5 - 更新配置文件..."

        # 更新配置值
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # 保存修改后的配置
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configPath, $updatedJson, [System.Text.Encoding]::UTF8)

        Write-Host "$BLUE⏳ [进度]$NC 5/5 - 验证修改结果..."

        # 验证修改是否成功
        try {
            $verifyContent = Get-Content $configPath -Raw -Encoding UTF8
            $verifyConfig = $verifyContent | ConvertFrom-Json

            $verificationPassed = $true
            if ($verifyConfig.'telemetry.machineId' -ne $MACHINE_ID) { $verificationPassed = $false }
            if ($verifyConfig.'telemetry.macMachineId' -ne $MAC_MACHINE_ID) { $verificationPassed = $false }
            if ($verifyConfig.'telemetry.devDeviceId' -ne $UUID) { $verificationPassed = $false }
            if ($verifyConfig.'telemetry.sqmId' -ne $SQM_ID) { $verificationPassed = $false }

            if ($verificationPassed) {
                Write-Host "$GREEN✅ [进度]$NC 5/5 - 修改验证成功"
                Write-Host ""
                Write-Host "$GREEN🎉 [成功]$NC 机器码配置修改完成！"
                Write-Host "$BLUE📋 [详情]$NC 已更新以下标识符："
                Write-Host "   🔹 machineId: $($MACHINE_ID.Substring(0,20))..."
                Write-Host "   🔹 macMachineId: $MAC_MACHINE_ID"
                Write-Host "   🔹 devDeviceId: $UUID"
                Write-Host "   🔹 sqmId: $SQM_ID"
                Write-Host ""
                Write-Host "$GREEN💾 [备份]$NC 原配置已备份至: $backupName"
                return $true
            } else {
                Write-Host "$RED❌ [错误]$NC 修改验证失败，正在恢复备份..."
                Copy-Item $backupPath $configPath -Force
                return $false
            }
        } catch {
            Write-Host "$RED❌ [错误]$NC 验证过程出错: $($_.Exception.Message)"
            Write-Host "$BLUE🔄 [恢复]$NC 正在恢复备份..."
            Copy-Item $backupPath $configPath -Force
            return $false
        }

    } catch {
        Write-Host "$RED❌ [错误]$NC 修改配置失败: $($_.Exception.Message)"
        Write-Host "$BLUE💡 [调试信息]$NC 错误类型: $($_.Exception.GetType().FullName)"

        # 尝试恢复备份（如果存在）
        if ($backupPath -and (Test-Path $backupPath)) {
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

# 🚀 启动Cursor生成配置文件
function Start-CursorToGenerateConfig {
    Write-Host "$BLUE🚀 [启动]$NC 正在尝试启动Cursor生成配置文件..."

    # 查找Cursor可执行文件
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:PROGRAMFILES\Cursor\Cursor.exe",
        "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
    )

    $cursorPath = $null
    foreach ($path in $cursorPaths) {
        if (Test-Path $path) {
            $cursorPath = $path
            break
        }
    }

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
        $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
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
Write-Host "$YELLOW💰   [小小广告]  出售CursorPro教育号一年质保三个月，有需要找我(86)，WeChat：JavaRookie666  $NC"
Write-Host "$BLUE================================$NC"

# 🎯 用户选择菜单
Write-Host ""
Write-Host "$GREEN🎯 [选择模式]$NC 请选择您要执行的操作："
Write-Host ""
Write-Host "$BLUE  1️⃣  仅修改机器码$NC"
Write-Host "$YELLOW      • 仅执行机器码修改功能$NC"
Write-Host "$YELLOW      • 跳过文件夹删除/环境重置步骤$NC"
Write-Host "$YELLOW      • 保留现有Cursor配置和数据$NC"
Write-Host ""
Write-Host "$BLUE  2️⃣  重置环境+修改机器码$NC"
Write-Host "$RED      • 执行完全环境重置（删除Cursor文件夹）$NC"
Write-Host "$RED      • ⚠️  配置将丢失，请注意备份$NC"
Write-Host "$YELLOW      • 按照机器代码修改$NC"
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
        $cursorPaths = @(
            "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
            "$env:PROGRAMFILES\Cursor\Cursor.exe",
            "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
        )

        foreach ($path in $cursorPaths) {
            if (Test-Path $path) {
                $global:CursorProcessInfo = @{
                    ProcessName = "Cursor"
                    Path = $path
                    StartTime = $null
                }
                Write-Host "$GREEN💾 [发现]$NC 找到Cursor安装路径: $path"
                break
            }
        }

        if (-not $global:CursorProcessInfo) {
            Write-Host "$YELLOW⚠️  [警告]$NC 未找到Cursor安装路径，将使用默认路径"
            $global:CursorProcessInfo = @{
                ProcessName = "Cursor"
                Path = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"
                StartTime = $null
            }
        }
    }
}

# 🚀 根据用户选择执行相应功能
if ($executeMode -eq "MODIFY_ONLY") {
    Write-Host "$GREEN🚀 [开始]$NC 开始执行仅修改机器码功能..."

    # 先进行环境检查
    $envCheck = Test-CursorEnvironment -Mode "MODIFY_ONLY"
    if (-not $envCheck.Success) {
        Write-Host ""
        Write-Host "$RED❌ [环境检查失败]$NC 无法继续执行，发现以下问题："
        foreach ($issue in $envCheck.Issues) {
            Write-Host "$RED  • $issue$NC"
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
    if (Modify-MachineCodeConfig -Mode "MODIFY_ONLY") {
        Write-Host ""
        Write-Host "$GREEN🎉 [完成]$NC 机器码修改完成！"
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
    Modify-MachineCodeConfig
}

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