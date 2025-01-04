@echo off
setlocal EnableDelayedExpansion

:: Build optimization flags
set "OPTIMIZATION_FLAGS=-trimpath -ldflags=\"-s -w\""
set "BUILD_JOBS=4"

:: Messages / 消息
set "EN_MESSAGES[0]=Starting build process for version"
set "EN_MESSAGES[1]=Using optimization flags:"
set "EN_MESSAGES[2]=Cleaning old builds..."
set "EN_MESSAGES[3]=Cleanup completed"
set "EN_MESSAGES[4]=Starting builds for all platforms..."
set "EN_MESSAGES[5]=Building for"
set "EN_MESSAGES[6]=Build successful:"
set "EN_MESSAGES[7]=All builds completed!"

:: Colors
set "GREEN=[32m"
set "RED=[31m"
set "RESET=[0m"

:: Cleanup function
:cleanup
if exist "..\bin" (
    rd /s /q "..\bin"
    echo %GREEN%!EN_MESSAGES[3]!%RESET%
)
mkdir "..\bin" 2>nul

:: Build function with optimizations
:build
set "os=%~1"
set "arch=%~2"
set "ext="
if "%os%"=="windows" set "ext=.exe"

echo %GREEN%!EN_MESSAGES[5]! %os%/%arch%%RESET%

set "CGO_ENABLED=0"
set "GOOS=%os%"
set "GOARCH=%arch%"

start /b cmd /c "go build -trimpath -ldflags=\"-s -w\" -o ..\bin\%os%\%arch%\cursor-id-modifier%ext% -a -installsuffix cgo -mod=readonly ..\cmd\cursor-id-modifier"
exit /b 0

:: Main execution
echo %GREEN%!EN_MESSAGES[0]!%RESET%
echo %GREEN%!EN_MESSAGES[1]! %OPTIMIZATION_FLAGS%%RESET%

call :cleanup

echo %GREEN%!EN_MESSAGES[4]!%RESET%

:: Start builds in parallel
set "pending=0"
for %%o in (windows linux darwin) do (
    for %%a in (amd64 386) do (
        call :build %%o %%a
        set /a "pending+=1"
        if !pending! geq %BUILD_JOBS% (
            timeout /t 1 /nobreak >nul
            set "pending=0"
        )
    )
)

:: Wait for all builds to complete
:wait_builds
timeout /t 2 /nobreak >nul
tasklist /fi "IMAGENAME eq go.exe" 2>nul | find "go.exe" >nul
if not errorlevel 1 goto wait_builds

echo %GREEN%!EN_MESSAGES[7]!%RESET%