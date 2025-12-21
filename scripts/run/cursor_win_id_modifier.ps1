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

# 🔧 修改Cursor内核JS文件实现设备识别绕过（增强版 Hook 方案）
# 方案A: someValue占位符替换 - 稳定锚点，不依赖混淆后的函数名
# 方案B: 深度 Hook 注入 - 从底层拦截所有设备标识符生成
# 方案C: Module.prototype.require 劫持 - 拦截 child_process, crypto, os 等模块
function Modify-CursorJSFiles {
    Write-Host ""
    Write-Host "$BLUE🔧 [内核修改]$NC 开始修改Cursor内核JS文件实现设备识别绕过..."
    Write-Host "$BLUE💡 [方案]$NC 使用增强版 Hook 方案：深度模块劫持 + someValue替换"
    Write-Host ""

    # Windows版Cursor应用路径
    $cursorAppPath = "${env:LOCALAPPDATA}\Programs\Cursor"
    if (-not (Test-Path $cursorAppPath)) {
        # 尝试其他可能的安装路径
        $alternatePaths = @(
            "${env:ProgramFiles}\Cursor",
            "${env:ProgramFiles(x86)}\Cursor",
            "${env:USERPROFILE}\AppData\Local\Programs\Cursor"
        )

        foreach ($path in $alternatePaths) {
            if (Test-Path $path) {
                $cursorAppPath = $path
                break
            }
        }

        if (-not (Test-Path $cursorAppPath)) {
            Write-Host "$RED❌ [错误]$NC 未找到Cursor应用安装路径"
            Write-Host "$YELLOW💡 [提示]$NC 请确认Cursor已正确安装"
            return $false
        }
    }

    Write-Host "$GREEN✅ [发现]$NC 找到Cursor安装路径: $cursorAppPath"

    # 生成新的设备标识符（使用固定格式确保兼容性）
    $newUuid = [System.Guid]::NewGuid().ToString().ToLower()
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
    $sessionId = [System.Guid]::NewGuid().ToString().ToLower()
    $macAddress = "00:11:22:33:44:55"

    Write-Host "$GREEN🔑 [生成]$NC 已生成新的设备标识符"
    Write-Host "   machineId: $($machineId.Substring(0,16))..."
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
        macMachineId = $macMachineId
        devDeviceId = $deviceId
        sqmId = $sqmId
        macAddress = $macAddress
        createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    $idsConfig | ConvertTo-Json | Set-Content -Path $idsConfigPath -Encoding UTF8
    Write-Host "$GREEN💾 [保存]$NC 新的 ID 配置已保存到: $idsConfigPath"

    # 目标JS文件列表（Windows路径，按优先级排序）
    $jsFiles = @(
        "$cursorAppPath\resources\app\out\main.js"
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
    Write-Host "$BLUE🔧 [修改]$NC 开始修改JS文件（使用新的设备标识符）..."

    foreach ($file in $jsFiles) {
        if (-not (Test-Path $file)) {
            Write-Host "$YELLOW⚠️  [跳过]$NC 文件不存在: $(Split-Path $file -Leaf)"
            continue
        }

        Write-Host "$BLUE📝 [处理]$NC 正在处理: $(Split-Path $file -Leaf)"

        try {
            $content = Get-Content $file -Raw -Encoding UTF8
            $replaced = $false

            # ========== 方法A: someValue占位符替换（稳定锚点） ==========
            # 这些字符串是固定的占位符，不会被混淆器修改，跨版本稳定

            # 替换 someValue.machineId
            if ($content -match 'someValue\.machineId') {
                $content = $content -replace 'someValue\.machineId', "`"$machineId`""
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.machineId"
                $replaced = $true
            }

            # 替换 someValue.macMachineId
            if ($content -match 'someValue\.macMachineId') {
                $content = $content -replace 'someValue\.macMachineId', "`"$macMachineId`""
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.macMachineId"
                $replaced = $true
            }

            # 替换 someValue.devDeviceId
            if ($content -match 'someValue\.devDeviceId') {
                $content = $content -replace 'someValue\.devDeviceId', "`"$deviceId`""
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.devDeviceId"
                $replaced = $true
            }

            # 替换 someValue.sqmId
            if ($content -match 'someValue\.sqmId') {
                $content = $content -replace 'someValue\.sqmId', "`"$sqmId`""
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.sqmId"
                $replaced = $true
            }

            # 替换 someValue.sessionId（新增锚点）
            if ($content -match 'someValue\.sessionId') {
                $content = $content -replace 'someValue\.sessionId', "`"$sessionId`""
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.sessionId"
                $replaced = $true
            }

            # 🔧 新增: 替换 someValue.firstSessionDate
            $firstSessionDateValue = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            if ($content -match 'someValue\.firstSessionDate') {
                $content = $content -replace 'someValue\.firstSessionDate', $firstSessionDateValue
                Write-Host "   $GREEN✓$NC [方案A] 替换 someValue.firstSessionDate"
                $replaced = $true
            }

            # ========== 方法B: 增强版深度 Hook 注入 ==========
            # 从底层拦截所有设备标识符的生成：
            # 1. Module.prototype.require 劫持 - 拦截 child_process, crypto, os 等模块
            # 2. child_process.execSync - 拦截 REG.exe 查询 MachineGuid
            # 3. crypto.createHash - 拦截 SHA256 哈希计算
            # 4. crypto.randomUUID - 拦截 UUID 生成
            # 5. os.networkInterfaces - 拦截 MAC 地址获取
            # 6. @vscode/deviceid - 拦截 devDeviceId 获取
            # 7. @vscode/windows-registry - 拦截注册表读取

            $injectCode = @"
// ========== Cursor Hook 注入开始 ==========
;(function(){/*__cursor_patched__*/
'use strict';
if(globalThis.__cursor_patched__)return;
globalThis.__cursor_patched__=true;

// 固定的设备标识符
var __ids__={
    machineId:'$machineId',
    macMachineId:'$macMachineId',
    devDeviceId:'$deviceId',
    sqmId:'$sqmId',
    macAddress:'$macAddress'
};

// 暴露到全局
globalThis.__cursor_ids__=__ids__;

// Hook Module.prototype.require
var Module=require('module');
var _origReq=Module.prototype.require;
var _hooked=new Map();

Module.prototype.require=function(id){
    var result=_origReq.apply(this,arguments);
    if(_hooked.has(id))return _hooked.get(id);
    var hooked=result;

    // Hook child_process
    if(id==='child_process'){
        var _origExecSync=result.execSync;
        result.execSync=function(cmd,opts){
            var cmdStr=String(cmd).toLowerCase();
            if(cmdStr.includes('reg')&&cmdStr.includes('machineguid')){
                return Buffer.from('\r\n    MachineGuid    REG_SZ    '+__ids__.machineId.substring(0,36)+'\r\n');
            }
            if(cmdStr.includes('ioreg')&&cmdStr.includes('ioplatformexpertdevice')){
                return Buffer.from('"IOPlatformUUID" = "'+__ids__.machineId.substring(0,36).toUpperCase()+'"');
            }
            return _origExecSync.apply(this,arguments);
        };
        hooked=result;
    }
    // Hook os
    else if(id==='os'){
        var _origNI=result.networkInterfaces;
        result.networkInterfaces=function(){
            return{'Ethernet':[{address:'192.168.1.100',netmask:'255.255.255.0',family:'IPv4',mac:__ids__.macAddress,internal:false}]};
        };
        hooked=result;
    }
    // Hook crypto
    else if(id==='crypto'){
        var _origCreateHash=result.createHash;
        var _origRandomUUID=result.randomUUID;
        result.createHash=function(algo){
            var hash=_origCreateHash.apply(this,arguments);
            if(algo.toLowerCase()==='sha256'){
                var _origDigest=hash.digest.bind(hash);
                var _origUpdate=hash.update.bind(hash);
                var inputData='';
                hash.update=function(data,enc){inputData+=String(data);return _origUpdate(data,enc);};
                hash.digest=function(enc){
                    if(inputData.includes('MachineGuid')||inputData.includes('IOPlatformUUID')||(inputData.length>=32&&inputData.length<=40)){
                        return enc==='hex'?__ids__.machineId:Buffer.from(__ids__.machineId,'hex');
                    }
                    return _origDigest(enc);
                };
            }
            return hash;
        };
        if(_origRandomUUID){
            var uuidCount=0;
            result.randomUUID=function(){
                uuidCount++;
                if(uuidCount<=2)return __ids__.devDeviceId;
                return _origRandomUUID.apply(this,arguments);
            };
        }
        hooked=result;
    }
    // Hook @vscode/deviceid
    else if(id==='@vscode/deviceid'){
        hooked={...result,getDeviceId:async function(){return __ids__.devDeviceId;}};
    }
    // Hook @vscode/windows-registry
    else if(id==='@vscode/windows-registry'){
        var _origGetReg=result.GetStringRegKey;
        hooked={...result,GetStringRegKey:function(hive,path,name){
            if(name==='MachineId'||path.includes('SQMClient'))return __ids__.sqmId;
            if(name==='MachineGuid'||path.includes('Cryptography'))return __ids__.machineId.substring(0,36);
            return _origGetReg?_origGetReg.apply(this,arguments):'';
        }};
    }

    if(hooked!==result)_hooked.set(id,hooked);
    return hooked;
};

console.log('[Cursor ID Modifier] 增强版 Hook 已激活 - 煎饼果子(86) 公众号【煎饼果子卷AI】');
})();
// ========== Cursor Hook 注入结束 ==========

"@

            # 找到版权声明结束位置并在其后注入
            if ($content -match '(\*/\s*\n)') {
                $content = $content -replace '(\*/\s*\n)', "`$1$injectCode"
                Write-Host "   $GREEN✓$NC [方案B] 增强版 Hook 代码已注入（版权声明后）"
            } else {
                # 如果没有找到版权声明，则注入到文件开头
                $content = $injectCode + $content
                Write-Host "   $GREEN✓$NC [方案B] 增强版 Hook 代码已注入（文件开头）"
            }

            # 写入修改后的内容
            Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline

            if ($replaced) {
                Write-Host "$GREEN✅ [成功]$NC 增强版混合方案修改成功（someValue替换 + 深度Hook）"
            } else {
                Write-Host "$GREEN✅ [成功]$NC 增强版 Hook 修改成功"
            }
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
        Write-Host "$BLUE💡 [说明]$NC 使用增强版 Hook 方案："
        Write-Host "   • 方案A: someValue占位符替换（稳定锚点，跨版本兼容）"
        Write-Host "   • 方案B: 深度模块劫持（child_process, crypto, os, @vscode/*）"
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
    $BASE_PATH = "$env:APPDATA\Cursor\User"

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

# 检查配置文件和环境
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
            # 🔧 新增: firstSessionDate (重置首次会话日期)
            $FIRST_SESSION_DATE = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

            Write-Host "$GREEN✅ [进度]$NC 1/7 - 设备标识符生成完成"

            Write-Host "$BLUE⏳ [进度]$NC 2/7 - 创建备份目录..."

            # 备份原始值（增强版）
            $backupDir = "$env:APPDATA\Cursor\User\globalStorage\backups"
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
            $tempContent = Get-Content $tempPath -Raw -Encoding UTF8
            $tempConfig = $tempContent | ConvertFrom-Json

            # 验证所有属性是否正确写入
            $tempVerificationPassed = $true
            foreach ($property in $propertiesToUpdate.GetEnumerator()) {
                $key = $property.Key
                $expectedValue = $property.Value
                $actualValue = $tempConfig.$key

                if ($actualValue -ne $expectedValue) {
                    $tempVerificationPassed = $false
                    Write-Host "$RED  ✗ 临时文件验证失败: ${key}$NC"
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

            $verifyContent = Get-Content $configPath -Raw -Encoding UTF8
            $verifyConfig = $verifyContent | ConvertFrom-Json

            $verificationPassed = $true
            $verificationResults = @()

            # 安全验证每个属性
            foreach ($property in $propertiesToUpdate.GetEnumerator()) {
                $key = $property.Key
                $expectedValue = $property.Value
                $actualValue = $verifyConfig.$key

                if ($actualValue -eq $expectedValue) {
                    $verificationResults += "✓ ${key}: 验证通过"
                } else {
                    $verificationResults += "✗ ${key}: 验证失败 (期望: ${expectedValue}, 实际: ${actualValue})"
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
                $machineIdFilePath = "$env:APPDATA\Cursor\machineid"
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

                # 🔧 新增: 修改 .updaterId 文件（更新器设备标识符）
                Write-Host "$BLUE🔧 [updaterId]$NC 正在修改 .updaterId 文件..."
                $updaterIdFilePath = "$env:APPDATA\Cursor\.updaterId"
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
Write-Host "$YELLOW⚡  [小小广告] Cursor官网正规成品号：Pro¥65 | Pro+¥265 | Ultra¥888 独享账号/7天质保，WeChat：JavaRookie666  $NC"
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

# �️ 确保备份目录存在
if (-not (Test-Path $BACKUP_DIR)) {
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
                $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
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
                $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
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
                $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
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
                $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
                $configFile = Get-Item $configPath
                $configFile.IsReadOnly = $true
                Write-Host "$GREEN✅ [保护]$NC 配置文件已设置为只读，防止Cursor覆盖修改"
                Write-Host "$BLUE💡 [提示]$NC 文件路径: $configPath"
            } catch {
                Write-Host "$YELLOW⚠️  [保护]$NC 设置只读属性失败: $($_.Exception.Message)"
                Write-Host "$BLUE💡 [建议]$NC 可手动右键文件 → 属性 → 勾选'只读'"
            }
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
Write-Host "$GREEN================================$NC"
Write-Host ""

# 🎉 脚本执行完成
Write-Host "$GREEN🎉 [脚本完成]$NC 感谢使用 Cursor 机器码修改工具！"
Write-Host "$BLUE💡 [提示]$NC 如有问题请参考公众号或重新运行脚本"
Write-Host ""
Read-Host "按回车键退出"
exit 0
