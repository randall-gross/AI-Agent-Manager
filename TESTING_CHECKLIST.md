# Testing Checklist - Bug Fixes Validation

**Purpose**: Verify the credential decryption fix and UX improvements work correctly on the actual system.

---

## Pre-Test Cleanup

Before testing, clean up any files from the broken setup:

```powershell
# Navigate to project directory
cd "C:\Users\tekk7\Desktop\ChatGPT Agents\AI-Agent-Manager"

# Remove any existing credential files (they were created with broken code)
Remove-Item credentials.json -ErrorAction SilentlyContinue
Remove-Item credentials.json.encrypted -ErrorAction SilentlyContinue

# Remove config file (will be regenerated)
Remove-Item config.json -ErrorAction SilentlyContinue

# Clean slate - ready to test the fixed code
```

---

## Test 1: OAuth Client Validation UX

**What we're testing**: The improved error message for oauth_client.json validation.

### Steps:
1. Make sure `oauth_client.json` exists and has valid credentials
2. Run setup:
   ```powershell
   .\setup.ps1
   ```

### Expected Results:
- ✅ Python version check passes
- ✅ Package installation succeeds
- ✅ Ngrok configuration succeeds
- ✅ oauth_client.json validation passes (no error about placeholder values)

### If oauth_client.json has placeholders:
- ✅ Should show: "Press Enter to continue after fixing oauth_client.json"
- ✅ NOT: "Press Enter to exit" (which is confusing)

**Status**: [ ] PASS / [ ] FAIL

---

## Test 2: OAuth Authorization & Credential Encryption

**What we're testing**: The OAuth flow and credential encryption (auth_setup.py).

### Steps:
1. Continue from Test 1 or re-run `.\setup.ps1`
2. When prompted, complete OAuth authorization in browser
3. Grant permissions when asked

### Expected Results:
- ✅ Browser opens to Google OAuth consent screen
- ✅ After authorizing, see: "Authorization successful!"
- ✅ See: "Encrypted credentials saved to credentials.json.encrypted"
- ✅ File `credentials.json.encrypted` exists
- ✅ File `credentials.json.encrypted` is NOT empty (should be ~200-500 bytes)

**Status**: [ ] PASS / [ ] FAIL

---

## Test 3: CRITICAL - Credential Decryption (init_drive.py)

**What we're testing**: The FIXED decrypt_credentials() function in init_drive.py.

### Steps:
1. After successful OAuth authorization, setup continues automatically
2. Watch the output for "Creating Google Drive structure..."

### Expected Results:
- ✅ See: "📦 Loading encrypted credentials..."
- ✅ See: "✅ Encrypted credentials loaded successfully"
- ✅ See: "📁 Creating folder structure in Google Drive..."
- ✅ See: "✅ Created main folder: AI Agents"
- ✅ See: "✅ Created agents folder"
- ✅ See: "📄 Creating agent registry..."
- ✅ See: "🤖 Creating starter agents..."
- ✅ See: "✅ Drive setup complete!"

### CRITICAL - Must NOT see:
- ❌ "Failed to decrypt credentials: 'str' object has no attribute 'decode'"
- ❌ "ERROR: Failed to load credentials"
- ❌ Any credential-related errors

### Verification:
```powershell
# Check that config.json was created
Test-Path config.json
# Should return: True

# Check config contains required fields
Get-Content config.json | ConvertFrom-Json | Select agent_folder_id, registry_doc_id
# Should show Google Drive IDs (long alphanumeric strings)
```

**Status**: [ ] PASS / [ ] FAIL

**If FAILED**:
- Check the exact error message
- Verify Python version: `python --version` (should be 3.11+)
- Verify win32crypt is installed: `python -c "import win32crypt; print('OK')"`
- Check BUGFIX_REPORT.md for troubleshooting

---

## Test 4: Server Startup with Encrypted Credentials

**What we're testing**: The FIXED decrypt_credentials() function in agent_server.py.

### Steps:
1. After setup completes, start the server:
   ```powershell
   .\start-server.bat
   ```

### Expected Results:
- ✅ See: "Starting AI Agent Manager..."
- ✅ See: "Loading encrypted credentials..."
- ✅ See: "✅ Encrypted credentials loaded successfully"
- ✅ See: "✅ Google API services initialized"
- ✅ See: "Starting ngrok tunnel..."
- ✅ See: "✅ Ngrok tunnel started: https://..."
- ✅ See server banner with API key
- ✅ See: "Server running on: http://localhost:3000"

