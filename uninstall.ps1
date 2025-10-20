# uninstall.ps1
# AI Agent Manager - Uninstall Script
# Industry-standard uninstaller with tiered cleanup options
# Perfect for development QC, testing, and clean re-installation

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI Agent Manager - Uninstall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Change to script directory
Set-Location $scriptDir

# Display cleanup level options
Write-Host "Choose cleanup level:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] MINIMAL - Quick cleanup for testing" -ForegroundColor Green
Write-Host "      Removes: credentials, logs, generated configs" -ForegroundColor Gray
Write-Host "      Keeps: oauth_client.json, ngrok config, startup entry" -ForegroundColor Gray
Write-Host "      Use when: Testing setup changes, keeping configurations" -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] STANDARD - Normal uninstall (Recommended)" -ForegroundColor Yellow
Write-Host "      Removes: All generated files, logs, startup entry" -ForegroundColor Gray
Write-Host "      Keeps: oauth_client.json, ngrok config" -ForegroundColor Gray
Write-Host "      Use when: Reinstalling, want to keep OAuth/ngrok setup" -ForegroundColor Gray
Write-Host ""
Write-Host "  [3] FULL - Complete cleanup" -ForegroundColor Red
Write-Host "      Removes: EVERYTHING including OAuth config and ngrok" -ForegroundColor Gray
Write-Host "      Warning: Will need to reconfigure OAuth and ngrok" -ForegroundColor Gray
Write-Host "      Use when: Complete removal, switching accounts" -ForegroundColor Gray
Write-Host ""

# Get cleanup level
do {
    $cleanupLevel = Read-Host "Select cleanup level (1/2/3)"
} while ($cleanupLevel -notin @('1','2','3'))

Write-Host ""

