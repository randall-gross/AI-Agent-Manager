# init_drive.py
"""
Initialize Google Drive structure
Creates folders, starter agents, and registry doc
"""

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import json
import sys
import os
import win32crypt

def load_template(template_name):
    """Load agent template from templates folder"""
    template_path = os.path.join('templates', f'{template_name}.txt')
    try:
        with open(template_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        # Return basic template if file not found
        return f"""# {template_name.replace('_', ' ').title()} Agent

## Purpose
This is a starter agent. Edit this document to customize the agent's behavior.

## Key Skills
- Add skills here
- One per line

## Rules
- Add rules here
- One per line

## Tone & Style
Describe the communication style here.

## Output Format
Describe how the agent should format responses.
"""

def decrypt_credentials(encrypted_data):
    """Decrypt credentials using Windows DPAPI"""
    try:
        # CryptUnprotectData returns (description, decrypted_bytes) tuple
        description, decrypted_bytes = win32crypt.CryptUnprotectData(encrypted_data, None, None, None, 0)
        return decrypted_bytes.decode('utf-8')
    except Exception as e:
        print(f"❌ Failed to decrypt credentials: {e}")
        return None

def load_credentials():
    """Load Google API credentials (encrypted or plain)"""
    try:
        # Try encrypted credentials first
        if os.path.exists('credentials.json.encrypted'):
            print("📦 Loading encrypted credentials...")
            with open('credentials.json.encrypted', 'rb') as f:
                encrypted_data = f.read()

            creds_json = decrypt_credentials(encrypted_data)
            if creds_json:
                creds = Credentials.from_authorized_user_info(json.loads(creds_json))
                print("✅ Encrypted credentials loaded successfully")
                return creds
            else:
                print("❌ Failed to decrypt credentials.json.encrypted")
                return None

        # Fallback to unencrypted credentials
        if os.path.exists('credentials.json'):
            print("⚠️  Loading unencrypted credentials (security risk)")
            creds = Credentials.from_authorized_user_file('credentials.json')
            return creds

        print("❌ No credentials file found - run setup first")
        return None

    except Exception as e:
        print(f"❌ Error loading credentials: {e}")
        return None

def create_starter_agent(docs, drive, folder_id, agent_name, template_name):
    """Create a starter agent doc with template content"""
    try:
        # Create doc
        doc = docs.documents().create(body={
            'title': agent_name
        }).execute()

        doc_id = doc['documentId']

        # Load template content
        content = load_template(template_name)

        # Write content to doc
        docs.documents().batchUpdate(
            documentId=doc_id,
            body={
                'requests': [{
                    'insertText': {
                        'location': {'index': 1},
                        'text': content
                    }
                }]
            }
        ).execute()

        # Move to agents folder
        drive.files().update(
            fileId=doc_id,
            addParents=folder_id,
            fields='id, parents'
        ).execute()

        print(f"   ✅ Created: {agent_name}")
        return doc_id

    except HttpError as e:
        print(f"   ❌ Failed to create {agent_name}: {e}")
        return None

def main():
    """Initialize Google Drive folder structure"""
    try:
        # Load credentials
        creds = load_credentials()
        if not creds:
            print("❌ ERROR: Failed to load credentials")
            return 1

        # Build services
        drive = build('drive', 'v3', credentials=creds)
        docs = build('docs', 'v1', credentials=creds)

        print("📁 Creating folder structure in Google Drive...")
        print()

        # Create main folder
        main_folder = drive.files().create(body={
            'name': 'AI Agents',
            'mimeType': 'application/vnd.google-apps.folder'
        }, fields='id').execute()

        main_folder_id = main_folder['id']
        print(f"✅ Created main folder: AI Agents")

        # Create agents subfolder
        agents_folder = drive.files().create(body={
            'name': 'agents',
            'mimeType': 'application/vnd.google-apps.folder',
            'parents': [main_folder_id]
        }, fields='id').execute()

        agents_folder_id = agents_folder['id']
        print(f"✅ Created agents folder")

        # Create registry doc
        print()
        print("📄 Creating agent registry...")
        registry = docs.documents().create(body={
            'title': 'Agent Registry'
        }).execute()

        registry_id = registry['documentId']

        # Move registry to main folder
        drive.files().update(
            fileId=registry_id,
            addParents=main_folder_id,
            fields='id, parents'
        ).execute()

        # Write initial registry content
        registry_content = """AGENT REGISTRY
Last Updated: Auto-generated

This document lists all available AI agents. Each agent has its own Google Doc with complete instructions.

AVAILABLE AGENTS
================

(Agents will be automatically listed here as they're created)

---

STARTER AGENTS

Agent Builder
- Purpose: Guide users through creating well-structured, effective AI agents
- Use for: Creating new agents, improving existing agents, agent best practices
- Special: Use this agent FIRST when creating new agents!

Sales Email Writer
- Purpose: Write compelling sales emails and outreach
- Use for: Cold emails, follow-ups, proposals

Technical Documentation
- Purpose: Create clear technical documentation
- Use for: API docs, code explanations, guides

Customer Support
- Purpose: Handle customer inquiries and support
- Use for: Troubleshooting, FAQs, customer communication

---

BEST PRACTICE: When creating a new agent, load the "Agent Builder" agent first!
It will guide you through creating well-structured, effective agents.

To create a new agent manually, tell your ChatGPT: "Create a new agent for [purpose]"
To edit an agent, open its document in Google Drive and make changes.
"""

        docs.documents().batchUpdate(
            documentId=registry_id,
            body={
                'requests': [{
                    'insertText': {
                        'location': {'index': 1},
                        'text': registry_content
                    }
                }]
            }
        ).execute()

        print(f"✅ Created agent registry")

        # Create starter agents (including Agent Builder as first agent)
        print()
        print("🤖 Creating starter agents...")

        starter_agents = [
            ('Agent Builder', 'agent_builder'),
            ('Sales Email Writer', 'sales_agent'),
            ('Technical Documentation', 'technical_agent'),
            ('Customer Support', 'support_agent')
        ]

        for agent_name, template_name in starter_agents:
            create_starter_agent(docs, drive, agents_folder_id, agent_name, template_name)

        # Get user's email
        about = drive.about().get(fields='user').execute()
        user_email = about['user'].get('emailAddress', 'Unknown')

        # Save configuration
        config = {
            'agent_folder_id': agents_folder_id,
            'agent_folder_name': 'AI Agents',
            'registry_doc_id': registry_id,
            'main_folder_id': main_folder_id,
            'user_email': user_email,
            'version': '1.0.0'
        }

        with open('config.json', 'w') as f:
            json.dump(config, f, indent=2)

        print()
        print("=" * 60)
        print("✅ Drive setup complete!")
        print("=" * 60)
        print()
        print(f"📁 Main folder: https://drive.google.com/drive/folders/{main_folder_id}")
        print(f"📄 Registry: https://docs.google.com/document/d/{registry_id}")
        print(f"👤 User: {user_email}")
        print()
        print("💡 TIP: Use the 'Agent Builder' agent when creating new agents!")
        print()

        return 0

    except HttpError as e:
        print(f"❌ ERROR: Google API error: {e}")
        return 1

    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
