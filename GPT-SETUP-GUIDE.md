# ChatGPT Configuration Guide
## Complete Setup Instructions for AI Agent Manager

---

## Overview

This guide walks you through configuring your ChatGPT to work with the AI Agent Manager server running on your computer.

**Time required:** 5-10 minutes
**Prerequisites:** Server must be running (start-server.bat)

---

## Step 1: Get Your Server URL and API Key

1. Make sure `start-server.bat` is running
2. Look at the server console window
3. Find these lines:
   - **Server URL:** `https://abc123-def.ngrok-free.app`
   - **API Key:** `your-generated-api-key-here`

**Alternative:** Open `GPT-CONFIG.txt` in the project folder - both are there

⚠️ **Important:**
- The URL changes each time you restart the server (unless you have paid ngrok)
- The API Key stays the same (stored in config.json)
- NEVER share your API key publicly

---

## Step 2: Access ChatGPT GPT Builder

1. Go to https://chat.openai.com
2. Log in to your ChatGPT Plus account
3. Click your profile icon (bottom-left)
4. Select **"My GPTs"**
5. Click **"Create a GPT"** button

---

## Step 3: Configure Basic Information

Switch to the **"Configure"** tab at the top.

### Name
```
AI Agent Manager
```

### Description
```
Dynamic agent system that loads specialized AI agents from Google Drive on-demand
```

### Instructions

Copy and paste this **exactly**:

```
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
```

---

## Step 4: Add Actions

Scroll down to the **"Actions"** section and click **"Create new action"**.

### Import the Schema

1. Open `gpt-actions.yaml` from your AI-Agent-Manager folder
2. Copy the entire contents
3. Paste into the Actions schema editor

### Update the Server URL

**CRITICAL STEP:** You must replace the placeholder URL with YOUR ngrok URL.

In the schema editor, find this line near the top:
```yaml
servers:
  - url: http://localhost:3000
```

Change it to:
```yaml
servers:
  - url: https://YOUR-ACTUAL-NGROK-URL-HERE
```

Example:
```yaml
servers:
  - url: https://abc123-def.ngrok-free.app
```

### Configure Authentication (NEW - REQUIRED)

**CRITICAL:** The API now requires authentication for security.

1. After pasting the schema, scroll down to the **"Authentication"** section
2. ChatGPT should auto-detect the "BearerAuth" security scheme
3. You'll see a field labeled **"Bearer Token"** or **"API Key"**
4. Paste your API key (from server console or GPT-CONFIG.txt)
5. Click **"Save"**

**Example:**
- Field name: "Bearer Token" or "Authorization"
- Value: `your-api-key-from-gpt-config-txt`

⚠️ **Important:**
- Without the API key, all requests will be rejected with 401 Unauthorized
- The API key is shown when you start the server
- It's also saved in GPT-CONFIG.txt
- Keep this key private - don't share it

### Test the Connection

1. Click the **"Test"** button in the Actions section
2. You should see: ✅ "Connection successful"
3. If you see an error:
   - **401 Unauthorized:** API key is missing or incorrect
   - Make sure start-server.bat is running
   - Verify the URL is correct (no typos, no trailing slash)
   - Verify the API key is correct (copy from GPT-CONFIG.txt)
   - Check that the URL matches what's in the server console

---

## Step 5: Configure Conversation Starters (Optional)

Scroll to **"Conversation starters"** and add these:

```
📋 List all my agents
```

```
✨ Create a new agent for [purpose]
```

```
🔄 Load the sales agent
```

```
📝 What agents do I have available?
```

These give users quick ways to interact with the system.

---

## Step 6: Save Your GPT

1. Click **"Save"** in the top-right corner
2. Choose visibility:
   - **"Only me"** - Recommended for personal use
   - **"Anyone with a link"** - If you want to share
   - **"Public"** - Not recommended for personal agents

3. Click **"Confirm"**

---

## Step 7: Test Your Setup

Let's verify everything works:

### Test 1: List Agents
In your new GPT, type:
```
List my available agents
```

**Expected result:** Should show at least 4 agents:
- Agent Builder
- Sales Email Writer
- Technical Documentation
- Customer Support

### Test 2: Load an Agent
Type:
```
Load the Sales Email Writer agent
```

**Expected result:** GPT should load the agent and confirm it's ready to write sales emails

