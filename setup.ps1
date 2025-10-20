# setup.ps1
# One-time setup script for AI Agent Manager
# Run this once to configure everything

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI Agent Manager - Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  Found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Python not found" -ForegroundColor Red
    Write-Host "  Please install Python 3.11+ from https://python.org" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Python version
$versionMatch = $pythonVersion -match "Python (\d+)\.(\d+)"
if ($versionMatch) {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]

    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 11)) {
        Write-Host "  ERROR: Python 3.11 or newer required" -ForegroundColor Red
        Write-Host "  Found: Python $major.$minor" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""

# Install Python packages
Write-Host "Installing Python packages..." -ForegroundColor Yellow
Write-Host "  (This may take a few minutes)" -ForegroundColor Gray
Write-Host ""

$pipInstall = python -m pip install -r requirements.txt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to install packages" -ForegroundColor Red
    Write-Host "  Try running: python -m pip install --upgrade pip" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Packages installed successfully" -ForegroundColor Green
Write-Host ""

# Pre-download ngrok binary (better UX - avoids delay after token entry)
Write-Host "Preparing ngrok..." -ForegroundColor Yellow
Write-Host "  (Downloading ngrok binary if needed - first time only)" -ForegroundColor Gray

$ngrokPrep = python -c "from pyngrok import ngrok; import sys; sys.stdout.reconfigure(encoding='utf-8'); print('ready')" 2>&1
if ($ngrokPrep -notmatch "ready") {
    Write-Host "  First-time setup: Downloading ngrok..." -ForegroundColor Gray
    Write-Host "  This may take a minute..." -ForegroundColor Gray
}

Write-Host "  Ngrok binary ready" -ForegroundColor Green
Write-Host ""

# Ngrok setup
Write-Host "Ngrok Configuration" -ForegroundColor Yellow
Write-Host "  Ngrok creates a secure tunnel so ChatGPT can reach your local server" -ForegroundColor Gray
Write-Host ""
Write-Host "  Step 1: Sign up for free ngrok account" -ForegroundColor White
Write-Host "          Visit: https://dashboard.ngrok.com/signup" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Step 2: Get your authtoken" -ForegroundColor White
Write-Host "          After signing up, copy your authtoken from:" -ForegroundColor Gray
Write-Host "          https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor Cyan
Write-Host ""

# Open ngrok signup in browser
$openBrowser = Read-Host "Open ngrok signup page in browser? (Y/n)"
if ($openBrowser -ne "n") {
    Start-Process "https://dashboard.ngrok.com/signup"
    Write-Host "  Browser opened. Create account and get authtoken" -ForegroundColor Green
}

Write-Host ""
$ngrokToken = Read-Host "Paste your ngrok authtoken here"

if ([string]::IsNullOrWhiteSpace($ngrokToken)) {
    Write-Host "  ERROR: Authtoken is required" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "  Configuring ngrok..." -ForegroundColor Yellow

$ngrokConfig = python -c "from pyngrok import ngrok; ngrok.set_auth_token('$ngrokToken'); print('success')" 2>&1
if ($ngrokConfig -notmatch "success") {
    Write-Host "  ERROR: Failed to configure ngrok" -ForegroundColor Red
    Write-Host "  Token may be invalid" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Ngrok configured successfully" -ForegroundColor Green
Write-Host ""

# Check for oauth_client.json
Write-Host "Checking OAuth client configuration..." -ForegroundColor Yellow

if (!(Test-Path "oauth_client.json")) {
    Write-Host ""
    Write-Host "  ERROR: oauth_client.json not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "  You need to create oauth_client.json with your Google Cloud credentials." -ForegroundColor White
    Write-Host ""
    Write-Host "  Steps:" -ForegroundColor White
    Write-Host "    1. Copy oauth_client.json.template to oauth_client.json" -ForegroundColor Cyan
    Write-Host "    2. Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor Cyan
    Write-Host "    3. Create OAuth 2.0 Client ID (Desktop app)" -ForegroundColor Cyan
    Write-Host "    4. Download credentials and copy values to oauth_client.json" -ForegroundColor Cyan
    Write-Host ""

    $copyTemplate = Read-Host "Copy template file now? (Y/n)"
    if ($copyTemplate -ne "n") {
        Copy-Item "oauth_client.json.template" "oauth_client.json"
        Write-Host "  Template copied to oauth_client.json" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Now edit oauth_client.json with your credentials and run setup again." -ForegroundColor Yellow
    }
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Validate oauth_client.json
$oauthContent = Get-Content "oauth_client.json" -Raw
if ($oauthContent -match "YOUR_CLIENT_ID") {
    Write-Host ""
    Write-Host "  ERROR: oauth_client.json contains placeholder values" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please edit oauth_client.json and replace the placeholder values" -ForegroundColor Yellow
    Write-Host "  with your actual Google Cloud OAuth credentials." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Get credentials from: https://console.cloud.google.com/apis/credentials" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  oauth_client.json found and validated" -ForegroundColor Green
Write-Host ""

# CRITICAL: Test User Requirement Warning
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  IMPORTANT: Test User Setup Required" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Before continuing, you MUST add yourself as a test user in Google Cloud Console." -ForegroundColor White
Write-Host "Without this, you'll get an 'Access blocked: verification process' error!" -ForegroundColor Red
Write-Host ""
Write-Host "Steps to add test user:" -ForegroundColor White
Write-Host "  1. Go to: https://console.cloud.google.com/apis/credentials/consent" -ForegroundColor Cyan
Write-Host "  2. Scroll down to 'Test users' section" -ForegroundColor Cyan
Write-Host "  3. Click 'ADD USERS' button" -ForegroundColor Cyan
Write-Host "  4. Enter the EXACT Gmail you'll use to authorize" -ForegroundColor Cyan
Write-Host "     (e.g., yourname@gmail.com)" -ForegroundColor Gray
Write-Host "  5. Click 'ADD' then 'SAVE'" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: The test user email MUST match the Gmail you select in the browser!" -ForegroundColor Yellow
Write-Host ""

$testUserConfirm = Read-Host "Have you added your Gmail as a test user? (Y/n)"
if ($testUserConfirm -eq "n") {
    Write-Host ""
    Write-Host "  Please add yourself as a test user first, then run setup again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Google OAuth setup
Write-Host "Google Drive Authorization" -ForegroundColor Yellow
Write-Host "  A browser will open for you to authorize Google Drive access" -ForegroundColor Gray
Write-Host "  This lets the app store your agents as Google Docs" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to start authorization"

python auth_setup.py
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  ERROR: Google authorization failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Most common causes:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. EMAIL MISMATCH - Test user email doesn't match Gmail used" -ForegroundColor White
    Write-Host "   - Check: https://console.cloud.google.com/apis/credentials/consent" -ForegroundColor Cyan
    Write-Host "   - Make sure YOUR Gmail is listed under 'Test users'" -ForegroundColor Cyan
    Write-Host "   - The email must EXACTLY match the Gmail you selected" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. MISSING TEST USER - You didn't add yourself as a test user" -ForegroundColor White
    Write-Host "   - Go to: https://console.cloud.google.com/apis/credentials/consent" -ForegroundColor Cyan
    Write-Host "   - Scroll to 'Test users' section" -ForegroundColor Cyan
    Write-Host "   - Click 'ADD USERS' and add your Gmail" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. WRONG OAUTH CREDENTIALS - Check oauth_client.json" -ForegroundColor White
    Write-Host "   - Make sure client_id and client_secret are correct" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If you see 'Access blocked' or '403: access_denied':" -ForegroundColor Red
    Write-Host "  This is almost always a test user issue!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please fix the issue above and run setup again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Initialize Google Drive structure
Write-Host "Creating Google Drive structure..." -ForegroundColor Yellow
Write-Host ""

python init_drive.py
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  ERROR: Failed to create Drive structure" -ForegroundColor Red
    Write-Host "  Check error above for details" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Test the setup
Write-Host "Testing configuration..." -ForegroundColor Yellow
Write-Host ""

# Quick test - check if files exist
$filesOk = $true
$requiredFiles = @('credentials.json', 'config.json')

foreach ($file in $requiredFiles) {
    if (!(Test-Path $file)) {
        Write-Host "  ERROR: $file not found" -ForegroundColor Red
        $filesOk = $false
    }
}

if (!$filesOk) {
    Write-Host ""
    Write-Host "  Setup incomplete - missing required files" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  All configuration files created" -ForegroundColor Green
Write-Host ""

# Success!
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Double-click: start-server.bat" -ForegroundColor Cyan
Write-Host "  2. Copy the URL it shows" -ForegroundColor Cyan
Write-Host "  3. Follow GPT-SETUP-GUIDE.md to configure ChatGPT" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your AI Agents are in Google Drive:" -ForegroundColor White

# Get Drive URL from config
if (Test-Path "config.json") {
    $config = Get-Content "config.json" | ConvertFrom-Json
    $folderUrl = "https://drive.google.com/drive/folders/" + $config.main_folder_id
    Write-Host "  $folderUrl" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "TIP: Use the 'Agent Builder' agent when creating new agents!" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
