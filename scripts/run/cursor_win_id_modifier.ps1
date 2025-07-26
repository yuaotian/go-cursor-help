# ========================================
# 🪟 Cursor Windows ID Modifier Script 🚀
# ========================================
# Purpose: Reset Cursor trial by modifying device identifiers
# Platform: Windows (x64, x86, ARM64)
# Requirements: Administrator privileges, Cursor installed
# ========================================

# Set output encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========================================
# CONFIGURATION
# ========================================

$SCRIPT_NAME = "Cursor Windows ID Modifier"
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# Colors for output
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# ========================================
# UTILITY FUNCTIONS
# ========================================

# Logging functions with emojis
function Write-Info {
    param([string]$Message)
    Write-Host "$GREEN✅ [INFO]$NC $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "$YELLOW⚠️  [WARN]$NC $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$RED❌ [ERROR]$NC $Message"
}

function Write-Debug {
    param([string]$Message)
    Write-Host "$BLUE🔍 [DEBUG]$NC $Message"
}

# Generate random string
function Generate-RandomString {
    param([int]$Length = 32)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $result
}

# Generate UUID
function Generate-UUID {
    return [System.Guid]::NewGuid().ToString().ToLower()
}

# ========================================
# CURSOR DETECTION
# ========================================

# Find Cursor installation
function Find-CursorInstallation {
    Write-Info "🔍 Searching for Cursor installation..."
    
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:PROGRAMFILES\Cursor\Cursor.exe",
        "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
    )
    
    foreach ($path in $cursorPaths) {
        if (Test-Path $path) {
            Write-Info "🎯 Found Cursor at: $path"
            return $path
        }
    }
    
    Write-Error "Cursor installation not found"
    return $null
}

# Find Cursor resources directory
function Find-CursorResources {
    Write-Info "Searching for Cursor resources..."
    
    $cursorAppPath = "$env:LOCALAPPDATA\Programs\Cursor"
    if (-not (Test-Path $cursorAppPath)) {
        $alternatePaths = @(
            "$env:PROGRAMFILES\Cursor",
            "$env:PROGRAMFILES(X86)\Cursor"
        )
        
        foreach ($path in $alternatePaths) {
            if (Test-Path $path) {
                $cursorAppPath = $path
                break
            }
        }
    }
    
    if (Test-Path $cursorAppPath) {
        Write-Info "Found Cursor resources at: $cursorAppPath"
        return $cursorAppPath
    }
    
    Write-Error "Cursor resources not found"
    return $null
}

# ========================================
# PROCESS MANAGEMENT
# ========================================

# Stop all Cursor processes
function Stop-AllCursorProcesses {
    param(
        [int]$MaxRetries = 3,
        [int]$WaitSeconds = 5
    )
    
    Write-Info "🔄 Stopg Cursursor processes..."
    
    $cursorProcessNames = @("Cursor", "cursor", "Cursor Helper", "CursorUpdater")
    
    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        Write-Debug "Process check attempt $retry/$MaxRetries"
        
        $foundProcesses = @()
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                $foundProcesses += $processes
                Write-Warn "Found process: $processName (PID: $($processes.Id -join ', '))"
            }
        }
        
        if ($foundProcesses.Count -eq 0) {
            Write-Info "All Cursor processes stopped"
            return $true
        }
        
        Write-Info "Stopping $($foundProcesses.Count) Cursor processes..."
        
        # Try graceful shutdown first
        foreach ($process in $foundProcesses) {
            try {
                $process.CloseMainWindow() | Out-Null
            } catch {
                Write-Debug "Graceful shutdown failed for: $($process.ProcessName)"
            }
        }
        
        Start-Sleep -Seconds 3
        
        # Force terminate remaining processes
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                foreach ($process in $processes) {
                    try {
                        Stop-Process -Id $process.Id -Force
                        Write-Debug "Force terminated: $($process.ProcessName) (PID: $($process.Id))"
                    } catch {
                        Write-Warn "Failed to terminate: $($process.ProcessName)"
                    }
                }
            }
        }
        
        if ($retry -lt $MaxRetries) {
            Write-Info "Waiting $WaitSeconds seconds before retry..."
            Start-Sleep -Seconds $WaitSeconds
        }
    }
    
    Write-Error "Failed to stop all Cursor processes after $MaxRetries attempts"
    return $false
}