### Test 3: Use an Agent
Type:
```
Write a cold email to a CEO about our new AI tool
```

**Expected result:** GPT should write an email in the style defined in the Sales Email Writer agent

### Test 4: Create New Agent
Type:
```
Create a new agent for writing Instagram captions
```

**Expected result:** GPT should ask questions about the agent's style, then create it

---

## Troubleshooting

### "401 Unauthorized" Error (NEW)

**Problem:** API key authentication failed

**Solutions:**
- Make sure you configured Authentication in ChatGPT Actions
- Copy the API key from GPT-CONFIG.txt or server console
- Paste it exactly as shown (no extra spaces)
- The API key is case-sensitive
- If you deleted config.json, a new key was generated - update ChatGPT
- Test the connection in Actions panel after updating

### "Connection failed" Error

**Problem:** GPT can't reach your server

**Solutions:**
- Is `start-server.bat` running? Check for console window
- Is the ngrok URL in Actions correct?
- Is the API key configured in Authentication section?
- Try opening the URL in your browser - should show JSON with limited info
- Check Windows Firewall isn't blocking Python
- Look at `agent-server.log` for errors

### OAuth Authorization Failed (NEW)

**Problem:** Setup fails during Google OAuth authorization

**Common Causes:**

1. **EMAIL MISMATCH** (Most Common)
   - The Gmail you selected doesn't match the test user you added
   - Solution: Go to https://console.cloud.google.com/apis/credentials/consent
   - Verify YOUR email is listed under 'Test users'
   - The email must EXACTLY match the Gmail you use to authorize

2. **MISSING TEST USER**
   - You didn't add yourself as a test user in OAuth consent screen
   - Solution: Go to https://console.cloud.google.com/apis/credentials/consent
   - Scroll to 'Test users' section
   - Click 'ADD USERS' and add your Gmail
   - Click 'SAVE'

3. **WRONG OAUTH CREDENTIALS**
   - oauth_client.json has incorrect client_id or client_secret
   - Solution: Check oauth_client.json values match Google Cloud Console
   - Get correct values from https://console.cloud.google.com/apis/credentials

**Note:** Setup.ps1 now provides detailed error messages with direct links to these fixes if OAuth fails.

### "No agents found"

**Problem:** Server running but can't find agents

**Solutions:**
- Run `python test_server.py` to diagnose
- Check Google Drive for "AI Agents" folder
- Run `python init_drive.py` to recreate structure
- Check `agent-server.log` for Google API errors

### Agent doesn't follow instructions

**Problem:** Agent loads but doesn't behave correctly

**Solutions:**
- Open the agent doc in Google Drive
- Verify it has proper sections (Purpose, Skills, Rules)
- Make sure content isn't empty or malformed
- Try recreating the agent
- Use "Agent Builder" agent to create well-structured agents

### URL changed after restart

**Problem:** Server URL is different now

**Solutions:**
- This is normal with free ngrok
- Copy new URL from server console
- Update your GPT Actions with new URL (Authentication stays the same)
- API key does NOT change when restarting - only URL changes
- **OR** upgrade to ngrok paid ($8/month) for static URL

### "429 Rate Limit Exceeded" Error (NEW)

**Problem:** Too many requests to the API

**Explanation:**
- Rate limits protect against abuse and API quota exhaustion
- Limits: 10 creates/hour, 100 reads/hour per endpoint

**Solutions:**
- Wait an hour and try again
- This is normal protection - not a bug
- If you legitimately need more, you can edit agent_server.py rate limits

### GPT seems slow to respond

**Problem:** Responses take longer than normal ChatGPT

**Causes:**
- First agent load always takes a few seconds (Google API call)
- Large agent documents (>10KB) load slower
- Multiple agents in one conversation adds latency

**Normal behavior:** 2-5 second delay when loading an agent is expected

---

## Advanced Configuration

### Multiple GPTs with Different Default Agents

You can create multiple GPTs that auto-load specific agents:

**Sales GPT:**
Add to instructions:
```
When conversation starts, automatically load the "Sales Email Writer" agent.
```

**Tech GPT:**
Add to instructions:
```
When conversation starts, automatically load the "Technical Documentation" agent.
```

All GPTs share the same server and agent library!

### Custom Agent Templates

