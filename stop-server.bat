@echo off
REM stop-server.bat - Stop AI Agent Manager server

title Stop AI Agent Manager

echo.
echo ========================================
echo   AI Agent Manager
echo   Stopping server...
echo ========================================
echo.

REM Find and kill Python processes running agent_server.py
for /f "tokens=2" %%a in ('tasklist ^| find "python"') do (
    taskkill /F /PID %%a >nul 2>&1
)

echo.
echo Server stopped
echo.
pause
