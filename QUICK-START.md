# AI Agent Manager - Quick Start Guide

**Time:** 15-20 minutes first time | 30 seconds daily

---

## Prerequisites

- Windows 11 (or 10)
- Python 3.11+ (3.13 compatible)
- ChatGPT Plus subscription
- Google account (free)
- Internet connection

---

## First Time Setup (15-20 minutes)

### Step 1: Google OAuth Setup (5-10 min)

**Create Google Cloud Project:**

1. Go to: https://console.cloud.google.com/
2. Click "Select a project" → "NEW PROJECT"
3. Name: "AI Agent Manager" → Click "CREATE"
4. Wait 30 seconds for project creation

**Enable Required APIs:**

5. Go to: https://console.cloud.google.com/apis/library
6. Search "Google Docs API" → Click it → Click "ENABLE"
7. Search "Google Drive API" → Click it → Click "ENABLE"

**Configure OAuth Consent:**

8. Go to: https://console.cloud.google.com/apis/credentials/consent
9. Select "External" → Click "CREATE"
10. Fill in:
    - App name: "AI Agent Manager"
    - User support email: [Your email]
    - Developer contact: [Your email]
11. Click "SAVE AND CONTINUE"
12. Click "ADD OR REMOVE SCOPES"
13. Check: ".../auth/documents" and ".../auth/drive.file"
14. Click "UPDATE" → "SAVE AND CONTINUE"
15. Click "ADD USERS" → Enter your email → "ADD"
16. Click "SAVE AND CONTINUE" → "BACK TO DASHBOARD"

**Create OAuth Credentials:**

17. Go to: https://console.cloud.google.com/apis/credentials
18. Click "CREATE CREDENTIALS" → "OAuth client ID"
19. Application type: **"Desktop app"** (CRITICAL)
20. Name: "AI Agent Manager Desktop"
21. Click "CREATE"
22. **KEEP POPUP OPEN** - you need these values next

---

### Step 2: Configure Project (2 min)

**Copy and edit credentials file:**

1. Open folder: `AI-Agent-Manager`
2. Find file: `oauth_client.json.EXAMPLE`
3. Open with Notepad
4. Replace `"YOUR_CLIENT_ID_HERE"` with your Client ID (from popup)
5. Replace `"YOUR_CLIENT_SECRET_HERE"` with your Client Secret (from popup)
6. Save as: `oauth_client.json` (remove .EXAMPLE)

---

### Step 3: Run Setup Script (5 min)

**Install dependencies and initialize system:**

1. Right-click: `setup.ps1`
2. Select: "Run with PowerShell"
3. Follow prompts:
   - Python installation check
   - Dependency installation (includes Python 3.13 compatibility)
   - Ngrok binary pre-download (happens before token prompt for better UX)
   - Test user requirement warning (IMPORTANT)
   - Google Drive folder creation
   - Starter agents initialization
4. Browser will open for Google OAuth - click "Allow"
5. Wait for "Setup complete!" message

**Note:** Setup now provides enhanced error messages if OAuth fails, with links to exact console pages for troubleshooting the 3 most common failures.

---

### Step 4: Start Server (30 sec)

**Launch the local API server:**

1. Double-click: `start-server.bat`
2. Server console opens showing:
   ```
   Server URL: https://abc123-xyz.ngrok-free.app
   API Key: your-generated-api-key-here
   ```
3. **COPY BOTH VALUES** - you need them for ChatGPT

Note: URL also saved to `GPT-CONFIG.txt`

---

### Step 5: Configure ChatGPT (5 min)

**Create Custom GPT:**

1. Go to: https://chat.openai.com
2. Click profile icon → "My GPTs" → "Create a GPT"
3. Switch to "Configure" tab

**Basic Settings:**

4. Name: `AI Agent Manager`
5. Description: `Dynamic agent system that loads specialized AI agents from Google Drive on-demand`
6. Instructions: Copy from README.txt "CHATGPT GPT CONFIGURATION" section (lines 196-244)

**Add Actions:**

7. Scroll to "Actions" → Click "Create new action"
8. Open file: `gpt-actions.yaml` (in project folder)
9. Copy entire contents → Paste into schema editor
10. Find line: `- url: http://localhost:3000`
11. Replace with: `- url: https://YOUR-NGROK-URL` (from server console)

**Configure Authentication (CRITICAL):**

12. Scroll to "Authentication" section
13. Select authentication type (should auto-detect "BearerAuth")
14. Field: "Bearer Token" or "API Key"
15. Paste your API key (from server console or GPT-CONFIG.txt)

**Test and Save:**

16. Click "Test" button → Should show "Connection successful"
17. Click "Save" (top right) → Select "Only me" → "Confirm"

---

