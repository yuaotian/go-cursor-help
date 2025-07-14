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

# 新增 Cursor 初始化函数
function Cursor-初始化 {
    Write-Host "$GREEN[信息]$NC 正在执行 Cursor 初始化清理..."
    $BASE_PATH = "$env:APPDATA\Cursor\User"

    $filesToDelete = @(
        (Join-Path -Path $BASE_PATH -ChildPath "globalStorage\\state.vscdb"),
        (Join-Path -Path $BASE_PATH -ChildPath "globalStorage\\state.vscdb.backup")
    )
    
    $folderToCleanContents = Join-Path -Path $BASE_PATH -ChildPath "History"
    $folderToDeleteCompletely = Join-Path -Path $BASE_PATH -ChildPath "workspaceStorage"

    Write-Host "$BLUE[调试]$NC 基础路径: $BASE_PATH"

    # 删除指定文件
    foreach ($file in $filesToDelete) {
        Write-Host "$BLUE[调试]$NC 检查文件: $file"
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Host "$GREEN[成功]$NC 已删除文件: $file"
            }
            catch {
                Write-Host "$RED[错误]$NC 删除文件 $file 失败: $($_.Exception.Message)"
            }
        } else {
            Write-Host "$YELLOW[警告]$NC 文件不存在，跳过删除: $file"
        }
    }

    # 清空指定文件夹内容
    Write-Host "$BLUE[调试]$NC 检查待清空文件夹: $folderToCleanContents"
    if (Test-Path $folderToCleanContents) {
        try {
            # 获取子项进行删除，以避免删除 History 文件夹本身
            Get-ChildItem -Path $folderToCleanContents -Recurse | Remove-Item -Recurse -Force -ErrorAction Stop
            Write-Host "$GREEN[成功]$NC 已清空文件夹内容: $folderToCleanContents"
        }
        catch {
            Write-Host "$RED[错误]$NC 清空文件夹 $folderToCleanContents 内容失败: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW[警告]$NC 文件夹不存在，跳过清空: $folderToCleanContents"
    }

    # 删除指定文件夹及其内容
    Write-Host "$BLUE[调试]$NC 检查待删除文件夹: $folderToDeleteCompletely"
    if (Test-Path $folderToDeleteCompletely) {
        try {
            Remove-Item -Path $folderToDeleteCompletely -Recurse -Force -ErrorAction Stop
            Write-Host "$GREEN[成功]$NC 已删除文件夹: $folderToDeleteCompletely"
        }
        catch {
            Write-Host "$RED[错误]$NC 删除文件夹 $folderToDeleteCompletely 失败: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW[警告]$NC 文件夹不存在，跳过删除: $folderToDeleteCompletely"
    }

    Write-Host "$GREEN[信息]$NC Cursor 初始化清理完成。"
    Write-Host "" # 添加空行以改善输出格式
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
Write-Host "$GREEN   Cursor 设备ID 修改工具          $NC"
Write-Host "$YELLOW  关注公众号【煎饼果子卷AI】 $NC"
Write-Host "$YELLOW  一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  $NC"
Write-Host "$YELLOW  [重要提示] 本工具免费，如果对您有帮助，请关注公众号【煎饼果子卷AI】  $NC"
Write-Host ""
Write-Host "$YELLOW   [小小广告]  出售CursorPro教育号一年质保三个月，有需要找我(86)，WeChat：JavaRookie666  $NC"
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

Write-Host "$YELLOW[重要提示]$NC 最新的 1.0.x (以支持)"
Write-Host ""

# 检查并关闭 Cursor 进程
Write-Host "$GREEN[信息]$NC 检查 Cursor 进程..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[调试]$NC 正在获取 $processName 进程详细信息："
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# 定义最大重试次数和等待时间
$MAX_RETRIES = 5
$WAIT_TIME = 1

# 处理进程关闭
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[警告]$NC 发现 $processName 正在运行"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[警告]$NC 尝试关闭 $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[错误]$NC 在 $MAX_RETRIES 次尝试后仍无法关闭 $processName"
                Get-ProcessDetails $processName
                Write-Host "$RED[错误]$NC 请手动关闭进程后重试"
                Read-Host "按回车键退出"
                exit 1
            }
            Write-Host "$YELLOW[警告]$NC 等待进程关闭，尝试 $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[信息]$NC $processName 已成功关闭"
    }
}

# 关闭所有 Cursor 进程
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# 执行 Cursor 初始化清理
# Cursor-初始化

# 创建备份目录
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# 备份现有配置
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[信息]$NC 正在备份配置文件..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# 生成新的 ID
Write-Host "$GREEN[信息]$NC 正在生成新的 ID..."

# 在颜色定义后添加此函数
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

# 改进 ID 生成函数
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

