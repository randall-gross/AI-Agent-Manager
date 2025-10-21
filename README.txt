========================================
AI AGENT MANAGER - USER GUIDE
========================================

Version: 1.1.0
Platform: Windows 11 (Windows 10 compatible)
Python: 3.11+ (3.13 compatible)
License: MIT

========================================
WHAT IS THIS?
========================================

AI Agent Manager lets you create and manage specialized AI agents for ChatGPT using Google Docs.

Key Features:
  - Create unlimited custom AI agents through conversation
  - Edit agents by simply editing their Google Doc
  - No coding required
  - No cloud hosting costs
  - All data stays on YOUR computer and YOUR Google Drive
  - Works with ChatGPT Plus

How it works:
  1. Runs a tiny server on your computer
  2. Stores agents as Google Docs you can edit
  3. ChatGPT connects to your server to load agents
  4. Create/edit agents anytime

========================================
GETTING GOOGLE OAUTH CREDENTIALS (REQUIRED FIRST)
========================================

Before you can use AI Agent Manager, you need Google OAuth credentials.
This lets the application access YOUR Google Drive securely.

IMPORTANT: You only do this ONCE. Takes about 5-10 minutes.

Step 1: Create Google Cloud Project
------------------------------------
  1. Go to: https://console.cloud.google.com/
  2. Sign in with your Google account
  3. Click "Select a project" at the top
  4. Click "NEW PROJECT"
  5. Project name: "AI Agent Manager" (or any name you want)
  6. Click "CREATE"
  7. Wait for project to be created (30 seconds)

Step 2: Enable Required APIs
-----------------------------
  1. Make sure your new project is selected (check top bar)
  2. Go to: https://console.cloud.google.com/apis/library
  3. Search for: "Google Docs API"
  4. Click on "Google Docs API"
  5. Click "ENABLE"
  6. Wait for it to enable (10 seconds)
  7. Click "Go to APIs" or use back button
  8. Search for: "Google Drive API"
  9. Click on "Google Drive API"
  10. Click "ENABLE"
  11. Wait for it to enable (10 seconds)

Step 3: Configure OAuth Consent Screen
---------------------------------------
  1. Go to: https://console.cloud.google.com/apis/credentials/consent
  2. Select "External" user type
  3. Click "CREATE"
  4. Fill in required fields:
     - App name: "AI Agent Manager"
     - User support email: [YOUR EMAIL]
     - Developer contact: [YOUR EMAIL]
  5. Click "SAVE AND CONTINUE"
  6. On "Scopes" page: Click "ADD OR REMOVE SCOPES"
  7. Filter for: ".../auth/documents"
  8. Check: ".../auth/documents" (Google Docs API)
  9. Check: ".../auth/drive.file" (Google Drive API)
  10. Click "UPDATE"
  11. Click "SAVE AND CONTINUE"
  12. On "Test users" page: Click "ADD USERS"
  13. Enter YOUR email address
  14. Click "ADD"
  15. Click "SAVE AND CONTINUE"
  16. Review summary, click "BACK TO DASHBOARD"

Step 4: Create OAuth Credentials
---------------------------------
  1. Go to: https://console.cloud.google.com/apis/credentials
  2. Click "CREATE CREDENTIALS"
  3. Select "OAuth client ID"
  4. Application type: "Desktop app" ⚠️ CRITICAL - Choose "Desktop app"
  5. Name: "AI Agent Manager Desktop"
  6. Click "CREATE"
  7. You'll see a popup with your credentials
  8. DON'T close it yet!

Step 5: Copy Your Credentials
------------------------------
  You'll see two values:
    - Client ID: Something like "123456789-abcdefg.apps.googleusercontent.com"
    - Client Secret: Something like "GOCSPX-abc123xyz789"

  Keep this popup open! You'll need these values in the next step.

