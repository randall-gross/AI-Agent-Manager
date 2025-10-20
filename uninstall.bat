@echo off
REM AI Agent Manager - Uninstall (Batch Wrapper)
REM Double-click this file to uninstall

echo.
echo ========================================
echo   AI Agent Manager - Uninstall
echo ========================================
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"

REM Check if PowerShell failed
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to run uninstall script
    echo.
    echo Try running uninstall.ps1 directly:
    echo   Right-click uninstall.ps1 ^> Run with PowerShell
    echo.
    pause
    exit /b 1
)

exit /b 0