# 在生成 ID 时使用新函数
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
# 将 auth0|user_ 转换为字节数组的十六进制
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
# 生成32字节(64个十六进制字符)的随机数作为 machineId 的随机部分
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# 在Update-MachineGuid函数前添加权限检查
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[错误]$NC 请使用管理员权限运行此脚本"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Update-MachineGuid {
    try {
        # 检查注册表路径是否存在，不存在则创建
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            Write-Host "$YELLOW[警告]$NC 注册表路径不存在: $registryPath，正在创建..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "$GREEN[信息]$NC 注册表路径创建成功"
        }

        # 获取当前的 MachineGuid，如果不存在则使用空字符串作为默认值
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Host "$GREEN[信息]$NC 当前注册表值："
                Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
                Write-Host "    MachineGuid    REG_SZ    $originalGuid"
            } else {
                Write-Host "$YELLOW[警告]$NC MachineGuid 值不存在，将创建新值"
            }
        } catch {
            Write-Host "$YELLOW[警告]$NC 获取 MachineGuid 失败: $($_.Exception.Message)"
        }

        # 创建备份目录（如果不存在）
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        # 创建备份文件（仅当原始值存在时）
        if ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($backupResult.ExitCode -eq 0) {
                Write-Host "$GREEN[信息]$NC 注册表项已备份到：$backupFile"
            } else {
                Write-Host "$YELLOW[警告]$NC 备份创建失败，继续执行..."
            }
        }

        # 生成新GUID
        $newGuid = [System.Guid]::NewGuid().ToString()

        # 更新或创建注册表值
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        # 验证更新
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "注册表验证失败：更新后的值 ($verifyGuid) 与预期值 ($newGuid) 不匹配"
        }

        Write-Host "$GREEN[信息]$NC 注册表更新成功："
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[错误]$NC 注册表操作失败：$($_.Exception.Message)"
        
        # 尝试恢复备份（如果存在）
        if (($backupFile -ne $null) -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[恢复]$NC 正在从备份恢复..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[恢复成功]$NC 已还原原始注册表值"
            } else {
                Write-Host "$RED[错误]$NC 恢复失败，请手动导入备份文件：$backupFile"
            }
        } else {
            Write-Host "$YELLOW[警告]$NC 未找到备份文件或备份创建失败，无法自动恢复"
        }
        return $false
    }
}

# 创建或更新配置文件
Write-Host "$GREEN[信息]$NC 正在更新配置..."