Step 6: Create oauth_client.json File
--------------------------------------
  1. In the AI-Agent-Manager folder, find: oauth_client.json.EXAMPLE
  2. Open it with Notepad
  3. You'll see this:
     {
       "installed": {
         "client_id": "YOUR_CLIENT_ID_HERE",
         "client_secret": "YOUR_CLIENT_SECRET_HERE",
         ...
       }
     }
  4. Replace "YOUR_CLIENT_ID_HERE" with your Client ID
  5. Replace "YOUR_CLIENT_SECRET_HERE" with your Client Secret
  6. Save the file as: oauth_client.json
     (Remove .EXAMPLE from the name)

Step 7: Verify Your Setup
--------------------------
  You should now have:
    ✓ Google Cloud project created
    ✓ Google Docs API enabled
    ✓ Google Drive API enabled
    ✓ OAuth consent screen configured
    ✓ Test user added (your email)
    ✓ OAuth Desktop app credentials created
    ✓ oauth_client.json file created with your credentials

  Ready to proceed? Continue to QUICK START below.

========================================
QUICK START (FIRST TIME)
========================================

PREREQUISITE: Get Google OAuth credentials first (see section above)

1. RUN SETUP
   - Right-click: setup.ps1
   - Select: "Run with PowerShell"
   - Follow the prompts
   - Setup will pre-download ngrok binary before asking for token
   - Setup includes prominent test user requirement warning
   - Setup provides detailed OAuth error messages if authorization fails

2. START SERVER
   - Double-click: start-server.bat
   - Copy the URL it shows

3. CONFIGURE CHATGPT
   - Open: GPT-SETUP-GUIDE.md
   - Follow instructions
   - Use URL from server

4. USE YOUR AGENTS!
   - "List my agents"
   - "Load the sales agent"
   - "Create agent for Instagram captions"

========================================
DAILY USE
========================================

Starting the server:
  - Double-click: start-server.bat
  - Server runs in background
  - Keep window open while using ChatGPT

Stopping the server:
  - Close server window, or
  - Double-click: stop-server.bat

Creating new agents:
  - Tell ChatGPT: "Create agent for [purpose]"
  - Answer a few questions
  - Done! Agent is ready to use

Editing agents:
  - Open Google Drive
  - Go to "AI Agents/agents/" folder
  - Edit any agent document
  - Changes apply immediately

========================================
CHATGPT GPT CONFIGURATION
========================================

After completing setup and starting the server, you need to create and configure a custom GPT in ChatGPT.

GPT Name:
---------
AI Agent Manager

GPT Description:
----------------
Dynamic agent system that loads specialized AI agents from Google Drive on-demand

GPT Instructions (Copy and paste exactly):
-------------------------------------------
You are an AI agent orchestrator with three primary functions:

1. AGENT MANAGEMENT
   - List available agents: Call listAgents action
   - Load specific agent: Call getAgent action with doc_id
   - Create new agent: Call createAgent action with structured data

2. AGENT LOADING WORKFLOW
   CRITICAL: Before performing any specialized task, you MUST:
   a) Call listAgents to see available agents
   b) Identify the most appropriate agent for the user's request
   c) Call getAgent(doc_id) to load that agent's instructions
   d) Read and adopt the agent's prompt as your PRIMARY instructions
   e) Then respond to the user as that agent

3. AGENT CREATION
   When user wants a new agent, ask for:
   - Agent name (what to call it)
   - Purpose (what it does)
   - Key skills (list of capabilities)
   - Rules (constraints, must/must not)
   - Tone (communication style)
   - Output format (how to structure responses)

   Then call createAgent with this structured data.

IMPORTANT BEHAVIORS:
- The loaded agent's instructions OVERRIDE these base instructions
- You become that agent - adopt its personality, rules, and style completely
- Don't mention "loading" or "switching" - just be the agent
- If no agent is appropriate, work in general-purpose mode
- Users can edit agents in Google Drive - changes apply immediately on next load

STARTER AGENTS AVAILABLE:
You have access to four starter agents:
- Agent Builder (use this FIRST when creating new agents!)
- Sales Email Writer
- Technical Documentation
- Customer Support

More agents can be created on-demand through conversation.

