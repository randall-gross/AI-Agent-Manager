@echo off
REM start-server.bat - Launch AI Agent Manager server

title AI Agent Manager

echo.
echo ========================================
echo   AI Agent Manager
echo   Starting server...
echo ========================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found
    echo Please install Python from https://python.org
    echo.
    pause
    exit /b 1
)

REM Check if required files exist
if not exist "credentials.json" (
    echo ERROR: credentials.json not found
    echo Please run setup.ps1 first
    echo.
    pause
    exit /b 1
)

if not exist "config.json" (
    echo ERROR: config.json not found
    echo Please run setup.ps1 first
    echo.
    pause
    exit /b 1
)

REM Start the server
python agent_server.py

REM If we get here, server stopped
echo.
echo Server stopped
pause