### CRITICAL - Must NOT see:
- ❌ "Failed to decrypt credentials: 'str' object has no attribute 'decode'"
- ❌ "Failed to initialize services"
- ❌ Any credential-related errors

### Verification:
```powershell
# In another PowerShell window, test the health endpoint
# (Replace NGROK_URL and API_KEY with actual values from server output)

$apiKey = "YOUR_API_KEY_FROM_SERVER"
$ngrokUrl = "YOUR_NGROK_URL_FROM_SERVER"

$headers = @{
    "Authorization" = "Bearer $apiKey"
}

Invoke-RestMethod -Uri "$ngrokUrl/health" -Headers $headers
# Should return JSON with status: "healthy"
```

**Status**: [ ] PASS / [ ] FAIL

---

## Test 5: End-to-End Validation

**What we're testing**: Complete functionality after the fixes.

### Steps:
1. Open Google Drive in browser
2. Navigate to "AI Agents" folder
3. Verify folder structure

### Expected Results:
- ✅ "AI Agents" folder exists
- ✅ "agents" subfolder exists inside "AI Agents"
- ✅ "Agent Registry" document exists in "AI Agents" folder
- ✅ Four starter agents exist in "agents" folder:
  - Agent Builder
  - Sales Email Writer
  - Technical Documentation
  - Customer Support
- ✅ Opening "Agent Builder" shows formatted content (not empty)

**Status**: [ ] PASS / [ ] FAIL

---

## Test 6: API Functionality Test

**What we're testing**: Server can actually use the decrypted credentials.

### Steps:
1. With server running, test the /agents endpoint:

```powershell
$apiKey = "YOUR_API_KEY_FROM_GPT_CONFIG_TXT"
$ngrokUrl = "YOUR_NGROK_URL_FROM_GPT_CONFIG_TXT"

$headers = @{
    "Authorization" = "Bearer $apiKey"
}

# List all agents
$agents = Invoke-RestMethod -Uri "$ngrokUrl/agents" -Headers $headers
$agents.agents

# Should return array of 4 agents with names and IDs
```

### Expected Results:
- ✅ Request succeeds (status 200)
- ✅ Response contains 4 agents
- ✅ Each agent has: id, name, modified timestamp
- ✅ Agent names match the starter agents

**Status**: [ ] PASS / [ ] FAIL

---

## Summary

### All Tests Must Pass:
- [ ] Test 1: OAuth Client Validation UX
- [ ] Test 2: OAuth Authorization & Credential Encryption
- [ ] Test 3: CRITICAL - Credential Decryption (init_drive.py)
- [ ] Test 4: Server Startup with Encrypted Credentials
- [ ] Test 5: End-to-End Validation
- [ ] Test 6: API Functionality Test

### If Any Test Fails:
1. Note the exact error message
2. Check which file is failing (init_drive.py or agent_server.py)
3. Verify the fix was applied correctly:
   ```powershell
   # Check init_drive.py line 47
   Select-String -Path "init_drive.py" -Pattern "description, decrypted_bytes"

   # Check agent_server.py line 153
   Select-String -Path "agent_server.py" -Pattern "description, decrypted_bytes"
   ```
4. Both should show: `description, decrypted_bytes = win32crypt.CryptUnprotectData(...)`

---

## Success Criteria

**CRITICAL FIX VERIFIED**: If Tests 3 and 4 both pass, the credential decryption bug is fixed.

**UX FIX VERIFIED**: If Test 1 shows the improved message, the UX issue is fixed.

**SYSTEM READY**: If all 6 tests pass, the system is ready for production use.

---

## Quick Test Command

Run this after setup completes to quickly verify the fix:

```powershell
# Test that encrypted credentials can be loaded and parsed
python -c "
import json
import os
import win32crypt
from google.oauth2.credentials import Credentials

# Test decryption
with open('credentials.json.encrypted', 'rb') as f:
    encrypted = f.read()

description, decrypted_bytes = win32crypt.CryptUnprotectData(encrypted, None, None, None, 0)
creds_json = decrypted_bytes.decode('utf-8')
creds_dict = json.loads(creds_json)
creds = Credentials.from_authorized_user_info(creds_dict)

print('✅ SUCCESS: Credentials decrypted and loaded')
print(f'   Description: {description}')
print(f'   Token type: {creds.token}')
print(f'   Has refresh token: {bool(creds.refresh_token)}')
"
```

Expected output:
```
✅ SUCCESS: Credentials decrypted and loaded
   Description: AI Agent Manager
   Token type: [some token value]
   Has refresh token: True
```
