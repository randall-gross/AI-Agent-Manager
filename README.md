# AI Agent Manager

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/randall-gross/AI-Agent-Manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2011%2F10-lightgrey.svg)]()
[![Python](https://img.shields.io/badge/python-3.11%2B%20%7C%203.13-blue.svg)]()

> Create and manage unlimited custom AI agents for ChatGPT using Google Docs - no coding required, runs on your computer, all data stays private.

## What is AI Agent Manager?

AI Agent Manager lets you create specialized AI agents through conversation with ChatGPT, storing them as editable Google Docs on your own Google Drive. Think of it as a personal agent factory that runs on your computer with zero cloud hosting costs.

### Key Features

- **Create Unlimited Agents** - Build specialized AI agents through simple conversation
- **No Coding Required** - Everything managed through ChatGPT interface
- **Edit Anytime** - Agents are Google Docs you can edit directly
- **Private & Secure** - All data stays on YOUR computer and YOUR Google Drive
- **Zero Cloud Costs** - Local server, your infrastructure
- **Instant Updates** - Edit agents in Google Drive, changes apply immediately
- **4 Starter Agents** - Agent Builder, Sales Writer, Technical Docs, Customer Support

### How It Works

```
1. Tiny server runs on your computer (Python + Flask)
2. Agents stored as Google Docs you can edit
3. ChatGPT connects to your server via secure tunnel
4. Create/edit/use agents through conversation
```

---

## Quick Start

**Time:** 15-20 minutes first time | 30 seconds daily

### Prerequisites

- Windows 11 (or Windows 10)
- Python 3.11 or newer (3.13 compatible)
- ChatGPT Plus subscription
- Google account (free)
- Internet connection

### Installation

1. **Get Google OAuth Credentials** (one-time, 5-10 min)
   - See [detailed instructions in QUICK-START.md](QUICK-START.md#step-1-google-oauth-setup-5-10-min)
   - Create Google Cloud project
   - Enable Google Docs & Drive APIs
   - Create OAuth Desktop app credentials

2. **Configure OAuth**
   ```bash
   # Copy template and add your credentials
   copy oauth_client.json.EXAMPLE oauth_client.json
   # Edit oauth_client.json with your Client ID and Client Secret
   ```

3. **Run Setup**
   ```powershell
   # Right-click setup.ps1 -> "Run with PowerShell"
   .\setup.ps1
   ```

4. **Start Server**
   ```bash
   start-server.bat
   # Copy the URL and API key shown
   ```

5. **Configure ChatGPT**
   - Follow [GPT-SETUP-GUIDE.md](GPT-SETUP-GUIDE.md)
   - Create custom GPT with provided instructions
   - Add Actions with your server URL
   - Configure authentication with your API key

### Daily Use

```bash
# Start server
start-server.bat

# Use ChatGPT
"List my agents"
"Load the sales agent"
"Create agent for Instagram captions"

# Stop server
stop-server.bat
```

---

## Security Features

AI Agent Manager includes comprehensive security protections:

### 1. API Authentication
- Every request requires Bearer token authentication
- API key auto-generated on first run
- Stored securely in `config.json`
- Without API key: All access blocked

### 2. Credential Encryption
- Google OAuth credentials encrypted using Windows DPAPI
- Only decryptable on your Windows account
- Protects against credential theft

### 3. OAuth Client Protection
- OAuth credentials in separate file (`oauth_client.json`)
- Never committed to Git (`.gitignore`)
- Template system for easy setup

### 4. Rate Limiting
- POST /agents: 10/hour (prevent spam)
- GET endpoints: 100/hour
- Protects against API quota exhaustion

### 5. Input Validation
- Agent names: 3-200 chars, alphanumeric only
- Content fields: Max 50KB per field
- All text sanitized to prevent injection attacks

**Learn more:** [SECURITY-UPGRADE-NOTES.md](SECURITY-UPGRADE-NOTES.md)

---

## Documentation

- **[README.md](README.md)** - This file - comprehensive overview and quick start
- **[QUICK-START.md](QUICK-START.md)** - 1-page quick reference guide
- **[GPT-SETUP-GUIDE.md](GPT-SETUP-GUIDE.md)** - Detailed ChatGPT configuration walkthrough
- **[SECURITY-UPGRADE-NOTES.md](SECURITY-UPGRADE-NOTES.md)** - Security features and migration guide
- **[README.txt](README.txt)** - Alternative text-based comprehensive guide

---

## System Architecture

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   ChatGPT   │ <────> │ Ngrok Tunnel │ <────> │ Local Server│
│  (Actions)  │  HTTPS  │   (Secure)   │  HTTP  │   (Flask)   │
└─────────────┘         └──────────────┘         └─────────────┘
                                                        │
                                                        v
                                                  ┌─────────────┐
                                                  │Google Drive │
                                                  │  (Agents)   │
                                                  └─────────────┘
```

**Components:**
- **Flask Server**: Local Python server handling agent CRUD operations
- **Ngrok**: Secure HTTPS tunnel to expose local server to ChatGPT
- **Google Drive API**: Stores agents as Google Docs
- **ChatGPT Actions**: Custom GPT that calls your server

---

## Usage Examples

### List Available Agents
```
You: "List my available agents"
GPT: Shows all agents with IDs and names
```

### Load and Use an Agent
```
You: "Load the Sales Email Writer agent"
GPT: [Loads agent instructions]

You: "Write a cold email to a CEO about our AI tool"
GPT: [Writes email using Sales Email Writer personality and rules]
```

### Create New Agent
```
You: "Create an agent for writing Instagram captions"
GPT: Asks questions about purpose, style, rules
You: Answer questions
GPT: Creates agent and saves to Google Drive
```

### Edit Agent
1. Open Google Drive
2. Navigate to `AI Agents/agents/`
3. Open agent document
4. Edit content (Purpose, Skills, Rules, etc.)
5. Save - changes apply on next load

---

## Starter Agents

Four pre-configured agents included:

| Agent | Purpose | Use Cases |
|-------|---------|-----------|
| **Agent Builder** | Guide you in creating well-structured agents | Use FIRST when making new agents |
| **Sales Email Writer** | Write compelling sales emails | Cold emails, follow-ups, proposals |
| **Technical Documentation** | Create clear technical docs | API docs, code explanations, guides |
| **Customer Support** | Handle customer inquiries | Troubleshooting, FAQs, support tickets |

---

## Troubleshooting

### Server won't start
```bash
# Check Python installation
python --version

# Run test script
python test_server.py
```

### ChatGPT can't connect
- Verify server is running (`start-server.bat`)
- Check URL in ChatGPT Actions matches server console
- Verify API key is configured in Authentication section
- Test connection in Actions panel

### 401 Unauthorized error
- Add API key to ChatGPT Actions → Authentication
- Copy exact key from `GPT-CONFIG.txt` (case-sensitive)
- Test connection

### No agents found
```bash
# Reinitialize Google Drive structure
python init_drive.py

# Check logs for errors
type agent-server.log
```

### URL changed after restart
- Normal with free ngrok
- Copy new URL from server console
- Update ChatGPT Actions with new URL
- API key stays the same (no need to update)

**For more troubleshooting:** See [GPT-SETUP-GUIDE.md](GPT-SETUP-GUIDE.md) for detailed solutions

---

## Uninstalling

AI Agent Manager includes a comprehensive uninstall script with three cleanup tiers:

**Quick uninstall:**
```powershell
.\uninstall.ps1
```

**Cleanup Levels:**

1. **MINIMAL** - Quick cleanup for testing
   - Removes: credentials, logs, generated configs
   - Keeps: oauth_client.json, ngrok config, startup entry
   - Use when: Testing setup changes, keeping configurations

2. **STANDARD** - Normal uninstall (Recommended)
   - Removes: All generated files, logs, startup entry
   - Keeps: oauth_client.json, ngrok config
   - Use when: Reinstalling, want to keep OAuth/ngrok setup

3. **FULL** - Complete cleanup
   - Removes: EVERYTHING including OAuth config and ngrok
   - Warning: Will need to reconfigure OAuth and ngrok
   - Use when: Complete removal, switching accounts

The uninstaller provides:
- Clear status indicators ([OK], [SKIP], [KEEP], [ERROR])
- Detailed cleanup summary showing what was removed/kept
- Context-aware "Next Steps" guidance for each tier
- Comprehensive warnings for destructive operations

**Note:** Google Drive folder must be deleted manually for security.

---

## Advanced Features

### Auto-start on Boot
```bash
python install_autostart.py
```

### Static Ngrok URL
Upgrade to ngrok paid ($8/month) for URL that never changes - no need to update ChatGPT Actions after restarts.

### Multiple GPTs
- Create different GPTs for different purposes
- All connect to same server
- All share same agent library

### Backup Agents
Agents are Google Docs - use Google Drive's native backup/export features.

---

## Files and Folders

```
AI-Agent-Manager/
├── agent_server.py           # Main Flask server
├── auth_setup.py             # Google OAuth setup
├── init_drive.py             # Google Drive initialization
├── setup.ps1                 # One-time setup script
├── start-server.bat          # Start server
├── stop-server.bat           # Stop server
├── gpt-actions.yaml          # ChatGPT Actions schema
├── oauth_client.json         # Your OAuth credentials (PRIVATE)
├── config.json               # Server config + API key
├── credentials.json.encrypted # Encrypted Google token
├── templates/                # Starter agent templates
├── README.md                 # This file
├── README.txt                # Complete user guide
├── QUICK-START.md            # Quick reference
├── GPT-SETUP-GUIDE.md        # ChatGPT setup guide
└── SECURITY-UPGRADE-NOTES.md # Security documentation
```

**Never share:** `oauth_client.json`, `credentials.json*`, `config.json`

---

## Requirements

- **Platform:** Windows 11 or Windows 10
- **Python:** 3.11 or newer (3.13 compatible)
- **ChatGPT:** Plus subscription (for custom GPTs)
- **Google:** Free Google account
- **Ngrok:** Free account (optional $8/month for static URL)
- **Disk:** 100MB free space

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Support

- **Documentation:** This README provides complete overview
- **Quick Start:** [QUICK-START.md](QUICK-START.md) for fast setup
- **ChatGPT Setup:** [GPT-SETUP-GUIDE.md](GPT-SETUP-GUIDE.md) for detailed configuration
- **Issues:** [GitHub Issues](https://github.com/randall-gross/AI-Agent-Manager/issues)
- **Logs:** Check `agent-server.log` for errors
- **Test:** Run `python test_server.py` to diagnose issues

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Built with:
- [Python](https://www.python.org/) & [Flask](https://flask.palletsprojects.com/)
- [Google Drive API](https://developers.google.com/drive) & [Google Docs API](https://developers.google.com/docs)
- [Ngrok](https://ngrok.com/)
- [ChatGPT](https://chat.openai.com/)

Created for non-technical users who want custom AI agents without cloud hosting costs.

---

## Version History

**v1.1.0** (2025-10-20) - Security & UX Update
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

**v1.0.0** (2025-10-20) - Initial Release
- Core agent management
- Google Drive integration
- ChatGPT Actions support
- 4 starter agents included

---

**Made with Claude Code** | [GitHub](https://github.com/randall-gross/AI-Agent-Manager) | [License](LICENSE)