Edit the templates in `templates/` folder to change how new agents are structured.

### Security Features (NEW)

The system now includes comprehensive security:

**API Authentication:**
- Every request requires API key in Authorization header
- API key auto-generated on first run
- Stored in config.json (persists across restarts)
- Configure once in ChatGPT Actions, works forever

**Credential Encryption:**
- Google OAuth tokens encrypted using Windows DPAPI
- Stored as credentials.json.encrypted
- Only decryptable on your Windows user account
- Automatic fallback to unencrypted if encryption fails

**Rate Limiting:**
- Protects against abuse and API quota exhaustion
- Different limits for different operations
- See troubleshooting if you hit limits

**Input Validation:**
- All inputs validated before processing
- Prevents injection attacks and malformed data
- Clear error messages for invalid input

**What this means for you:**
- More secure against unauthorized access
- Protected if someone finds your ngrok URL
- Credentials safer if computer is compromised
- Better protection against abuse

---

## URL Management Tips

### Free Ngrok (URL changes each restart)

**Every time you restart:**
1. Copy new URL from server console
2. Open your GPT in ChatGPT
3. Edit → Actions → Update URL
4. Save

**Time required:** ~30 seconds

### Paid Ngrok ($8/month - Static URL)

**One-time setup:**
1. Upgrade at ngrok.com
2. Configure static domain
3. Update GPT Actions once
4. Never update again

**Benefit:** URL never changes, set-and-forget

---

## Using Your Agents

### Basic Usage

**List agents:**
```
What agents do I have?
```

**Load specific agent:**
```
Load the [agent name] agent
```

**Create new agent:**
```
Create an agent for [purpose]
```

### Best Practices

1. **Use Agent Builder First**
   - When creating new agents, load Agent Builder agent
   - It guides you through proper structure
   - Results in better, more effective agents

2. **Name Agents Clearly**
   - Good: "Instagram Caption Writer"
   - Bad: "Agent 1"

3. **Edit in Google Drive**
   - Agents are just Google Docs
   - Edit anytime to refine behavior
   - Changes apply on next load

4. **Test After Creation**
   - Create agent
   - Immediately test it
   - Refine in Google Drive if needed

5. **Organize Agents**
   - Keep Agent Registry doc updated
   - Use folders in Google Drive
   - Archive agents you don't use

---

## Sharing Agents

### Share with Others

1. Open agent doc in Google Drive
2. Click Share
3. Set permissions (View or Edit)
4. Send link
5. They copy to their own Drive and use

### Export Agents

1. Open agent doc
2. File → Download → Plain text (.txt)
3. Share file
4. Others can copy content into new agent

---

## Maintenance

### Daily
- Just start the server when needed
- No maintenance required

### Weekly
- Check `agent-server.log` size
- Restart server to clear memory

### Monthly
- Review and archive unused agents
- Update agent instructions if needed
- Check for software updates

---

## Next Steps

Now that your GPT is configured:

1. ✅ Test all 4 starter agents
2. ✅ Create your first custom agent
3. ✅ Edit an agent in Google Drive to see live updates
4. ✅ Explore the Agent Builder for creating complex agents
5. ✅ Share this with others who might want custom agents

---

## Getting Help

**Server issues:**
- Check: `agent-server.log`
- Run: `python test_server.py`
- See: README.txt troubleshooting section

**Agent issues:**
- Use Agent Builder to create well-structured agents
- Check agent doc formatting in Google Drive
- Test with simple requests first

**ChatGPT issues:**
- Verify Actions URL is correct
- Test connection in Actions panel
- Check server is running

**Still stuck?**
- Review this guide again
- Check all troubleshooting steps
- Contact support (see README.txt)

---

## Summary Checklist

Use this to verify complete setup:

- [ ] Server running (start-server.bat)
- [ ] Ngrok URL copied
- [ ] GPT created in ChatGPT
- [ ] Instructions pasted
- [ ] Actions configured with correct URL
- [ ] Connection test passed
- [ ] Can list agents
- [ ] Can load agent
- [ ] Can create new agent
- [ ] Agent edits in Drive work

If all checked, you're ready to go! 🎉

---

**Congratulations!** Your AI Agent Manager is fully configured and ready to use.

Start by saying to your GPT: "List my agents" and explore from there!