# Display what will be removed based on selection
switch ($cleanupLevel) {
    '1' {
        Write-Host "MINIMAL CLEANUP - Will remove:" -ForegroundColor Green
        Write-Host "  - credentials.json (OAuth tokens)" -ForegroundColor Yellow
        Write-Host "  - credentials.json.encrypted (encrypted backup)" -ForegroundColor Yellow
        Write-Host "  - config.json (server configuration)" -ForegroundColor Yellow
        Write-Host "  - Log files" -ForegroundColor Yellow
        Write-Host "  - Python cache files" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "WILL KEEP:" -ForegroundColor Green
        Write-Host "  - oauth_client.json (for easy re-setup)" -ForegroundColor Gray
        Write-Host "  - ngrok configuration" -ForegroundColor Gray
        Write-Host "  - Windows startup entry" -ForegroundColor Gray
    }
    '2' {
        Write-Host "STANDARD CLEANUP - Will remove:" -ForegroundColor Yellow
        Write-Host "  - credentials.json (OAuth tokens)" -ForegroundColor Yellow
        Write-Host "  - credentials.json.encrypted (encrypted backup)" -ForegroundColor Yellow
        Write-Host "  - config.json (server configuration)" -ForegroundColor Yellow
        Write-Host "  - Log files" -ForegroundColor Yellow
        Write-Host "  - Windows startup entry" -ForegroundColor Yellow
        Write-Host "  - Python cache files" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "WILL KEEP:" -ForegroundColor Green
        Write-Host "  - oauth_client.json (for easy re-setup)" -ForegroundColor Gray
        Write-Host "  - ngrok configuration" -ForegroundColor Gray
    }
    '3' {
        Write-Host "FULL CLEANUP - Will remove:" -ForegroundColor Red
        Write-Host "  - credentials.json (OAuth tokens)" -ForegroundColor Yellow
        Write-Host "  - credentials.json.encrypted (encrypted backup)" -ForegroundColor Yellow
        Write-Host "  - oauth_client.json (OAuth client config)" -ForegroundColor Red
        Write-Host "  - config.json (server configuration)" -ForegroundColor Yellow
        Write-Host "  - Log files" -ForegroundColor Yellow
        Write-Host "  - Windows startup entry" -ForegroundColor Yellow
        Write-Host "  - ngrok authtoken (system-wide)" -ForegroundColor Red
        Write-Host "  - ngrok cache directory" -ForegroundColor Yellow
        Write-Host "  - Python cache files" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "WARNING: Removing oauth_client.json requires reconfiguring from template!" -ForegroundColor Red
        Write-Host "WARNING: Ngrok removal may affect other applications using ngrok!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "ALL LEVELS KEEP:" -ForegroundColor Cyan
Write-Host "  - All source code" -ForegroundColor Green
Write-Host "  - All templates" -ForegroundColor Green
Write-Host "  - All documentation" -ForegroundColor Green
Write-Host "  - Python packages (optional cleanup at end)" -ForegroundColor Green
Write-Host ""

# Confirm with user
$confirmation = Read-Host "Continue with cleanup level $cleanupLevel? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host ""
    Write-Host "Uninstall cancelled." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Starting cleanup..." -ForegroundColor Cyan
Write-Host ""

# Tracking variables
$removedCount = 0
$skippedCount = 0
$errorCount = 0
$removedItems = @()
$keptItems = @()

# Function to safely remove file
function Remove-SafeFile {
    param($FilePath, $Description, $ShouldRemove = $true)

    if (-not $ShouldRemove) {
        if (Test-Path $FilePath) {
            Write-Host "  [KEEP] $Description" -ForegroundColor Cyan
            $script:keptItems += $Description
            $script:skippedCount++
        }
        return 0
    }

    if (Test-Path $FilePath) {
        try {
            Remove-Item $FilePath -Force
            Write-Host "  [OK] Removed: $Description" -ForegroundColor Green
            $script:removedItems += $Description
            return 1
        } catch {
            Write-Host "  [ERROR] Failed to remove: $Description" -ForegroundColor Red
            Write-Host "          $_" -ForegroundColor Red
            return -1
        }
    } else {
        Write-Host "  [SKIP] Not found: $Description" -ForegroundColor Gray
        return 0
    }
}

# Function to safely remove directory
function Remove-SafeDirectory {
    param($DirPath, $Description, $ShouldRemove = $true)

    if (-not $ShouldRemove) {
        if (Test-Path $DirPath) {
            Write-Host "  [KEEP] $Description" -ForegroundColor Cyan
            $script:keptItems += $Description
            $script:skippedCount++
        }
        return 0
    }

    if (Test-Path $DirPath) {
        try {
            Remove-Item $DirPath -Recurse -Force
            Write-Host "  [OK] Removed: $Description" -ForegroundColor Green
            $script:removedItems += $Description
            return 1
        } catch {
            Write-Host "  [ERROR] Failed to remove: $Description" -ForegroundColor Red
            Write-Host "          $_" -ForegroundColor Red
            return -1
        }
    } else {
        Write-Host "  [SKIP] Not found: $Description" -ForegroundColor Gray
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
            Write-Host "  [OK] Stopped server process (PID: $($proc.Id))" -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Could not stop process (PID: $($proc.Id))" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "  [SKIP] No server process found" -ForegroundColor Gray
}

Write-Host ""

# 2. Remove generated files
Write-Host "2. Removing generated files..." -ForegroundColor Cyan

# Core files - removed in all levels
$result = Remove-SafeFile -FilePath "credentials.json" -Description "OAuth credentials"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeFile -FilePath "credentials.json.encrypted" -Description "Encrypted credentials backup"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeFile -FilePath "config.json" -Description "Server configuration"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeFile -FilePath "agent-server.log" -Description "Server log file"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeFile -FilePath "GPT-CONFIG.txt" -Description "GPT configuration output"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeFile -FilePath "ngrok.yml" -Description "Local ngrok configuration"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

$result = Remove-SafeDirectory -DirPath ".ngrok" -Description "Local ngrok cache directory"
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

# OAuth client config - only removed in FULL cleanup
$removeOAuthClient = ($cleanupLevel -eq '3')
$result = Remove-SafeFile -FilePath "oauth_client.json" -Description "OAuth client configuration" -ShouldRemove $removeOAuthClient
if ($result -eq 1) { $removedCount++ }
if ($result -eq -1) { $errorCount++ }

Write-Host ""

# 3. Remove Windows startup entry
Write-Host "3. Removing Windows startup entry..." -ForegroundColor Cyan

# Skip startup removal in MINIMAL mode
if ($cleanupLevel -eq '1') {
    Write-Host "  [KEEP] Windows startup entry (minimal cleanup)" -ForegroundColor Cyan
    $keptItems += "Windows startup entry"
    $skippedCount++
} else {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $regName = "AIAgentServer"

        $exists = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue

        if ($exists) {
            Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop
            Write-Host "  [OK] Removed startup entry" -ForegroundColor Green
            $removedItems += "Windows startup entry"
            $removedCount++
        } else {
            Write-Host "  [SKIP] Startup entry not found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [ERROR] Failed to remove startup entry: $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""

# 4. Remove ngrok system configuration (FULL cleanup only)
if ($cleanupLevel -eq '3') {
    Write-Host "4. Removing ngrok system configuration..." -ForegroundColor Cyan
    Write-Host "   WARNING: This will remove ngrok authtoken system-wide!" -ForegroundColor Red
    Write-Host "   Other applications using ngrok will be affected." -ForegroundColor Red
    Write-Host ""
    $confirmNgrok = Read-Host "   Proceed with ngrok removal? (y/n)"

    if ($confirmNgrok -eq 'y') {
        # Try to remove ngrok authtoken
        try {
            $ngrokOutput = & ngrok config check 2>&1
            if ($LASTEXITCODE -eq 0) {
                # Get ngrok config path
                $ngrokConfigPath = "$env:USERPROFILE\.ngrok2\ngrok.yml"
                $result = Remove-SafeFile -FilePath $ngrokConfigPath -Description "ngrok authtoken configuration"
                if ($result -eq 1) { $removedCount++ }
                if ($result -eq -1) { $errorCount++ }
            }
        } catch {
            Write-Host "  [WARN] Could not check ngrok configuration" -ForegroundColor Yellow
        }

        # Remove pyngrok cache
        $pyngrokCache = "$env:LOCALAPPDATA\pyngrok"
        $result = Remove-SafeDirectory -DirPath $pyngrokCache -Description "pyngrok cache directory"
        if ($result -eq 1) { $removedCount++ }
        if ($result -eq -1) { $errorCount++ }

        # Alternative pyngrok location
        $pyngrokCache2 = "$env:APPDATA\pyngrok"
        $result = Remove-SafeDirectory -DirPath $pyngrokCache2 -Description "pyngrok cache directory (alt)"
        if ($result -eq 1) { $removedCount++ }
        if ($result -eq -1) { $errorCount++ }
    } else {
        Write-Host "  [SKIP] Ngrok removal cancelled by user" -ForegroundColor Yellow
        $keptItems += "ngrok system configuration"
        $skippedCount++
    }
    Write-Host ""
} else {
    Write-Host "4. Ngrok configuration..." -ForegroundColor Cyan
    Write-Host "  [KEEP] ngrok system configuration (not in full cleanup mode)" -ForegroundColor Cyan
    $keptItems += "ngrok system configuration"
    $skippedCount++
    Write-Host ""
}

# 5. Google Drive folder
Write-Host "5. Google Drive folder..." -ForegroundColor Cyan
Write-Host ""
Write-Host "   Your 'AI Agents' folder in Google Drive contains your agent documents." -ForegroundColor White
Write-Host "   This uninstaller CANNOT delete it automatically (security by design)." -ForegroundColor White
Write-Host ""
Write-Host "   To delete it:" -ForegroundColor Yellow
Write-Host "   1. Go to: https://drive.google.com" -ForegroundColor Yellow
Write-Host "   2. Find the 'AI Agents' folder" -ForegroundColor Yellow
Write-Host "   3. Right-click -> Delete" -ForegroundColor Yellow
Write-Host ""
$openDrive = Read-Host "   Open Google Drive now? (y/n)"

if ($openDrive -eq 'y') {
    Start-Process "https://drive.google.com"
    Write-Host "  [OK] Opened Google Drive in browser" -ForegroundColor Green
}

Write-Host ""

# 6. Clean up Python cache
Write-Host "6. Cleaning Python cache..." -ForegroundColor Cyan

$pycacheDirs = Get-ChildItem -Path $scriptDir -Filter "__pycache__" -Recurse -Directory -ErrorAction SilentlyContinue

if ($pycacheDirs) {
    foreach ($dir in $pycacheDirs) {
        try {
            Remove-Item $dir.FullName -Recurse -Force
            Write-Host "  [OK] Removed: $($dir.Name)" -ForegroundColor Green
            $removedCount++
        } catch {
            Write-Host "  [WARN] Could not remove: $($dir.FullName)" -ForegroundColor Yellow
        }
    }
    $removedItems += "Python __pycache__ directories"
} else {
    Write-Host "  [SKIP] No cache directories found" -ForegroundColor Gray
}

# Remove .pyc files
$pycFiles = Get-ChildItem -Path $scriptDir -Filter "*.pyc" -Recurse -ErrorAction SilentlyContinue

if ($pycFiles) {
    $pycCount = 0
    foreach ($file in $pycFiles) {
        try {
            Remove-Item $file.FullName -Force
            $pycCount++
        } catch {
            # Silent fail for .pyc files
        }
    }
    if ($pycCount -gt 0) {
        Write-Host "  [OK] Removed $pycCount .pyc file(s)" -ForegroundColor Green
        $removedItems += ".pyc files ($pycCount files)"
        $removedCount++
    }
}

Write-Host ""

# ========================================
# SUMMARY
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Display cleanup level
$levelName = switch ($cleanupLevel) {
    '1' { 'MINIMAL' }
    '2' { 'STANDARD' }
    '3' { 'FULL' }
}
Write-Host "Cleanup Level: $levelName" -ForegroundColor Cyan
Write-Host ""

# Display statistics
if ($removedCount -gt 0) {
    Write-Host "REMOVED ($removedCount items):" -ForegroundColor Green
    foreach ($item in $removedItems) {
        Write-Host "  - $item" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($skippedCount -gt 0) {
    Write-Host "KEPT ($skippedCount items):" -ForegroundColor Cyan
    foreach ($item in $keptItems) {
        Write-Host "  - $item" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($errorCount -gt 0) {
    Write-Host "ERRORS ($errorCount items failed):" -ForegroundColor Red
    Write-Host "  Some items could not be removed. Check messages above." -ForegroundColor Yellow
    Write-Host ""
}

# ========================================
# NEXT STEPS
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($cleanupLevel) {
    '1' {
        Write-Host "MINIMAL cleanup complete. To test setup again:" -ForegroundColor Green
        Write-Host "  1. Run: .\setup.ps1" -ForegroundColor White
        Write-Host "  2. OAuth and ngrok already configured" -ForegroundColor White
        Write-Host "  3. Just provide credentials and you're ready" -ForegroundColor White
    }
    '2' {
        Write-Host "STANDARD cleanup complete. To reinstall:" -ForegroundColor Yellow
        Write-Host "  1. Run: .\setup.ps1" -ForegroundColor White
        Write-Host "  2. oauth_client.json preserved for easy setup" -ForegroundColor White
        Write-Host "  3. Provide credentials and ngrok token" -ForegroundColor White
        Write-Host "  4. Server will be ready to use" -ForegroundColor White
    }
    '3' {
        Write-Host "FULL cleanup complete. To reinstall from scratch:" -ForegroundColor Red
        Write-Host "  1. Copy oauth_client_template.json to oauth_client.json" -ForegroundColor White
        Write-Host "  2. Fill in your OAuth client details" -ForegroundColor White
        Write-Host "  3. Run: .\setup.ps1" -ForegroundColor White
        Write-Host "  4. Follow all setup prompts" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "To completely remove AI Agent Manager:" -ForegroundColor White
Write-Host "  1. Delete this entire folder" -ForegroundColor White
Write-Host "  2. Delete 'AI Agents' from Google Drive (manually)" -ForegroundColor White
Write-Host "  3. Optionally uninstall Python packages (see below)" -ForegroundColor White
Write-Host ""

# ========================================
# OPTIONAL: Python packages
# ========================================
$uninstallPackages = Read-Host "Uninstall Python packages now? (y/n)"

if ($uninstallPackages -eq 'y') {
    Write-Host ""
    Write-Host "Uninstalling Python packages..." -ForegroundColor Cyan

    if (Test-Path "requirements.txt") {
        try {
            # Use pip to uninstall packages
            python -m pip uninstall -r requirements.txt -y
            Write-Host "[OK] Python packages uninstalled" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to uninstall packages: $_" -ForegroundColor Red
            Write-Host "        Run manually: pip uninstall -r requirements.txt" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] requirements.txt not found" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Pause to let user read the output
Read-Host "Press Enter to exit"