try {
    # 检查配置文件是否存在
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[错误]$NC 未找到配置文件: $STORAGE_FILE"
        Write-Host "$YELLOW[提示]$NC 请先安装并运行一次 Cursor 后再使用此脚本"
        Read-Host "按回车键退出"
        exit 1
    }

    # 读取现有配置文件
    try {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8
        
        # 将 JSON 字符串转换为 PowerShell 对象
        $config = $originalContent | ConvertFrom-Json 

        # 备份当前值
        $oldValues = @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        # 更新特定的值
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # 将更新后的对象转换回 JSON 并保存
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[信息]$NC 成功更新配置文件"
    } catch {
        # 如果出错，尝试恢复原始内容
        if ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE), 
                $originalContent, 
                [System.Text.Encoding]::UTF8
            )
        }
        throw "处理 JSON 失败: $_"
    }
    # 直接执行更新 MachineGuid，不再询问
    Update-MachineGuid
    # 显示结果
    Write-Host ""
    Write-Host "$GREEN[信息]$NC 已更新配置:"
    Write-Host "$BLUE[调试]$NC machineId: $MACHINE_ID"
    Write-Host "$BLUE[调试]$NC macMachineId: $MAC_MACHINE_ID"
    Write-Host "$BLUE[调试]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[调试]$NC sqmId: $SQM_ID"

    # 显示文件树结构
    Write-Host ""
    Write-Host "$GREEN[信息]$NC 文件结构:"
    Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
    Write-Host "├── globalStorage"
    Write-Host "│   ├── storage.json (已修改)"
    Write-Host "│   └── backups"

    # 列出备份文件
    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        foreach ($file in $backupFiles) {
            Write-Host "│       └── $($file.Name)"
        }
    } else {
        Write-Host "│       └── (空)"
    }

    # 显示公众号信息
    Write-Host ""
    Write-Host "$GREEN================================$NC"
    Write-Host "$YELLOW  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  $NC"
    Write-Host "$GREEN================================$NC"
    Write-Host ""
    Write-Host "$GREEN[信息]$NC 请重启 Cursor 以应用新的配置"
    Write-Host ""

    # 询问是否要禁用自动更新
    Write-Host ""
    Write-Host "$YELLOW[询问]$NC 是否要禁用 Cursor 自动更新功能？"
    Write-Host "0) 否 - 保持默认设置 (按回车键)"
    Write-Host "1) 是 - 禁用自动更新"
    $choice = Read-Host "请输入选项 (0)"

    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "$GREEN[信息]$NC 正在处理自动更新..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        # 定义手动设置教程
        function Show-ManualGuide {
            Write-Host ""
            Write-Host "$YELLOW[警告]$NC 自动设置失败,请尝试手动操作："
            Write-Host "$YELLOW手动禁用更新步骤：$NC"
            Write-Host "1. 以管理员身份打开 PowerShell"
            Write-Host "2. 复制粘贴以下命令："
            Write-Host "$BLUE命令1 - 删除现有目录（如果存在）：$NC"
            Write-Host "Remove-Item -Path `"$updaterPath`" -Force -Recurse -ErrorAction SilentlyContinue"
            Write-Host ""
            Write-Host "$BLUE命令2 - 创建阻止文件：$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Write-Host ""
            Write-Host "$BLUE命令3 - 设置只读属性：$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Value `$true"
            Write-Host ""
            Write-Host "$BLUE命令4 - 设置权限（可选）：$NC"
            Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Write-Host ""
            Write-Host "$YELLOW验证方法：$NC"
            Write-Host "1. 运行命令：Get-ItemProperty `"$updaterPath`""
            Write-Host "2. 确认 IsReadOnly 属性为 True"
            Write-Host "3. 运行命令：icacls `"$updaterPath`""
            Write-Host "4. 确认只有读取权限"
            Write-Host ""
            Write-Host "$YELLOW[提示]$NC 完成后请重启 Cursor"
        }

        try {
            # 检查cursor-updater是否存在
            if (Test-Path $updaterPath) {
                # 如果是文件,说明已经创建了阻止更新
                if ((Get-Item $updaterPath) -is [System.IO.FileInfo]) {
                    Write-Host "$GREEN[信息]$NC 已创建阻止更新文件,无需再次阻止"
                    return
                }
                # 如果是目录,尝试删除
                else {
                    try {
                        Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
                        Write-Host "$GREEN[信息]$NC 成功删除 cursor-updater 目录"
                    }
                    catch {
                        Write-Host "$RED[错误]$NC 删除 cursor-updater 目录失败"
                        Show-ManualGuide
                        return
                    }
                }
            }

            # 创建阻止文件
            try {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Stop | Out-Null
                Write-Host "$GREEN[信息]$NC 成功创建阻止文件"
            }
            catch {
                Write-Host "$RED[错误]$NC 创建阻止文件失败"
                Show-ManualGuide
                return
            }

            # 设置文件权限
            try {
                # 设置只读属性
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
                
                # 使用 icacls 设置权限
                $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                if ($result.ExitCode -ne 0) {
                    throw "icacls 命令失败"
                }
                
                Write-Host "$GREEN[信息]$NC 成功设置文件权限"
            }
            catch {
                Write-Host "$RED[错误]$NC 设置文件权限失败"
                Show-ManualGuide
                return
            }

            # 验证设置
            try {
                $fileInfo = Get-ItemProperty $updaterPath
                if (-not $fileInfo.IsReadOnly) {
                    Write-Host "$RED[错误]$NC 验证失败：文件权限设置可能未生效"
                    Show-ManualGuide
                    return
                }
            }
            catch {
                Write-Host "$RED[错误]$NC 验证设置失败"
                Show-ManualGuide
                return
            }

            Write-Host "$GREEN[信息]$NC 成功禁用自动更新"
        }
        catch {
            Write-Host "$RED[错误]$NC 发生未知错误: $_"
            Show-ManualGuide
        }
    }
    else {
        Write-Host "$GREEN[信息]$NC 保持默认设置，不进行更改"
    }

    # 保留有效的注册表更新
    Update-MachineGuid

} catch {
    Write-Host "$RED[错误]$NC 主要操作失败: $_"
    Write-Host "$YELLOW[尝试]$NC 使用备选方法..."
    
    try {
        # 备选方法：使用 Add-Content
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[信息]$NC 使用备选方法成功写入配置"
    } catch {
        Write-Host "$RED[错误]$NC 所有尝试都失败了"
        Write-Host "错误详情: $_"
        Write-Host "目标文件: $STORAGE_FILE"
        Write-Host "请确保您有足够的权限访问该文件"
        Read-Host "按回车键退出"
        exit 1
    }
}

Write-Host ""
Read-Host "按回车键退出"
exit 0

# 在文件写入部分修改
function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        # 使用 UTF8 无 BOM 编码
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        
        # 统一使用 LF 换行符
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[信息]$NC 成功写入配置文件(UTF8 无 BOM)"
    }
    catch {
        throw "写入配置文件失败: $_"
    }
} 