## Daily Use (30 seconds)

**Every time you want to use your agents:**

1. Double-click: `start-server.bat`
2. Go to ChatGPT and open your "AI Agent Manager" GPT
3. Start using agents: "List my agents" or "Load the sales agent"
4. That's it!

**When done:**
- Close server window or run `stop-server.bat`

---

## Common Commands

**Start server:**
```bash
start-server.bat
```

**Stop server:**
```bash
stop-server.bat
```

**Test system:**
```bash
python test_server.py
```

**Reinstall/Reset:**
```powershell
.\setup.ps1
```

**Initialize Drive structure:**
```bash
python init_drive.py
```

---

## Troubleshooting

**401 Unauthorized error:**
- Add API key to ChatGPT Authentication section
- Copy exact key from GPT-CONFIG.txt (case-sensitive)
- Test connection in Actions panel

**Connection failed:**
- Server must be running (start-server.bat)
- Check server console is open
- Verify ngrok URL in Actions matches server console
- Verify API key is configured in Authentication
- Check Windows Firewall isn't blocking Python

**OAuth authorization failed:**
- **Most common:** Email mismatch - test user email doesn't match Gmail used
- Check: https://console.cloud.google.com/apis/credentials/consent
- Make sure YOUR Gmail is listed under 'Test users'
- The email must EXACTLY match the Gmail you selected
- Setup.ps1 will show detailed error messages with direct links to fix
- Common errors explained:
  1. EMAIL MISMATCH - Test user doesn't match selected Gmail
  2. MISSING TEST USER - You didn't add yourself as test user
  3. WRONG CREDENTIALS - Check oauth_client.json values

**No agents found:**
- Run: `python test_server.py` to diagnose
- Run: `python init_drive.py` to recreate structure
- Check Google Drive for "AI Agents" folder
- Check agent-server.log for errors

**URL changed after restart:**
- Normal with free ngrok
- Copy new URL from server console
- Update ChatGPT Actions with new URL
- API key stays the same (no need to update)

**oauth_client.json not found:**
- Copy oauth_client.json.EXAMPLE to oauth_client.json
- Edit with your Client ID and Client Secret
- See Step 2 above

**Full troubleshooting:** See README.txt and GPT-SETUP-GUIDE.md

---

## Important Files

- **README.txt** - Complete documentation
- **GPT-SETUP-GUIDE.md** - Detailed ChatGPT setup walkthrough
- **QUICK-START.md** - This file (1-page reference)
- **GPT-CONFIG.txt** - Your current URL + API Key (auto-generated)
- **agent-server.log** - Debug logs and error messages
- **oauth_client.json** - Your Google OAuth credentials (PRIVATE)
- **credentials.json.encrypted** - Your Google token (PRIVATE)
- **config.json** - Server configuration and API key

---

## Example Usage

**List available agents:**
```
List my agents
```

**Load specific agent:**
```
Load the Sales Email Writer agent
```

**Use loaded agent:**
```
Write a cold email to a CEO about our AI tool
```

**Create new agent:**
```
Create an agent for writing Instagram captions
```

**Edit agent:**
1. Open Google Drive
2. Navigate to: AI Agents/agents/
3. Open agent document
4. Edit content
5. Save (changes apply immediately on next load)

---

## Links

- **Google Cloud Console:** https://console.cloud.google.com
- **ChatGPT:** https://chat.openai.com
- **Ngrok:** https://ngrok.com (optional paid plan for static URL)

---

## Starter Agents Included

After setup, you'll have 4 starter agents:

1. **Agent Builder** - Use this FIRST when creating new agents
2. **Sales Email Writer** - Write compelling sales emails
3. **Technical Documentation** - Create clear technical docs
4. **Customer Support** - Handle customer inquiries

---

## Next Steps

**After completing setup:**

1. Test system: "List my agents"
2. Load starter agent: "Load the Agent Builder"
3. Create first custom agent: "Create agent for [your purpose]"
4. Edit agent in Google Drive to see live updates
5. Explore different agents for different tasks

---

## Notes

**Free vs Paid Ngrok:**
- **Free ($0):** URL changes each restart (~30 sec to update ChatGPT)
- **Paid ($8/month):** Static URL, never changes, set-and-forget

**Security:**
- API key required for all requests
- Keep oauth_client.json private
- Keep credentials.json.encrypted private
- Don't share your ngrok URL publicly
- All data stays on YOUR computer and YOUR Google Drive

**Performance:**
- First agent load: 2-5 seconds (normal)
- Subsequent loads: Near instant
- Keep agent docs under 10KB for best performance

---

**That's it!** See README.txt for complete documentation and troubleshooting.

**Questions?** Check agent-server.log for errors or run `python test_server.py` to diagnose issues.