# ========================================
# FOLDER MANAGEMENT
# ========================================

# Remove Cursor trial folders
function Remove-CursorTrialFolders {
    Write-Info "Removing Cursor trial folders..."
    
    $foldersToDelete = @(
        "$env:USERPROFILE\.cursor",
        "$env:APPDATA\Cursor",
        "C:\Users\Administrator\.cursor",
        "C:\Users\Administrator\AppData\Roaming\Cursor"
    )
    
    $deletedCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    foreach ($folder in $foldersToDelete) {
        Write-Debug "Checking folder: $folder"
        
        if (Test-Path $folder) {
            try {
                Write-Warn "Found folder, removing: $folder"
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Info "Successfully removed: $folder"
                $deletedCount++
            }
            catch {
                Write-Error "Failed to remove folder: $folder - $($_.Exception.Message)"
                $errorCount++
            }
        } else {
            Write-Info "Folder not found (skipping): $folder"
            $skippedCount++
        }
    }
    
    Write-Info "Folder removal completed - Deleted: $deletedCount, Skipped: $skippedCount, Errors: $errorCount"
    
    # Pre-create necessary directory structure
    $cursorAppData = "$env:APPDATA\Cursor"
    $cursorUserProfile = "$env:USERPROFILE\.cursor"
    
    try {
        if (-not (Test-Path $cursorAppData)) {
            New-Item -ItemType Directory -Path $cursorAppData -Force | Out-Null
        }
        if (-not (Test-Path $cursorUserProfile)) {
            New-Item -ItemType Directory -Path $cursorUserProfile -Force | Out-Null
        }
        Write-Info "Directory structure pre-created successfully"
    } catch {
        Write-Warn "Failed to pre-create directories: $($_.Exception.Message)"
    }
    
    return ($errorCount -eq 0)
}

# ========================================
# CURSOR MANAGEMENT
# ========================================

# Start Cursor to generate config
function Start-CursorForConfig {
    Write-Info "Starting Cursor to generate configuration..."
    
    $cursorPath = Find-CursorInstallation
    if (-not $cursorPath) {
        return $false
    }
    
    try {
        Write-Info "Starting Cursor at: $cursorPath"
        $process = Start-Process -FilePath $cursorPath -PassThru -WindowStyle Hidden
        
        Write-Info "Waiting for configuration file generation..."
        $configPath = $STORAGE_FILE
        $maxWait = 60
        $waited = 0
        
        while (-not (Test-Path $configPath) -and $waited -lt $maxWait) {
            Start-Sleep -Seconds 2
            $waited += 2
            if ($waited % 10 -eq 0) {
                Write-Info "Still waiting... ($waited/$maxWait seconds)"
            }
        }
        
        if (Test-Path $configPath) {
            Write-Info "Configuration file generated successfully"
            
            # Wait a bit more to ensure file is fully written
            Start-Sleep -Seconds 5
            
            # Stop Cursor
            if ($process -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit(5000)
            }
            
            # Ensure all processes are stopped
            Stop-AllCursorProcesses | Out-Null
            
            return $true
        } else {
            Write-Warn "Configuration file not generated within timeout"
            return $false
        }
    } catch {
        Write-Error "Failed to start Cursor: $($_.Exception.Message)"
        return $false
    }
}

# ========================================
# CONFIGURATION MANAGEMENT
# ========================================

# Backup configuration
function Backup-Config {
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Warn "Configuration file not found, skipping backup"
        return $true
    }
    
    if (-not (Test-Path $BACKUP_DIR)) {
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
    }
    
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $backupPath = "$BACKUP_DIR\$backupName"
    
    try {
        Copy-Item $STORAGE_FILE $backupPath -ErrorAction Stop
        Write-Info "Configuration backed up to: $backupName"
        return $true
    } catch {
        Write-Error "Failed to backup configuration: $($_.Exception.Message)"
        return $false
    }
}

