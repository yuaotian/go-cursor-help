# Check for admin rights and handle elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $isAdmin) {
    # Detect PowerShell version and path
    $pwshPath = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
        (Get-Command "pwsh").Source  # PowerShell 7+
    } elseif (Test-Path "$env:ProgramFiles\PowerShell\7\pwsh.exe") {
        "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    } else {
        "powershell.exe"  # Windows PowerShell
    }
    
    try {
        Write-Host "`nRequesting administrator privileges..." -ForegroundColor Cyan
        $scriptPath = $MyInvocation.MyCommand.Path
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process -FilePath $pwshPath -Verb RunAs -ArgumentList $argList -Wait
        exit
    }
    catch {
        Write-Host "`nError: Administrator privileges required" -ForegroundColor Red
        Write-Host "Please run this script from an Administrator PowerShell window" -ForegroundColor Yellow
        Write-Host "`nTo do this:" -ForegroundColor Cyan
        Write-Host "1. Press Win + X" -ForegroundColor White
        Write-Host "2. Click 'Windows Terminal (Admin)' or 'PowerShell (Admin)'" -ForegroundColor White
        Write-Host "3. Run the installation command again" -ForegroundColor White
        Write-Host "`nPress enter to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create temporary directory
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

# Cleanup function
function Cleanup {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir
    }
}

# Error handler
trap {
    Write-Host "Error: $_" -ForegroundColor Red
    Cleanup
    Write-Host "Press enter to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

# Detect system architecture
function Get-SystemArch {
    if ([Environment]::Is64BitOperatingSystem) {
        return "x86_64"
    } else {
        return "i386"
    }
}

# Download with progress
function Get-FileWithProgress {
    param (
        [string]$Url,
        [string]$OutputFile
    )
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        $webClient.DownloadFile($Url, $OutputFile)
        return $true
    }
    catch {
        Write-Host "Failed to download: $_" -ForegroundColor Red
        return $false
    }
}

# Main installation function
function Install-CursorModifier {
    Write-Host "Starting installation..." -ForegroundColor Cyan
    
    # Detect architecture
    $arch = Get-SystemArch
    Write-Host "Detected architecture: $arch" -ForegroundColor Green
    
    # Set installation directory
    $InstallDir = "$env:ProgramFiles\CursorModifier"
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    
    # Get latest release
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/yuaotian/go-cursor-help/releases/latest"
        Write-Host "Found latest release: $($latestRelease.tag_name)" -ForegroundColor Cyan
        
        # Look for Windows binary with our architecture
        $version = $latestRelease.tag_name.TrimStart('v')
        Write-Host "Version: $version" -ForegroundColor Cyan
        $possibleNames = @(
            "cursor-id-modifier_${version}_windows_x86_64.exe",
            "cursor-id-modifier_${version}_windows_$($arch).exe"
        )
        
        $asset = $null
        foreach ($name in $possibleNames) {
            Write-Host "Checking for asset: $name" -ForegroundColor Cyan
            $asset = $latestRelease.assets | Where-Object { $_.name -eq $name }
            if ($asset) {
                Write-Host "Found matching asset: $($asset.name)" -ForegroundColor Green
                break
            }
        }
        
        if (!$asset) {
            Write-Host "`nAvailable assets:" -ForegroundColor Yellow
            $latestRelease.assets | ForEach-Object { Write-Host "- $($_.name)" }
            throw "Could not find appropriate Windows binary for $arch architecture"
        }
        
        $downloadUrl = $asset.browser_download_url
    }
    catch {
        Write-Host "Failed to get latest release: $_" -ForegroundColor Red
        exit 1
    }
    
    # Download binary
    Write-Host "`nDownloading latest release..." -ForegroundColor Cyan
    $binaryPath = Join-Path $TmpDir "cursor-id-modifier.exe"
    
    if (!(Get-FileWithProgress -Url $downloadUrl -OutputFile $binaryPath)) {
        exit 1
    }
    
    # Install binary
    Write-Host "Installing..." -ForegroundColor Cyan
    try {
        Copy-Item -Path $binaryPath -Destination "$InstallDir\cursor-id-modifier.exe" -Force
        
        # Add to PATH if not already present
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$InstallDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "Machine")
        }
    }
    catch {
        Write-Host "Failed to install: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "Running cursor-id-modifier..." -ForegroundColor Cyan
    
    # Run the program
    try {
        & "$InstallDir\cursor-id-modifier.exe"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to run cursor-id-modifier" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "Failed to run cursor-id-modifier: $_" -ForegroundColor Red
        exit 1
    }
}

# Run installation
try {
    Install-CursorModifier
}
catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    Cleanup
    Write-Host "Press enter to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}
finally {
    Cleanup
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Press enter to exit..." -ForegroundColor Green
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}