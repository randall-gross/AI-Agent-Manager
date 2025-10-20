# uninstall.ps1
# AI Agent Manager - Uninstall Script
# Removes generated files and configurations to allow clean re-installation
# Perfect for development QC and testing

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI Agent Manager - Uninstall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Change to script directory
Set-Location $scriptDir

Write-Host "This will remove:" -ForegroundColor Yellow
Write-Host "  - Generated configuration files" -ForegroundColor Yellow
Write-Host "  - OAuth credentials" -ForegroundColor Yellow
Write-Host "  - Log files" -ForegroundColor Yellow
Write-Host "  - Windows startup entry (if installed)" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will KEEP:" -ForegroundColor Green
Write-Host "  - All source code" -ForegroundColor Green
Write-Host "  - All templates" -ForegroundColor Green
Write-Host "  - All documentation" -ForegroundColor Green
Write-Host "  - Python packages (run 'pip uninstall' manually if needed)" -ForegroundColor Green
Write-Host ""
Write-Host "After uninstall, you can run setup.ps1 again for clean installation." -ForegroundColor Cyan
Write-Host ""

# Confirm with user
$confirmation = Read-Host "Continue with uninstall? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host ""
    Write-Host "Uninstall cancelled." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Starting uninstall..." -ForegroundColor Cyan
Write-Host ""

$removedCount = 0
$errorCount = 0

# Function to safely remove file
function Remove-SafeFile {
    param($FilePath, $Description)

    if (Test-Path $FilePath) {
        try {
            Remove-Item $FilePath -Force
            Write-Host "  ✅ Removed: $Description" -ForegroundColor Green
            return 1
        } catch {
            Write-Host "  ❌ Failed to remove: $Description" -ForegroundColor Red
            Write-Host "     Error: $_" -ForegroundColor Red
            return -1
        }
    } else {
        Write-Host "  ⏭️  Not found: $Description" -ForegroundColor Gray
        return 0
    }
}

# 1. Stop server if running
Write-Host "1. Checking for running server..." -ForegroundColor Cyan
$pythonProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like "*agent_server.py*" -or $_.CommandLine -like "*agent_server.py*"
}

if ($pythonProcesses) {
    Write-Host "   Found running server process(es). Stopping..." -ForegroundColor Yellow
    foreach ($proc in $pythonProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force
            Write-Host "  ✅ Stopped server process (PID: $($proc.Id))" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Could not stop process (PID: $($proc.Id))" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "  ⏭️  No server process found" -ForegroundColor Gray
}

Write-Host ""

# 2. Remove generated files
Write-Host "2. Removing generated files..." -ForegroundColor Cyan

$filesToRemove = @(
    @{Path="credentials.json"; Desc="OAuth credentials"},
    @{Path="config.json"; Desc="Server configuration"},
    @{Path="agent-server.log"; Desc="Server log file"},
    @{Path="GPT-CONFIG.txt"; Desc="GPT configuration output"},
    @{Path="ngrok.yml"; Desc="Ngrok configuration (if local)"},
    @{Path=".ngrok"; Desc="Ngrok cache directory (if exists)"}
)

foreach ($file in $filesToRemove) {
    $result = Remove-SafeFile -FilePath $file.Path -Description $file.Desc
    if ($result -eq 1) { $removedCount++ }
    if ($result -eq -1) { $errorCount++ }
}

Write-Host ""

# 3. Remove Windows startup entry
Write-Host "3. Removing Windows startup entry..." -ForegroundColor Cyan

try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $regName = "AIAgentServer"

    $exists = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue

    if ($exists) {
        Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop
        Write-Host "  ✅ Removed startup entry" -ForegroundColor Green
        $removedCount++
    } else {
        Write-Host "  ⏭️  Startup entry not found" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ Failed to remove startup entry: $_" -ForegroundColor Red
    $errorCount++
}

Write-Host ""

# 4. Ask about Google Drive folder
Write-Host "4. Google Drive folder..." -ForegroundColor Cyan
Write-Host ""
Write-Host "   Your 'AI Agents' folder in Google Drive contains your agent documents." -ForegroundColor White
Write-Host "   This uninstaller CANNOT delete it automatically (security by design)." -ForegroundColor White
Write-Host ""
Write-Host "   To delete it:" -ForegroundColor Yellow
Write-Host "   1. Go to: https://drive.google.com" -ForegroundColor Yellow
Write-Host "   2. Find the 'AI Agents' folder" -ForegroundColor Yellow
Write-Host "   3. Right-click → Delete" -ForegroundColor Yellow
Write-Host ""
$openDrive = Read-Host "   Open Google Drive now? (y/n)"

if ($openDrive -eq 'y') {
    Start-Process "https://drive.google.com"
    Write-Host "  ✅ Opened Google Drive in browser" -ForegroundColor Green
}

Write-Host ""

# 5. Clean up Python cache (optional)
Write-Host "5. Cleaning Python cache..." -ForegroundColor Cyan

$pycacheDirs = Get-ChildItem -Path $scriptDir -Filter "__pycache__" -Recurse -Directory -ErrorAction SilentlyContinue

if ($pycacheDirs) {
    foreach ($dir in $pycacheDirs) {
        try {
            Remove-Item $dir.FullName -Recurse -Force
            Write-Host "  ✅ Removed: $($dir.FullName)" -ForegroundColor Green
            $removedCount++
        } catch {
            Write-Host "  ⚠️  Could not remove: $($dir.FullName)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  ⏭️  No cache directories found" -ForegroundColor Gray
}

# Remove .pyc files
$pycFiles = Get-ChildItem -Path $scriptDir -Filter "*.pyc" -Recurse -ErrorAction SilentlyContinue

if ($pycFiles) {
    foreach ($file in $pycFiles) {
        try {
            Remove-Item $file.FullName -Force
            $removedCount++
        } catch {
            # Silent fail for .pyc files
        }
    }
    Write-Host "  ✅ Removed .pyc files" -ForegroundColor Green
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uninstall Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($removedCount -gt 0) {
    Write-Host "✅ Removed $removedCount item(s)" -ForegroundColor Green
}

if ($errorCount -gt 0) {
    Write-Host "⚠️  $errorCount error(s) occurred" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "What's Next:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To reinstall:" -ForegroundColor White
Write-Host "    1. Run: setup.ps1" -ForegroundColor White
Write-Host "    2. Follow setup prompts" -ForegroundColor White
Write-Host "    3. Server will be ready to use" -ForegroundColor White
Write-Host ""
Write-Host "  To completely remove:" -ForegroundColor White
Write-Host "    1. Delete this entire folder" -ForegroundColor White
Write-Host "    2. Delete 'AI Agents' from Google Drive (manually)" -ForegroundColor White
Write-Host "    3. Uninstall Python packages: pip uninstall -r requirements.txt" -ForegroundColor White
Write-Host ""

# Optional: Ask if user wants to uninstall Python packages
$uninstallPackages = Read-Host "Uninstall Python packages now? (y/n)"

if ($uninstallPackages -eq 'y') {
    Write-Host ""
    Write-Host "Uninstalling Python packages..." -ForegroundColor Cyan

    if (Test-Path "requirements.txt") {
        try {
            # Use pip to uninstall packages
            python -m pip uninstall -r requirements.txt -y
            Write-Host "✅ Python packages uninstalled" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to uninstall packages: $_" -ForegroundColor Red
            Write-Host "   Run manually: pip uninstall -r requirements.txt" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ requirements.txt not found" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "Uninstall script finished." -ForegroundColor Green
Write-Host ""

# Pause to let user read the output
Read-Host "Press Enter to exit"