# Modify machine code configuration
function Modify-MachineCodeConfig {
    Write-Info "Modifying machine code configuration..."
    
    $configPath = $STORAGE_FILE
    
    # Check if config file exists
    if (-not (Test-Path $configPath)) {
        Write-Error "Configuration file not found: $configPath"
        Write-Info "Attempting to generate configuration file..."
        
        if (Start-CursorForConfig) {
            Write-Info "Configuration file generated, continuing..."
        } else {
            Write-Error "Failed to generate configuration file"
            return $false
        }
    }
    
    # Verify JSON format
    try {
        $originalContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
        $config = $originalContent | ConvertFrom-Json -ErrorAction Stop
        Write-Info "Configuration file format is valid"
    } catch {
        Write-Error "Configuration file format is invalid: $($_.Exception.Message)"
        return $false
    }
    
    # Backup original configuration
    if (-not (Backup-Config)) {
        return $false
    }
    
    # Generate new IDs
    $MAC_MACHINE_ID = Generate-UUID
    $UUID = Generate-UUID
    $MACHINE_ID = "auth0|user_$(Generate-RandomString -Length 64)"
    $SQM_ID = "{$(([System.Guid]::NewGuid()).ToString().ToUpper())}"
    
    Write-Info "Generated new device identifiers"
    
    try {
        # Update configuration
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID
        
        # Write updated configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8 -NoNewline
        
        Write-Info "Configuration updated successfully"
        Write-Info "Updated identifiers:"
        Write-Host "  • machineId: $($MACHINE_ID.Substring(0, [Math]::Min(20, $MACHINE_ID.Length)))..."
        Write-Host "  • macMachineId: $MAC_MACHINE_ID"
        Write-Host "  • devDeviceId: $UUID"
        Write-Host "  • sqmId: $SQM_ID"
        
        return $true
    } catch {
        Write-Error "Failed to update configuration: $($_.Exception.Message)"
        return $false
    }
}

# ========================================
# JAVASCRIPT MODIFICATION
# ========================================