WORKFLOW EXAMPLE:
User: "Write me a sales email"
You: [Call listAgents] → [See "Sales Email Writer"] → [Call getAgent for that agent] → [Load its instructions] → [Write email using that agent's style and rules]

Remember: When an agent is loaded, you ARE that agent. Follow its rules exactly.

Actions Configuration:
----------------------
1. In ChatGPT GPT Builder, add the gpt-actions.yaml file as your Actions schema
2. Update the server URL in the schema to YOUR ngrok URL (shown in server console)
3. CRITICAL: Configure Authentication with your API key:
   - Add Bearer token authentication
   - Paste your API key (from server console or GPT-CONFIG.txt)
   - Without API key, all requests will be rejected with 401 Unauthorized
4. Test the connection (should show "Connection successful")
5. If URL changes (free ngrok), update Actions with new URL (API key stays same)

Note: The server URL changes each restart if using free ngrok ($0). Upgrade to paid ngrok ($8/month) for a static URL that never changes.

Detailed Setup Instructions:
-----------------------------
For complete step-by-step ChatGPT configuration including screenshots and troubleshooting, see GPT-SETUP-GUIDE.md

========================================
STARTER AGENTS INCLUDED
========================================

Agent Builder
- Purpose: Guide you in creating well-structured agents
- Use this FIRST when making new agents!

Sales Email Writer
- Purpose: Write compelling sales emails
- Use for: Cold emails, follow-ups, proposals

Technical Documentation
- Purpose: Create clear technical docs
- Use for: API docs, code explanations, guides

Customer Support
- Purpose: Handle customer inquiries
- Use for: Troubleshooting, FAQs, support

========================================
SYSTEM REQUIREMENTS
========================================

Required:
  - Windows 11 or Windows 10
  - Python 3.11 or newer (3.13 compatible)
  - Google account (free)
  - Ngrok account (free)
  - ChatGPT Plus subscription
  - 100MB disk space
  - Internet connection

Optional:
  - Paid ngrok account ($8/month) for static URL

========================================
FILES & FOLDERS
========================================

After setup, you'll have:

  credentials.json    - Your Google OAuth token (PRIVATE)
  config.json         - Server configuration
  agent-server.log    - Debug logs
  GPT-CONFIG.txt      - Current server URL

Templates:
  templates/          - Starter agent templates

Scripts:
  setup.ps1           - One-time setup
  start-server.bat    - Start server
  stop-server.bat     - Stop server

Python files:
  agent_server.py     - Main server
  auth_setup.py       - OAuth setup
  init_drive.py       - Drive initialization
  test_server.py      - Test script

========================================
TROUBLESHOOTING
========================================

Server won't start:
  - Make sure you ran setup.ps1 first
  - Check that Python is installed
  - Try: python test_server.py

ChatGPT can't connect:
  - Is start-server.bat running?
  - Copy current URL from server window
  - Update your GPT Actions with new URL
  - Verify API key is configured in Authentication

OAuth authorization failed:
  - Most common: Email mismatch - test user email doesn't match Gmail used
  - Check: https://console.cloud.google.com/apis/credentials/consent
  - Make sure YOUR Gmail is listed under 'Test users'
  - The email must EXACTLY match the Gmail you selected
  - See setup.ps1 output for detailed error explanations

No agents found:
  - Check Google Drive for "AI Agents" folder
  - Run: python init_drive.py
  - Check agent-server.log for errors

Agent doesn't work right:
  - Open agent doc in Google Drive
  - Check formatting (Purpose, Skills, Rules sections)
  - Make sure content isn't empty

URL changed:
  - Free ngrok URLs change each restart
  - Copy new URL from server
  - Update GPT Actions

For more help:
  - Check agent-server.log
  - Run: python test_server.py
  - See troubleshooting guide in docs/

========================================
PRIVACY & SECURITY
========================================

Where your data lives:
  - Agent definitions: Your Google Drive
  - Credentials: Your computer (credentials.json.encrypted)
  - OAuth config: Your computer (oauth_client.json)
  - API key: Your computer (config.json)
  - Nothing in the cloud: Everything is yours

What's shared:
  - Nothing is shared automatically
  - You can share agent docs with others manually
  - Server only accessible via your ngrok URL + API key

SECURITY FEATURES (NEW):

1. API Key Authentication
   - Every request requires Bearer token authentication
   - API key generated automatically on first run
   - Stored in config.json and shown in server console
   - ChatGPT must provide this key to access your agents
   - Without API key: Unauthorized access is blocked

2. Credential Encryption
   - Google OAuth credentials encrypted using Windows DPAPI
   - Stored as credentials.json.encrypted (not plaintext)
   - Only decryptable on your Windows account
   - If someone steals the file, they can't use it

3. OAuth Client Protection
   - OAuth credentials moved to separate file (oauth_client.json)
   - File is in .gitignore (won't be committed to Git)
   - Uses template system for easy setup
   - Validates credentials before use

4. Rate Limiting
   - POST /agents: 10 requests per hour (prevent spam)
   - GET /agents: 100 requests per hour
   - GET /agents/{id}: 100 requests per hour
   - GET /health: 30 requests per hour
   - Protects against API quota exhaustion

5. Input Validation
   - Agent names: 3-200 chars, alphanumeric only
   - Content fields: Max 50KB per field
   - All text sanitized to prevent injection attacks
   - Agent IDs validated against Google Doc format

Security best practices:
  - NEVER share your API key publicly
  - NEVER commit oauth_client.json to Git
  - NEVER share credentials.json or credentials.json.encrypted
  - Keep your ngrok URL private (don't post online)
  - Ngrok provides encrypted HTTPS tunnel
  - Google Drive access limited to AI Agents folder
  - Server runs on YOUR computer, not in cloud
  - Review agent content before using (trust but verify)

What to do if compromised:
  1. Stop the server immediately (stop-server.bat)
  2. Delete config.json (will regenerate new API key)
  3. Revoke Google access: https://myaccount.google.com/permissions
  4. Run setup.ps1 again to create new credentials
  5. Update ChatGPT with new API key

========================================
UPDATING AGENTS
========================================

Agents are just Google Docs! Edit them anytime:

1. Open Google Drive
2. Navigate to: AI Agents/agents/
3. Open any agent document
4. Edit the content
5. Save (Ctrl+S)
6. Changes apply immediately

Agent structure (recommended):
  # Agent Name

  ## Purpose
  What this agent does

  ## Key Skills
  - Skill 1
  - Skill 2

  ## Rules
  - Rule 1
  - Rule 2

  ## Tone & Style
  How the agent communicates

  ## Output Format
  How to structure responses

========================================
ADVANCED FEATURES
========================================

Auto-start on boot:
  - Run: python install_autostart.py
  - Server starts automatically when you log in

Static ngrok URL:
  - Upgrade to ngrok paid ($8/month)
  - URL won't change between restarts
  - No need to update GPT Actions

Multiple GPTs:
  - Create different GPTs for different purposes
  - All can connect to same server
  - All share same agent library

Backup agents:
  - Agents are Google Docs
  - Use Google Drive export/download
  - Or use Google Drive backup features

Testing:
  - Run: python test_server.py
  - Checks all components
  - Reports any issues

========================================
UNINSTALLING
========================================

AI Agent Manager includes a comprehensive uninstall script with three cleanup tiers.

To uninstall:
  Run: .\uninstall.ps1

Cleanup Levels:

1. MINIMAL - Quick cleanup for testing
   - Removes: credentials, logs, generated configs
   - Keeps: oauth_client.json, ngrok config, startup entry
   - Use when: Testing setup changes, keeping configurations

2. STANDARD - Normal uninstall (Recommended)
   - Removes: All generated files, logs, startup entry
   - Keeps: oauth_client.json, ngrok config
   - Use when: Reinstalling, want to keep OAuth/ngrok setup

3. FULL - Complete cleanup
   - Removes: EVERYTHING including OAuth config and ngrok
   - Warning: Will need to reconfigure OAuth and ngrok
   - Use when: Complete removal, switching accounts

The uninstaller provides:
  - Clear status indicators ([OK], [SKIP], [KEEP], [ERROR])
  - Detailed cleanup summary showing what was removed/kept
  - Context-aware "Next Steps" guidance for each tier
  - Comprehensive warnings for destructive operations

To completely remove AI Agent Manager:
  1. Run: .\uninstall.ps1 (select FULL cleanup)
  2. Delete this folder
  3. Delete "AI Agents" folder from Google Drive (manual)
  4. Revoke app access:
     - Go to: https://myaccount.google.com/permissions
     - Remove "AI Agent Manager"

========================================
SUPPORT & UPDATES
========================================

Documentation:
  - README.txt (this file)
  - GPT-SETUP-GUIDE.md
  - PRD.md (technical details)

Logs:
  - agent-server.log (errors and activity)

Version:
  - Current: 1.1.0
  - Check version.py for details

Updates:
  - Check GitHub for updates
  - GitHub: [Your repo URL here]

Support:
  - Email: [Your email here]
  - Issues: GitHub issues page

========================================
TIPS & BEST PRACTICES
========================================

Creating good agents:
  - Use the "Agent Builder" agent to guide you
  - Be specific about purpose and rules
  - Test agent after creating
  - Iterate and refine in Google Docs

Organizing agents:
  - Name agents clearly
  - Keep agent docs focused on one purpose
  - Create folders in Google Drive to organize
  - Update Agent Registry doc with notes

Performance:
  - Keep agent docs under 10KB for fast loading
  - Restart server weekly to clear logs
  - Monitor agent-server.log size

Security:
  - Keep credentials.json private
  - Don't share your ngrok URL publicly
  - Review agent content before using

========================================
FREQUENTLY ASKED QUESTIONS
========================================

Q: Do I need ChatGPT Plus?
A: Yes, custom GPTs require ChatGPT Plus.

Q: Can I use this on Mac or Linux?
A: Currently Windows only. Mac/Linux support possible in future.

Q: How many agents can I create?
A: Unlimited! Each is just a Google Doc.

Q: Will this work without internet?
A: No, requires internet for Google Drive and ChatGPT.

Q: Can I share my agents with others?
A: Yes! Share the Google Doc link. They can copy it.

Q: Does this work with other AI models?
A: Currently optimized for ChatGPT. Other models may work with modifications.

Q: What if I delete an agent doc?
A: It won't appear in agent list anymore. You can recreate it.

Q: Can I export my agents?
A: Yes! Use Google Drive's export feature (File > Download).

========================================
VERSION HISTORY
========================================

1.1.0 (2025-10-20) - Security & UX Update
  - Added API authentication with Bearer tokens
  - Added credential encryption (Windows DPAPI)
  - Added OAuth protection (separate client file)
  - Added rate limiting (10 creates/hour, 100 reads/hour)
  - Added comprehensive input validation
  - Enhanced setup UX (pre-downloads ngrok, test user warnings)
  - Enhanced uninstall (3-tier cleanup: MINIMAL/STANDARD/FULL)
  - Improved OAuth error messages (3 most common failures explained)
  - Fixed Python 3.13 compatibility (pillow>=10.1.0, pywin32>=306)
  - Fixed init_drive.py encrypted credentials support
  - Fixed PowerShell syntax issues

1.0.0 (2025-10-20) - Initial Release
  - Core agent management
  - Google Drive integration
  - ChatGPT Actions support
  - Windows 11 support
  - 4 starter agents included (including Agent Builder)

========================================
CREDITS
========================================

Built with:
  - Python & Flask
  - Google Drive API
  - Google Docs API
  - Ngrok
  - ChatGPT

Created for: Non-technical users who want custom AI agents

========================================

Thank you for using AI Agent Manager!

For help: See GPT-SETUP-GUIDE.md
For issues: Check agent-server.log
For updates: Check GitHub

========================================
