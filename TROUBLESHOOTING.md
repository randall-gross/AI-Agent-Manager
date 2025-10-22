# Troubleshooting Guide - AI Agent Manager

**Version:** 1.1.0
**Last Updated:** 2025-10-22

This guide covers common issues encountered during setup and daily use, with step-by-step solutions.

---

## Table of Contents

- [Setup Issues](#setup-issues)
  - [PowerShell Execution Policy Errors](#1-powershell-execution-policy-errors)
  - [File Blocked (Downloaded from Internet)](#2-file-blocked-downloaded-from-internet)
  - [Path with Spaces Issues](#3-path-with-spaces-issues)
  - [Python Not Found](#4-python-not-found)
  - [Windows Store Python Conflict](#5-windows-store-python-conflict)
  - [OAuth Authorization Failed](#6-oauth-authorization-failed)
  - [oauth_client.json Issues](#7-oauth_clientjson-issues)
- [Runtime Issues](#runtime-issues)
  - [Windows Defender / Antivirus Blocking Ngrok](#8-windows-defender--antivirus-blocking-ngrok-critical)
  - [Server Won't Start (Other Causes)](#9-server-wont-start-other-causes)
  - [401 Unauthorized Error](#10-401-unauthorized-error)
  - [ChatGPT Can't Connect](#11-chatgpt-cant-connect)
  - [No Agents Found](#12-no-agents-found)
  - [Ngrok URL Changed](#13-ngrok-url-changed)
- [Performance Issues](#performance-issues)
- [Network/Firewall Issues](#networkfirewall-issues)
- [Quick Diagnostic Commands](#quick-diagnostic-commands)

---

## Setup Issues

### 1. PowerShell Execution Policy Errors

**Symptom:**
```
.\setup.ps1 cannot be loaded because running scripts is disabled on this system.
CategoryInfo : SecurityError
FullyQualifiedErrorId : UnauthorizedAccess
```

**Cause:** Windows blocks PowerShell scripts by default for security.

**Solution:**

**Option A: Set Execution Policy (Recommended)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
When prompted, type `Y` and press Enter.

Then run setup:
```powershell
.\setup.ps1
```

**Option B: Bypass for Single Run**
```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup.ps1
```

**Option C: Check Current Policy**
```powershell
Get-ExecutionPolicy
```
If it shows "Restricted", use Option A above.

---

### 2. File Blocked (Downloaded from Internet)

**Symptom:**
```
.\setup.ps1 cannot be loaded. The file is not digitally signed.
You cannot run this script on the current system.
CategoryInfo : SecurityError
FullyQualifiedErrorId : UnauthorizedAccess
```

**Cause:** Windows marks files downloaded from the internet as "blocked" for security.

**Solution:**

**Option A: PowerShell Unblock (Fastest)**
```powershell
Unblock-File .\setup.ps1
```

Then run setup:
```powershell
.\setup.ps1
```

**Option B: GUI Unblock**
1. Open File Explorer
2. Navigate to the AI-Agent-Manager folder
3. Right-click `setup.ps1`
4. Select "Properties"
5. At the bottom, check the box **"Unblock"**
6. Click "Apply" → "OK"
7. Run setup again

**Option C: Bypass (If Unblock Doesn't Work)**
```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup.ps1
```

---

### 3. Path with Spaces Issues

**Symptom:**
```
cd C:\Users\Silicon computers\Documents\AI-Agent-Manager
Set-Location : A positional parameter cannot be found that accepts argument 'computers\Documents\...'
CategoryInfo : InvalidArgument
FullyQualifiedErrorId : PositionalParameterNotFound
```

**Cause:** PowerShell treats spaces as argument separators unless the path is quoted.

**Solution:**

**Always use QUOTES around paths with spaces:**

✅ **Correct:**
```powershell
cd "C:\Users\Silicon computers\Documents\AI-Agent-Manager"
```

❌ **Wrong:**
```powershell
cd C:\Users\Silicon computers\Documents\AI-Agent-Manager
```

**When running scripts:**
```powershell
& "C:\Users\Silicon computers\Documents\AI-Agent-Manager\setup.ps1"
```

---

### 4. Python Not Found

**Symptom:**
```
Python was not found; run without arguments to install from the Microsoft Store
ERROR: Failed to install packages
```

**Cause:** Python isn't installed, or it's not in the system PATH.

**Solution:**

### Step 1: Check if Python is Actually Installed

```powershell
# Try these commands
python --version
py --version
where python
where py
```

If **nothing works**, Python isn't installed properly.

### Step 2: Reinstall Python Correctly

1. **Uninstall existing Python** (if any):
   - Press `Win + I` → Apps → Installed apps
   - Find "Python 3.x" → Uninstall

2. **Download Python 3.11 or newer:**
   - Go to: https://www.python.org/downloads/
   - Download the latest stable version

3. **Install with correct settings:**
   - Run the installer
   - ⚠️ **CRITICAL:** Check **"Add Python to PATH"** at the bottom
   - Click "Install Now"
   - Wait for completion

4. **Restart PowerShell:**
   - **Close PowerShell completely**
   - **Open a NEW PowerShell window as Administrator**

5. **Verify installation:**
   ```powershell
   python --version
   ```
   Should show: `Python 3.13.x` or similar

6. **Run setup again:**
   ```powershell
   cd "C:\Path\To\AI-Agent-Manager"
   .\setup.ps1
   ```

### Step 3: If Python Version Shows But pip Doesn't Work

```powershell
# Upgrade pip
python -m pip install --upgrade pip

# Install dependencies manually
python -m pip install -r requirements.txt
```

---

### 5. Windows Store Python Conflict

**Symptom:**
```
Python was not found; run without arguments to install from the Microsoft Store
```
Even though you installed Python from python.org.

**Cause:** Windows 10/11 redirects the `python` command to Microsoft Store by default.

**Solution:**

### Disable Windows Store Python Alias

1. **Press** `Win + I` (opens Settings)
2. **Go to:** Apps → Apps & features → App execution aliases
3. **Scroll down** and find:
   - **"App Installer python.exe"** → Turn **OFF**
   - **"App Installer python3.exe"** → Turn **OFF**
4. **Click** back arrow to save
5. **Close Settings**
6. **Restart PowerShell**
7. **Try again:**
   ```powershell
   python --version
   ```

**Alternative: Use `py` launcher instead**

If the above doesn't work, use Python's `py` launcher:

```powershell
# Check if py works
py --version

# Use py for all commands
py -m pip install --upgrade pip
py -m pip install -r requirements.txt

# Run Python scripts with py
py init_drive.py
py agent_server.py
```

---

### 6. OAuth Authorization Failed

**Symptom:**
```
OAuth authorization failed
Error: access_denied
Error: invalid_grant
Browser opened but authorization failed
```

**Cause:** Email mismatch, missing test user, or wrong credentials.

**Solutions:**

### Issue 6A: Email Mismatch (Most Common)

**Problem:** The Gmail you selected during authorization doesn't match the test user you added in Google Cloud Console.

**Fix:**
1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Scroll to **"Test users"** section
3. Verify YOUR Gmail is listed
4. The email must **EXACTLY** match the Gmail you use to authorize
5. If your email isn't there, click **"ADD USERS"** → Enter your Gmail → **"ADD"**
6. Run setup again and use the **same Gmail** during authorization

### Issue 6B: Missing Test User

**Problem:** You didn't add yourself as a test user.

**Fix:**
1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Scroll to **"Test users"** section
3. Click **"ADD USERS"**
4. Enter your Gmail address
5. Click **"ADD"** → **"SAVE"**
6. Run setup again

### Issue 6C: Wrong OAuth Credentials

**Problem:** `oauth_client.json` has incorrect client_id or client_secret.

**Fix:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find your OAuth 2.0 Client ID
3. Click the name to view details
4. Copy the **Client ID** and **Client Secret**
5. Open `oauth_client.json` in Notepad
6. Replace `YOUR_CLIENT_ID` with actual Client ID
7. Replace `YOUR_CLIENT_SECRET` with actual Client Secret
8. Save the file
9. Run setup again

### Issue 6D: OAuth Consent Screen Not Published

**Problem:** OAuth consent screen is in "Testing" mode but expired.

**Fix:**
1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. If you see "PUBLISH APP" button, click it
3. OR ensure app status is "Testing" and you're added as test user
4. Run setup again

---

### 7. oauth_client.json Issues

**Symptom:**
```
oauth_client.json not found
oauth_client.json contains placeholder values
Invalid client_id or client_secret
```

**Cause:** The file doesn't exist, wasn't edited, or has wrong values.

**Solution:**

### Step 1: Verify File Exists

```powershell
# Check if file exists
Test-Path .\oauth_client.json

# View contents
Get-Content .\oauth_client.json
```

If file doesn't exist, download it from GitHub or create it manually.

### Step 2: Check for Placeholder Values

Open `oauth_client.json` - it should look like this:

```json
{
  "installed": {
    "client_id": "123456789-abc123def456.apps.googleusercontent.com",
    "client_secret": "GOCSPX-aBcDeFgHiJkLmNoPqRsTuVwXyZ",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
  }
}
```

**If you see this, it's WRONG (placeholders not replaced):**
```json
{
  "installed": {
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET",
    ...
  }
}
```

### Step 3: Get Real Credentials

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click **"CREATE CREDENTIALS"** → **"OAuth client ID"**
3. Application type: **"Desktop app"**
4. Name: "AI Agent Manager Desktop"
5. Click **"CREATE"**
6. **Copy Client ID and Client Secret**

### Step 4: Update oauth_client.json

1. Open `oauth_client.json` with Notepad
2. Replace `YOUR_CLIENT_ID` with your actual Client ID
3. Replace `YOUR_CLIENT_SECRET` with your actual Client Secret
4. Save the file
5. Run setup again

---

## Runtime Issues

### 8. Windows Defender / Antivirus Blocking Ngrok (CRITICAL)

**Symptom:**
```
OSError: [WinError 225] Operation did not complete successfully because
the file contains a virus or potentially unwanted software

Failed to start ngrok tunnel
Failed to read C:\Users\...\ngrok.yml
```

**When it happens:**
- During `start-server.bat`
- When running `python agent_server.py`
- After running setup successfully

**Cause:** Windows Defender or antivirus software incorrectly flags ngrok.exe as malware and quarantines/deletes it.

**Why ngrok is flagged:**
- Creates network tunnels (looks suspicious to antivirus)
- Used in penetration testing (legitimate security tool)
- Detects as "Trojan:Win32/Kepavi!!rfn" (FALSE POSITIVE)

**Ngrok is 100% SAFE** - used by millions of developers worldwide including companies like Microsoft, GitHub, and Stripe.

---

### Solution: Add Antivirus Exclusions and Restore File

### Step 1: Add Exclusions FIRST

**Before restoring the file, add exclusions so it won't be deleted again:**

1. **Press** `Win + I` (Settings)
2. Type **"virus"** in search
3. Click **"Virus & threat protection"**
4. Click **"Manage settings"**
5. Scroll down, click **"Add or remove exclusions"**
6. Add these **3 exclusions:**

**Exclusion 1: ngrok config folder**
- Click **"+ Add an exclusion"** → **"Folder"**
- Paste path:
  ```
  C:\Users\YOUR-USERNAME\.ngrok2
  ```
- Click **"Select Folder"**

**Exclusion 2: pyngrok package folder**
- Click **"+ Add an exclusion"** → **"Folder"**
- Paste path:
  ```
  C:\Users\YOUR-USERNAME\AppData\Local\Python\pythoncore-3.14-64\Lib\site-packages\pyngrok
  ```
  (Adjust Python version if different)
- Click **"Select Folder"**

**Exclusion 3: AI-Agent-Manager project folder**
- Click **"+ Add an exclusion"** → **"Folder"**
- Paste path to your project folder:
  ```
  C:\Path\To\AI-Agent-Manager
  ```
- Click **"Select Folder"**

### Step 2: Check Protection History

1. In Windows Security, click **"Protection history"**
2. Look for recent quarantined items
3. Find **"ngrok.exe"** or **"Trojan:Win32/Kepavi!!rfn"**
4. Note the date/time

### Step 3: Restore Quarantined File

**If ngrok.exe was quarantined:**

1. In Protection history, find the ngrok.exe entry
2. Click **"Actions"** dropdown
3. Click **"Restore"**
4. Click **"Allow on device"**
5. Confirm when prompted

**If you can't find it in quarantine, reinstall pyngrok:**

```powershell
# Uninstall
python -m pip uninstall pyngrok -y

# Reinstall (with exclusions added, won't be deleted)
python -m pip install pyngrok

# Configure token
python -c "import pyngrok.ngrok as ngrok; ngrok.set_auth_token('YOUR_NGROK_TOKEN')"
```

### Step 4: Verify ngrok.exe Exists

```powershell
# Check if ngrok.exe exists
Test-Path "$env:LOCALAPPDATA\Python\pythoncore-3.14-64\Lib\site-packages\pyngrok\bin\ngrok.exe"

# Or check via Python
python -c "import pyngrok; print(pyngrok.get_ngrok_bin())"
```

If file exists, proceed to Step 5.

### Step 5: Restart Computer (Recommended)

**Restart your computer** for exclusions to fully take effect.

After restart:
```powershell
cd "C:\Path\To\AI-Agent-Manager"
.\start-server.bat
```

### Step 6: Alternative - Disable Real-time Protection Temporarily

**ONLY FOR TESTING - Re-enable after!**

1. Windows Security → Virus & threat protection
2. Manage settings
3. Turn **OFF** "Real-time protection"
4. Run `.\start-server.bat`
5. If it works, you confirmed it was antivirus
6. Turn real-time protection **back ON**
7. Add permanent exclusions (Step 1)

---

### Third-Party Antivirus (McAfee, Norton, Avast, etc.)

**If using third-party antivirus:**

1. Open your antivirus software
2. Find "Exclusions", "Whitelist", or "Allow List" settings
3. Add these paths:
   - `C:\Users\YOUR-USERNAME\.ngrok2`
   - `C:\Users\YOUR-USERNAME\AppData\Local\Python\...\pyngrok`
   - Your AI-Agent-Manager project folder
4. Restore quarantined ngrok.exe from antivirus quarantine
5. Restart computer

---

### Common Antivirus Detection Names

Ngrok may be detected as:
- **Trojan:Win32/Kepavi!!rfn** (Windows Defender)
- **PUA:Win32/Ngrok** (Potentially Unwanted Application)
- **Riskware/Ngrok**
- **HackTool:Win32/Ngrok**

**All are FALSE POSITIVES.** Ngrok is legitimate software.

---

### Verification After Fix

After adding exclusions and restoring:

```powershell
# Test ngrok directly
ngrok version

# Should show: ngrok version 3.x.x

# Test via Python
python -c "import pyngrok.ngrok as ngrok; print(ngrok.get_version())"

# Start server
.\start-server.bat
```

**Should see:**
```
Server URL: https://abc123.ngrok-free.app
API Key: your-api-key-here
Server running...
```

---

### 9. Server Won't Start (Other Causes)

**Symptom:**
```
Server fails to start
Port already in use
Ngrok connection failed
```

**Note:** If you're getting WinError 225 or ngrok errors, see Issue #8 above (Antivirus Blocking Ngrok).

**Solutions:**

### Issue 9A: Port Already in Use

**Check if another instance is running:**
```powershell
# Check if port 3000 is in use
netstat -ano | findstr :3000

# Kill the process using the port
taskkill /PID <PID> /F
```

Replace `<PID>` with the Process ID from the netstat output.

**Or just run:**
```powershell
stop-server.bat
```

Then start again:
```powershell
start-server.bat
```

### Issue 8B: Python Packages Missing

```powershell
# Reinstall dependencies
python -m pip install -r requirements.txt

# Then start server
start-server.bat
```

### Issue 8C: Credentials File Missing

```powershell
# Check if encrypted credentials exist
dir credentials.json.encrypted

# If missing, re-run setup
.\setup.ps1
```

### Issue 8D: Ngrok Token Invalid

```powershell
# Re-authenticate with ngrok
ngrok authtoken YOUR_NGROK_TOKEN

# Get token from: https://dashboard.ngrok.com/get-started/your-authtoken
```

---

### 10. 401 Unauthorized Error

**Symptom:**
```
401 Unauthorized
Authentication failed
Bearer token required
```

**Cause:** API key is missing or incorrect in ChatGPT Actions.

**Solution:**

### Step 1: Find Your API Key

**Option A: From Server Console**
```
start-server.bat
```
Look for: `🔑 API KEY: your-api-key-here`

**Option B: From Config File**
```powershell
# View API key
Get-Content .\config.json | Select-String "api_key"
```

**Option C: From GPT-CONFIG.txt**
```powershell
Get-Content .\GPT-CONFIG.txt
```

### Step 2: Update ChatGPT Actions

1. Open ChatGPT: https://chat.openai.com
2. Go to "My GPTs" → Select your AI Agent Manager GPT
3. Click "Edit"
4. Go to "Configure" tab
5. Scroll to **"Actions"** section
6. Scroll to **"Authentication"** section
7. Find the field labeled **"Bearer Token"** or **"API Key"**
8. Paste your API key (from Step 1)
9. Click **"Save"**
10. Click **"Test"** to verify connection

### Step 3: Verify Connection

In the Actions panel, click **"Test"**. You should see:
```
✅ Connection successful
```

If you still see 401:
- Double-check API key (copy/paste exactly, no extra spaces)
- API key is case-sensitive
- Restart the server and try again

---

### 11. ChatGPT Can't Connect

**Symptom:**
```
Connection failed
Unable to reach server
Timeout error
```

**Solutions:**

### Issue 10A: Server Not Running

**Check if server is running:**
```powershell
# Look for Python process
tasklist | findstr python

# Check port 3000
netstat -ano | findstr :3000
```

**Start server:**
```powershell
start-server.bat
```

### Issue 10B: Wrong URL in ChatGPT Actions

**Get current URL:**
```powershell
# From GPT-CONFIG.txt
Get-Content .\GPT-CONFIG.txt
```

**Update ChatGPT:**
1. Copy the ngrok URL (looks like: `https://abc123-def.ngrok-free.app`)
2. Open your GPT → Edit → Configure → Actions
3. Find the line: `- url: https://...`
4. Replace with your current ngrok URL
5. Save

### Issue 10C: Windows Firewall Blocking

**Allow Python through firewall:**
1. Press `Win + I` → Update & Security → Windows Security
2. Click "Firewall & network protection"
3. Click "Allow an app through firewall"
4. Click "Change settings"
5. Find "Python" → Check both Private and Public
6. Click OK
7. Restart server

### Issue 10D: Ngrok Free Tier Limits

Free ngrok has limits:
- 1 online ngrok process at a time
- Connections may timeout after inactivity

**Fix:**
- Restart server
- Consider upgrading to ngrok paid ($8/month) for better reliability

---

### 12. No Agents Found

**Symptom:**
```
No agents found
Empty agent list
Google Drive folder missing
```

**Solutions:**

### Step 1: Verify Google Drive Structure

1. Open Google Drive: https://drive.google.com
2. Look for folder: **"AI Agents"**
3. Inside should be subfolder: **"agents"**
4. Inside "agents" should be 4 starter agents:
   - Agent Builder
   - Sales Email Writer
   - Technical Documentation
   - Customer Support

### Step 2: Reinitialize Drive Structure

If folder is missing or empty:

```powershell
# Recreate Google Drive structure
python init_drive.py
```

This will:
- Create "AI Agents" folder
- Create "agents" subfolder
- Create 4 starter agents
- Create Agent Registry

### Step 3: Check Credentials

```powershell
# Test credentials
python -c "from google.oauth2.credentials import Credentials; print('OK')"

# If error, re-run auth
python auth_setup.py
```

### Step 4: Check Server Logs

```powershell
# View last 50 lines of log
Get-Content .\agent-server.log -Tail 50
```

Look for Google API errors or authentication issues.

---

### 13. Ngrok URL Changed

**Symptom:**
```
URL from yesterday doesn't work
ChatGPT gets connection error after server restart
```

**Cause:** Free ngrok URLs change every time you restart the server.

**Solution:**

### Quick Fix (Free Ngrok)

**Every time you restart the server:**

1. Start server:
   ```powershell
   start-server.bat
   ```

2. Copy new URL from console:
   ```
   Server URL: https://NEW-URL-HERE.ngrok-free.app
   ```

3. Update ChatGPT Actions:
   - Open GPT → Edit → Configure → Actions
   - Find line: `- url: https://...`
   - Replace with NEW URL
   - Save

**Time:** ~30 seconds

### Permanent Fix (Paid Ngrok)

Upgrade to ngrok paid ($8/month) for static URL:

1. Go to: https://ngrok.com/pricing
2. Subscribe to paid plan
3. Configure static domain in ngrok dashboard
4. Update `start-server.bat` to use static domain
5. Update ChatGPT Actions **once**
6. URL never changes again

---

## Performance Issues

### Agents Load Slowly

**Symptom:** Loading agents takes 5-10 seconds or more.

**Causes & Solutions:**

### Issue A: Large Agent Documents

**Problem:** Agent documents are very large (>10KB).

**Fix:**
- Edit agents in Google Drive
- Remove unnecessary content
- Keep agents focused and concise
- Use examples sparingly

### Issue B: Many Agents in Folder

**Problem:** 50+ agents in the folder.

**Fix:**
- Archive old agents (move to different folder)
- Keep only active agents in "AI Agents/agents/"

### Issue C: Slow Internet Connection

**Problem:** Slow connection to Google Drive API.

**Fix:**
- Check internet speed
- Restart router/modem
- Try at different time of day
- Consider VPN if ISP throttling

**Normal behavior:** First agent load: 2-5 seconds (API call to Google Drive)

---

## Network/Firewall Issues

### Issue: Corporate Firewall Blocking

**Symptom:**
```
Cannot connect to Google APIs
Ngrok connection failed
Timeout errors
```

**Solutions:**

### For Google APIs
- Check firewall allows: `*.googleapis.com`
- Check ports: 443 (HTTPS) is open
- May need to whitelist Google API IPs
- Contact IT department

### For Ngrok
- Check firewall allows: `*.ngrok.io`, `*.ngrok-free.app`
- Check ports: 443 (HTTPS) is open
- May need to use ngrok with custom domain
- Contact IT department

### For Python pip
- Check firewall allows: `*.pypi.org`, `*.pythonhosted.org`
- If blocked, use alternate pip mirrors:
  ```powershell
  python -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt
  ```

---

## Quick Diagnostic Commands

Run these commands to diagnose issues:

```powershell
# System Information
Get-ComputerInfo | Select-Object WindowsVersion, OsArchitecture

# Python Installation
python --version
py --version
where python
where py

# Execution Policy
Get-ExecutionPolicy

# Check if files exist
Test-Path .\setup.ps1
Test-Path .\oauth_client.json
Test-Path .\credentials.json.encrypted
Test-Path .\config.json

# View API Key
Get-Content .\config.json | Select-String "api_key"

# View Server URL
Get-Content .\GPT-CONFIG.txt

# Check if server is running
tasklist | findstr python
netstat -ano | findstr :3000

# View recent logs
Get-Content .\agent-server.log -Tail 50

# Test Google Drive connection
python -c "from googleapiclient.discovery import build; print('Google API OK')"

# Test ngrok
ngrok version

# Check PATH
$env:PATH -split ';' | Select-String -Pattern 'Python'
```

---

## Still Having Issues?

### Check the Logs

```powershell
# View full log
Get-Content .\agent-server.log

# View only errors
Get-Content .\agent-server.log | Select-String -Pattern "ERROR"

# Watch log in real-time (while server runs)
Get-Content .\agent-server.log -Wait -Tail 20
```

### Run Test Script

```powershell
python test_server.py
```

This will diagnose:
- Python installation
- Dependencies
- Google API connection
- Configuration files
- Server functionality

### Get Help

**Documentation:**
- README.md - Complete overview
- QUICK-START.md - Quick setup guide
- GPT-SETUP-GUIDE.md - ChatGPT configuration
- SECURITY-UPGRADE-NOTES.md - Security features

**Community:**
- GitHub Issues: https://github.com/randall-gross/AI-Agent-Manager/issues
- Include in your issue:
  - Operating System version
  - Python version
  - Error messages (full text)
  - Output of diagnostic commands above
  - What you've already tried

---

## Preventive Measures

**Before Running Setup:**
- [ ] Python 3.11+ installed with "Add to PATH" checked
- [ ] PowerShell execution policy set to RemoteSigned
- [ ] oauth_client.json configured with real credentials
- [ ] Test user added in Google Cloud Console
- [ ] Internet connection is stable
- [ ] No VPN interfering with connections

**Best Practices:**
- Restart PowerShell after installing Python
- Close and reopen PowerShell after changing PATH
- Use quotes around paths with spaces
- Keep API keys secure (don't share GPT-CONFIG.txt)
- Backup oauth_client.json before editing
- Check agent-server.log regularly for errors

---

**Last Updated:** 2025-10-22 | **Version:** 1.1.0