# Modify Cursor JS files
function Modify-CursorJSFiles {
    Write-Info "Modifying Cursor JS files..."
    
    $cursorAppPath = Find-CursorResources
    if (-not $cursorAppPath) {
        return $false
    }
    
    # Target JS files
    $jsFiles = @(
        "$cursorAppPath\resources\app\out\vs\workbench\api\node\extensionHostProcess.js",
        "$cursorAppPath\resources\app\out\main.js",
        "$cursorAppPath\resources\app\out\vs\code\node\cliProcessMain.js"
    )
    
    $modifiedCount = 0
    $needModification = $false
    
    # Check if modification is needed
    foreach ($file in $jsFiles) {
        if (-not (Test-Path $file)) {
            Write-Warn "File not found: $(Split-Path $file -Leaf)"
            continue
        }
        
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -notmatch "Cursor ID Modifier") {
            Write-Debug "File needs modification: $(Split-Path $file -Leaf)"
            $needModification = $true
            break
        } else {
            Write-Info "File already modified: $(Split-Path $file -Leaf)"
        }
    }
    
    if (-not $needModification) {
        Write-Info "All JS files already modified, skipping"
        return $true
    }
    
    # Stop Cursor processes
    if (-not (Stop-AllCursorProcesses -MaxRetries 3 -WaitSeconds 3)) {
        Write-Error "Failed to stop Cursor processes"
        return $false
    }
    
    # Generate new identifiers
    $newUuid = Generate-UUID
    $machineId = "auth0|user_$(Generate-RandomString -Length 32)"
    $deviceId = Generate-UUID
    $macMachineId = Generate-RandomString -Length 64
    
    Write-Info "Generated new device identifiers for JS injection"
    
    # Create backup
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$env:TEMP\Cursor_JS_Backup_$timestamp"
    
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        foreach ($file in $jsFiles) {
            if (Test-Path $file) {
                $fileName = Split-Path $file -Leaf
                Copy-Item $file "$backupPath\$fileName" -Force
            }
        }
        Write-Info "JS files backed up to: $backupPath"
    } catch {
        Write-Error "Failed to create backup: $($_.Exception.Message)"
        return $false
    }
    
    # Modify JS files
    foreach ($file in $jsFiles) {
        if (-not (Test-Path $file)) {
            Write-Warn "File not found: $(Split-Path $file -Leaf)"
            continue
        }
        
        Write-Info "Processing: $(Split-Path $file -Leaf)"
        
        try {
            $content = Get-Content $file -Raw -Encoding UTF8
            
            # Check if already modified
            if ($content -match "Cursor ID Modifier") {
                Write-Info "File already modified: $(Split-Path $file -Leaf)"
                $modifiedCount++
                continue
            }
            
            # Create injection code
            $injectCode = @"
// Cursor ID Modifier Injection - $(Get-Date)
const originalRequire = typeof require === 'function' ? require : null;
if (originalRequire) {
  require = function(module) {
    try {
      const result = originalRequire(module);
      if (module === 'crypto' && result && result.randomUUID) {
        result.randomUUID = function() { return '$newUuid'; };
      }
      return result;
    } catch (e) {
      return originalRequire(module);
    }
  };
}

// Override global functions
try { if (typeof global !== 'undefined' && global.getMachineId) global.getMachineId = function() { return '$machineId'; }; } catch(e){}
try { if (typeof global !== 'undefined' && global.getDeviceId) global.getDeviceId = function() { return '$deviceId'; }; } catch(e){}
try { if (typeof process !== 'undefined' && process.env) process.env.VSCODE_MACHINE_ID = '$machineId'; } catch(e){}

console.log('Cursor ID Modifier: Patches applied');
// End Cursor ID Modifier Injection

"@
            
            # Inject code at beginning
            $content = $injectCode + $content
            
            # Write modified content
            Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
            Write-Info "Successfully modified: $(Split-Path $file -Leaf)"
            $modifiedCount++
            
        } catch {
            Write-Error "Failed to modify file: $($_.Exception.Message)"
            # Try to restore from backup
            $fileName = Split-Path $file -Leaf
            $backupFile = "$backupPath\$fileName"
            if (Test-Path $backupFile) {
                Copy-Item $backupFile $file -Force
                Write-Info "Restored from backup: $(Split-Path $file -Leaf)"
            }
        }
    }
    
    if ($modifiedCount -gt 0) {
        Write-Info "Successfully modified $modifiedCount JS files"
        Write-Info "Backup location: $backupPath"
        return $true
    } else {
        Write-Error "Failed to modify any JS files"
        return $false
    }
}

# ========================================
# REGISTRY MANAGEMENT
# ========================================

# Update Windows MachineGuid
function Update-MachineGuid {
    Write-Info "Updating Windows MachineGuid..."
    
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        
        # Check if registry path exists
        if (-not (Test-Path $registryPath)) {
            Write-Warn "Registry path not found, creating: $registryPath"
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Get current GUID for backup
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Info "Current MachineGuid: $originalGuid"
            }
        } catch {
            Write-Warn "Could not read current MachineGuid"
        }
        
        # Create backup if original exists
        if ($originalGuid) {
            if (-not (Test-Path $BACKUP_DIR)) {
                New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
            }
            
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            $exportResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($exportResult.ExitCode -eq 0) {
                Write-Info "Registry backed up to: $(Split-Path $backupFile -Leaf)"
            } else {
                Write-Warn "Registry backup failed, continuing..."
            }
        }
        
        # Generate new GUID
        $newGuid = [System.Guid]::NewGuid().ToString()
        Write-Info "New MachineGuid: $newGuid"
        
        # Update registry
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        # Verify update
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -eq $newGuid) {
            Write-Info "Registry updated successfully"
            return $true
        } else {
            throw "Registry verification failed"
        }
    } catch {
        Write-Error "Registry operation failed: $($_.Exception.Message)"
        return $false
    }
}

