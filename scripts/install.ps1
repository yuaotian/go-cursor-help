# Set execution policy and TLS protocol
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -Wait
    exit $LASTEXITCODE
}

# Initialize paths
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
$InstallDir = "$env:ProgramFiles\CursorModifier"

# Create directories
New-Item -ItemType Directory -Force -Path $TmpDir, $InstallDir | Out-Null

# Cleanup function
function Cleanup {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}

try {
    Write-Host "Starting installation..." -ForegroundColor Cyan
    
    # Verify system requirements
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "This tool only supports 64-bit Windows"
    }
    
    # Get latest release info
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/yuaotian/go-cursor-help/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -like "cursor-id-modifier_Windows_x86_64*" } | Select-Object -First 1
    
    if (-not $asset) {
        throw "No compatible binary found"
    }
    
    Write-Host "Downloading version $($release.tag_name)..." -ForegroundColor Cyan
    
    # Download and install
    $zipPath = Join-Path $TmpDir "cursor-id-modifier.zip"
    (New-Object Net.WebClient).DownloadFile($asset.browser_download_url, $zipPath)
    
    Expand-Archive -Path $zipPath -DestinationPath $TmpDir -Force
    Copy-Item -Path (Join-Path $TmpDir "cursor-id-modifier.exe") -Destination $InstallDir -Force
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "Machine")
    }
    
    Write-Host "Installation complete!" -ForegroundColor Green
    
    # Run program
    $process = Start-Process -FilePath "$InstallDir\cursor-id-modifier.exe" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Program execution failed"
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
finally {
    Cleanup
}