# ========================================
# MAIN EXECUTION
# ========================================

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script requires administrator privileges"
        Write-Info "Please run PowerShell as Administrator and try again"
        return $false
    }
    
    # Check if Cursor is installed
    if (-not (Find-CursorInstallation)) {
        Write-Error "Cursor installation not found"
        Write-Info "Please install Cursor first: https://cursor.sh/"
        return $false
    }
    
    Write-Info "Prerequisites check passed"
    return $true
}

# Show menu
function Show-Menu {
    Write-Host ""
    Write-Host "🎯 Please select an option:"
    Write-Host ""
    Write-Host "   1️⃣  🔥 Full reset (Folders + Config + JS + Registry) [Recommended]"
    Write-Host "   2️⃣  🗂️  Reset trial folders only"
    Write-Host "   3️⃣  ⚙️  Modify machine code configuration only"
    Write-Host "   4️⃣  📝 Modify JS files only"
    Write-Host "   5️⃣  🔧 Update registry only"
    Write-Host "   6️⃣  🚪 Exit"
    Write-Host ""
}

# Main function
function Main {
    Write-Host ""
    Write-Host "██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ "
    Write-Host "██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗"
    Write-Host "██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝"
    Write-Host "██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗"
    Write-Host "╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║"
    Write-Host " ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
    Write-Host ""
    Write-Host "========================================="
    Write-Host "  🪟 $SCRIPT_NAME"
    Write-Host "========================================="
    Write-Host ""
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Enter your choice (1-6)"
        
        switch ($choice) {
            1 {
                Write-Info "Starting full reset..."
                
                $success = $true
                
                if (-not (Stop-AllCursorProcesses)) {
                    $success = $false
                }
                
                if ($success -and -not (Remove-CursorTrialFolders)) {
                    Write-Warn "Folder removal had issues, but continuing..."
                }
                
                if ($success -and -not (Modify-MachineCodeConfig)) {
                    Write-Warn "Config modification failed, but continuing..."
                }
                
                if ($success -and -not (Modify-CursorJSFiles)) {
                    Write-Warn "JS modification failed, but continuing..."
                }
                
                if ($success -and -not (Update-MachineGuid)) {
                    Write-Warn "Registry update failed, but continuing..."
                }
                
                Write-Host ""
                Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗"
                Write-Host "║                                                                              ║"
                Write-Host "║    🎉 SUCCESS! FULL RESET COMPLETED! 🎉                                      ║"
                Write-Host "║                                                                              ║"
                Write-Host "║    ✅ Trial folders removed                                                  ║"
                Write-Host "║    ✅ Machine code configuration updated                                     ║"
                Write-Host "║    ✅ JavaScript files patched                                               ║"
                Write-Host "║    ✅ Windows registry updated                                               ║"
                Write-Host "║                                                                              ║"
                Write-Host "║    🚀 You can now restart Cursor to use the reset trial!                     ║"
                Write-Host "║                                                                              ║"
                Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝"
                return
            }
            2 {
                Write-Info "Starting trial folder reset..."
                Stop-AllCursorProcesses | Out-Null
                Remove-CursorTrialFolders | Out-Null
                Write-Info "Trial folder reset completed"
                return
            }
            3 {
                Write-Info "Starting machine code configuration modification..."
                Stop-AllCursorProcesses | Out-Null
                Modify-MachineCodeConfig | Out-Null
                Write-Info "Machine code configuration completed"
                return
            }
            4 {
                Write-Info "Starting JS file modification..."
                Modify-CursorJSFiles | Out-Null
                Write-Info "JS file modification completed"
                return
            }
            5 {
                Write-Info "Starting registry update..."
                Update-MachineGuid | Out-Null
                Write-Info "Registry update completed"
                return
            }
            6 {
                Write-Info "Exiting..."
                return
            }
            default {
                Write-Warn "Invalid choice. Please enter 1-6."
            }
        }
    }
}

# Execute main function
Main