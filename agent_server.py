# agent_server.py
"""
Flask server for AI Agent Manager
Provides REST API for ChatGPT to access Google Drive agents
"""

import sys
import io

# Configure stdout/stderr for UTF-8 on Windows (Python 3.14 compatibility)
if sys.platform == 'win32':
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')

from flask import Flask, jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from pyngrok import ngrok
import json
import os
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
import threading
import time
import secrets
import yaml
import re
import html
import win32crypt

# Import version info
from version import VERSION, APP_NAME

# Initialize Flask app
app = Flask(__name__)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per hour"],
    storage_uri="memory://"
)

# Global services
drive_service = None
docs_service = None
config = None
ngrok_url = None
api_key = None

# Setup logging
def setup_logging():
    """Configure logging to file and console"""
    log_formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # File handler with rotation
    file_handler = RotatingFileHandler(
        'agent-server.log',
        maxBytes=1024*1024,  # 1MB
        backupCount=3
    )
    file_handler.setFormatter(log_formatter)
    file_handler.setLevel(logging.INFO)

    # Console handler with UTF-8 encoding for Windows compatibility
    console_handler = logging.StreamHandler()
    # Configure stream to use UTF-8 and replace unmappable characters
    if hasattr(console_handler.stream, 'reconfigure'):
        console_handler.stream.reconfigure(encoding='utf-8', errors='replace')
    console_handler.setFormatter(log_formatter)
    console_handler.setLevel(logging.INFO)

    # Configure root logger
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger

logger = setup_logging()

def generate_api_key():
    """Generate a secure random API key"""
    return secrets.token_urlsafe(32)

def load_or_create_api_key():
    """Load API key from config or generate new one"""
    global api_key

    # Check if config has API key
    if config and 'api_key' in config:
        api_key = config['api_key']
        logger.info("✅ API key loaded from config")
        return

    # Generate new API key
    api_key = generate_api_key()
    logger.info("🔑 Generated new API key")

    # Save to config
    if config:
        config['api_key'] = api_key
        try:
            with open('config.json', 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2)
            logger.info("✅ API key saved to config.json")
        except Exception as e:
            logger.error(f"Failed to save API key: {e}")

def validate_api_key():
    """Validate API key from request header"""
    auth_header = request.headers.get('Authorization', '')

    if not auth_header:
        return False

    # Check format: "Bearer {token}"
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        return False

    token = parts[1]
    return token == api_key

@app.before_request
def check_authentication():
    """Check API key before processing requests"""
    # Skip auth for health endpoint (but limit info shown)
    if request.path == '/health':
        return None

    # Validate API key
    if not validate_api_key():
        logger.warning(f"Unauthorized access attempt from {get_remote_address()}")
        return jsonify({'error': 'Unauthorized - Invalid or missing API key'}), 401

    return None

def load_config():
    """Load configuration from config.json"""
    try:
        with open('config.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error("config.json not found - run setup first")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Invalid config.json: {e}")
        return None

def decrypt_credentials(encrypted_data):
    """Decrypt credentials using Windows DPAPI"""
    try:
        # CryptUnprotectData returns (description, decrypted_bytes) tuple
        description, decrypted_bytes = win32crypt.CryptUnprotectData(encrypted_data, None, None, None, 0)
        return decrypted_bytes.decode('utf-8')
    except Exception as e:
        logger.error(f"Failed to decrypt credentials: {e}")
        return None

def load_credentials():
    """Load Google API credentials (encrypted or plain)"""
    try:
        # Try encrypted credentials first
        if os.path.exists('credentials.json.encrypted'):
            logger.info("Loading encrypted credentials...")
            with open('credentials.json.encrypted', 'rb') as f:
                encrypted_data = f.read()

            creds_json = decrypt_credentials(encrypted_data)
            if creds_json:
                creds = Credentials.from_authorized_user_info(json.loads(creds_json))
                logger.info("✅ Encrypted credentials loaded successfully")
                return creds
            else:
                logger.error("Failed to decrypt credentials.json.encrypted")
                return None

        # Fallback to unencrypted credentials
        if os.path.exists('credentials.json'):
            logger.warning("⚠️  Loading unencrypted credentials (security risk)")
            creds = Credentials.from_authorized_user_file('credentials.json')
            return creds

        logger.error("No credentials file found - run setup first")
        return None

    except FileNotFoundError:
        logger.error("credentials file not found - run setup first")
        return None
    except Exception as e:
        logger.error(f"Failed to load credentials: {e}")
        return None

def validate_agent_name(name):
    """Validate agent name"""
    if not name or not isinstance(name, str):
        return False, "Agent name is required"

    if len(name) < 3:
        return False, "Agent name must be at least 3 characters"

    if len(name) > 200:
        return False, "Agent name must be 200 characters or less"

    # Allow alphanumeric, spaces, hyphens, underscores
    if not re.match(r'^[a-zA-Z0-9\s\-_]+$', name):
        return False, "Agent name can only contain letters, numbers, spaces, hyphens, and underscores"

    return True, None

def validate_agent_id(agent_id):
    """Validate Google Doc ID format"""
    if not agent_id or not isinstance(agent_id, str):
        return False, "Agent ID is required"

    # Google Doc IDs are alphanumeric with hyphens and underscores, typically 44 chars
    if not re.match(r'^[a-zA-Z0-9\-_]{20,100}$', agent_id):
        return False, "Invalid agent ID format"

    return True, None

def validate_text_length(text, field_name, max_length=51200):
    """Validate text field length (default 50KB)"""
    if text is None:
        return True, None

    if not isinstance(text, str):
        return False, f"{field_name} must be a string"

    if len(text) > max_length:
        return False, f"{field_name} exceeds maximum length of {max_length} characters"

    return True, None

def sanitize_text(text):
    """Sanitize text input to prevent injection"""
    if text is None:
        return None
    if isinstance(text, str):
        return html.escape(text)
    if isinstance(text, list):
        return [html.escape(str(item)) for item in text]
    return text

def initialize_services():
    """Initialize Google API services"""
    global drive_service, docs_service, config

    logger.info("Initializing services...")

    # Load config
    config = load_config()
    if not config:
        logger.error("Failed to load config")
        return False

    # Load or generate API key
    load_or_create_api_key()

    # Load credentials
    creds = load_credentials()
    if not creds:
        logger.error("Failed to load credentials")
        return False

    # Build services
    try:
        drive_service = build('drive', 'v3', credentials=creds)
        docs_service = build('docs', 'v1', credentials=creds)
        logger.info("✅ Google API services initialized")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")
        return False

def start_ngrok():
    """Start ngrok tunnel"""
    global ngrok_url

    try:
        logger.info("Starting ngrok tunnel...")

        # Load authtoken from ngrok.yml if not already configured
        from pyngrok import conf
        config_obj = conf.get_default()

        if not config_obj.auth_token:
            ngrok_config_path = os.path.expanduser('~/.ngrok2/ngrok.yml')

            if os.path.exists(ngrok_config_path):
                try:
                    with open(ngrok_config_path, 'r') as f:
                        ngrok_config = yaml.safe_load(f)
                        if ngrok_config and 'authtoken' in ngrok_config:
                            ngrok.set_auth_token(ngrok_config['authtoken'])
                            logger.info("✅ Loaded authtoken from ~/.ngrok2/ngrok.yml")
                        else:
                            logger.error("❌ No authtoken found in ngrok.yml")
                            logger.error("Please run setup.ps1 to configure ngrok")
                            return False
                except Exception as e:
                    logger.error(f"Failed to read ngrok.yml: {e}")
                    return False
            else:
                logger.error("❌ No ngrok configuration found at ~/.ngrok2/ngrok.yml")
                logger.error("Please run setup.ps1 to configure ngrok")
                return False

        # Start tunnel
        tunnel = ngrok.connect(3000, bind_tls=True)
        ngrok_url = tunnel.public_url

        logger.info(f"✅ Ngrok tunnel started: {ngrok_url}")

        # Save URL to config
        if config:
            config['ngrok_url'] = ngrok_url
            with open('config.json', 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2)

        # Write URL and API key to file for easy copying
        with open('GPT-CONFIG.txt', 'w', encoding='utf-8') as f:
            f.write(f"AI Agent Manager - ChatGPT Configuration\n")
            f.write(f"="*60 + "\n\n")
            f.write(f"Server URL: {ngrok_url}\n\n")
            f.write(f"API Key: {api_key}\n\n")
            f.write(f"IMPORTANT:\n")
            f.write(f"1. Copy the Server URL for the 'servers' section in gpt-actions.yaml\n")
            f.write(f"2. Copy the API Key for the Authorization header in ChatGPT Actions\n\n")
            f.write(f"See GPT-SETUP-GUIDE.md for detailed setup instructions.\n\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            f.write(f"Security Status:\n")
            if os.path.exists('credentials.json.encrypted'):
                f.write(f"  ✓ Credentials encrypted (Windows DPAPI)\n")
            else:
                f.write(f"  ⚠ Credentials NOT encrypted\n")
            f.write(f"  ✓ API authentication enabled\n")
            f.write(f"  ✓ Rate limiting active\n")
            f.write(f"  ✓ Input validation enforced\n")

        return True

    except Exception as e:
        logger.error(f"Failed to start ngrok: {e}")
        logger.error("Make sure ngrok authtoken is configured")
        return False

# API Routes

@app.route('/health', methods=['GET'])
@limiter.limit("30 per hour")
def health_check():
    """Health check endpoint (limited info without auth)"""
    try:
        # Show limited info without authentication
        auth_header = request.headers.get('Authorization', '')
        is_authenticated = validate_api_key() if auth_header else False

        if is_authenticated:
            # Full details for authenticated requests
            drive_status = 'connected'
            try:
                drive_service.about().get(fields='user').execute()
            except:
                drive_status = 'disconnected'

            return jsonify({
                'status': 'healthy',
                'version': VERSION,
                'app_name': APP_NAME,
                'google_drive': drive_status,
                'agent_folder': config.get('agent_folder_name', 'Unknown'),
                'ngrok_url': ngrok_url,
                'authenticated': True
            })
        else:
            # Limited info for unauthenticated requests
            return jsonify({
                'status': 'healthy',
                'version': VERSION,
                'app_name': APP_NAME,
                'authenticated': False,
                'message': 'Use Authorization header for full details'
            })

    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

@app.route('/agents', methods=['GET'])
@limiter.limit("100 per hour")
def list_agents():
    """List all available agents"""
    try:
        logger.info("Listing agents...")

        folder_id = config.get('agent_folder_id')
        if not folder_id:
            return jsonify({'error': 'Agent folder not configured'}), 500

        # Query for all docs in agents folder
        query = f"'{folder_id}' in parents and mimeType='application/vnd.google-apps.document' and trashed=false"

        results = drive_service.files().list(
            q=query,
            fields='files(id, name, modifiedTime)',
            orderBy='name'
        ).execute()

        files = results.get('files', [])

        agents = [{
            'id': file['id'],
            'name': file['name'],
            'modified': file.get('modifiedTime')
        } for file in files]

        logger.info(f"Found {len(agents)} agents")

        return jsonify({
            'agents': agents,
            'count': len(agents)
        })

    except HttpError as e:
        logger.error(f"Google API error: {e}")
        return jsonify({'error': 'Failed to list agents', 'details': str(e)}), 500
    except Exception as e:
        logger.error(f"Error listing agents: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/agents/<agent_id>', methods=['GET'])
@limiter.limit("100 per hour")
def get_agent(agent_id):
    """Get specific agent's prompt"""
    try:
        # Validate agent ID
        is_valid, error_msg = validate_agent_id(agent_id)
        if not is_valid:
            return jsonify({'error': error_msg}), 400

        logger.info(f"Loading agent: {agent_id}")

        # Get document content
        doc = docs_service.documents().get(documentId=agent_id).execute()

        # Extract text content
        content = []
        for element in doc.get('body', {}).get('content', []):
            if 'paragraph' in element:
                for text_run in element['paragraph'].get('elements', []):
                    if 'textRun' in text_run:
                        content.append(text_run['textRun']['content'])

        prompt = ''.join(content)

        # Get metadata
        file_metadata = drive_service.files().get(
            fileId=agent_id,
            fields='name, modifiedTime'
        ).execute()

        logger.info(f"Loaded agent: {file_metadata['name']}")

        return jsonify({
            'id': agent_id,
            'name': file_metadata['name'],
            'prompt': prompt,
            'modified': file_metadata.get('modifiedTime'),
            'length': len(prompt)
        })

    except HttpError as e:
        logger.error(f"Google API error: {e}")
        return jsonify({'error': 'Agent not found or access denied'}), 404
    except Exception as e:
        logger.error(f"Error loading agent: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/agents', methods=['POST'])
@limiter.limit("10 per hour")
def create_agent():
    """Create a new agent"""
    try:
        data = request.get_json()

        if not data or 'name' not in data:
            return jsonify({'error': 'Agent name is required'}), 400

        # Validate agent name
        agent_name = data['name']
        is_valid, error_msg = validate_agent_name(agent_name)
        if not is_valid:
            return jsonify({'error': error_msg}), 400

        # Validate text field lengths
        for field in ['purpose', 'tone', 'output_format']:
            if field in data:
                is_valid, error_msg = validate_text_length(data[field], field)
                if not is_valid:
                    return jsonify({'error': error_msg}), 400

        # Validate list field lengths
        for field in ['skills', 'rules']:
            if field in data:
                if isinstance(data[field], list):
                    for item in data[field]:
                        is_valid, error_msg = validate_text_length(item, f"{field} item", 10240)
                        if not is_valid:
                            return jsonify({'error': error_msg}), 400
                else:
                    is_valid, error_msg = validate_text_length(data[field], field)
                    if not is_valid:
                        return jsonify({'error': error_msg}), 400

        logger.info(f"Creating agent: {agent_name}")

        # Sanitize all inputs
        agent_name_safe = sanitize_text(agent_name)

        # Build agent content from structured data
        content_parts = [f"# {agent_name_safe}\n\n"]

        if 'purpose' in data:
            purpose_safe = sanitize_text(data['purpose'])
            content_parts.append(f"## Purpose\n{purpose_safe}\n\n")

        if 'skills' in data:
            content_parts.append("## Key Skills\n")
            if isinstance(data['skills'], list):
                for skill in data['skills']:
                    skill_safe = sanitize_text(skill)
                    content_parts.append(f"- {skill_safe}\n")
            else:
                skills_safe = sanitize_text(data['skills'])
                content_parts.append(f"{skills_safe}\n")
            content_parts.append("\n")

        if 'rules' in data:
            content_parts.append("## Rules\n")
            if isinstance(data['rules'], list):
                for rule in data['rules']:
                    rule_safe = sanitize_text(rule)
                    content_parts.append(f"- {rule_safe}\n")
            else:
                rules_safe = sanitize_text(data['rules'])
                content_parts.append(f"{rules_safe}\n")
            content_parts.append("\n")

        if 'tone' in data:
            tone_safe = sanitize_text(data['tone'])
            content_parts.append(f"## Tone & Style\n{tone_safe}\n\n")

        if 'output_format' in data:
            format_safe = sanitize_text(data['output_format'])
            content_parts.append(f"## Output Format\n{format_safe}\n\n")

        content = ''.join(content_parts)

        # Create document
        doc = docs_service.documents().create(body={
            'title': agent_name
        }).execute()

        doc_id = doc['documentId']

        # Write content
        docs_service.documents().batchUpdate(
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
        folder_id = config.get('agent_folder_id')
        if folder_id:
            drive_service.files().update(
                fileId=doc_id,
                addParents=folder_id,
                fields='id, parents'
            ).execute()

        logger.info(f"✅ Created agent: {agent_name} (ID: {doc_id})")

        return jsonify({
            'id': doc_id,
            'name': agent_name,
            'url': f"https://docs.google.com/document/d/{doc_id}",
            'message': 'Agent created successfully'
        }), 201

    except HttpError as e:
        logger.error(f"Google API error: {e}")
        return jsonify({'error': 'Failed to create agent', 'details': str(e)}), 500
    except Exception as e:
        logger.error(f"Error creating agent: {e}")
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(429)
def rate_limit_exceeded(e):
    """Handle rate limit errors"""
    logger.warning(f"Rate limit exceeded from {get_remote_address()}")
    return jsonify({
        'error': 'Rate limit exceeded',
        'message': 'Too many requests. Please try again later.',
        'retry_after': e.description
    }), 429

@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors"""
    logger.error(f"Server error: {e}")
    return jsonify({'error': 'Internal server error'}), 500

def print_startup_banner():
    """Print startup information"""
    print()
    print("=" * 70)
    print(f"  {APP_NAME} v{VERSION}")
    print("=" * 70)
    print()
    print(f"✅ Server running on: http://localhost:3000")
    print(f"✅ Public URL: {ngrok_url}")
    print()
    print("🔑 API KEY (IMPORTANT - COPY THIS):")
    print(f"   {api_key}")
    print()
    print("📋 COPY THESE FOR YOUR CHATGPT:")
    print(f"   Server URL: {ngrok_url}")
    print(f"   API Key: {api_key}")
    print()
    print("📄 Configuration saved to: GPT-CONFIG.txt")
    print("📖 Setup guide: GPT-SETUP-GUIDE.md")
    print()
    print("🔒 Security enabled:")
    print("   ✓ API authentication required")
    print("   ✓ Rate limiting active")
    print("   ✓ Input validation enforced")
    if os.path.exists('credentials.json.encrypted'):
        print("   ✓ Credentials encrypted (DPAPI)")
    else:
        print("   ⚠ Credentials NOT encrypted")
    print()
    print("💡 TIP: Use the 'Agent Builder' agent when creating new agents!")
    print()
    print("Server logs: agent-server.log")
    print("Press Ctrl+C to stop server")
    print("=" * 70)
    print()

def main():
    """Main entry point"""
    try:
        logger.info(f"Starting {APP_NAME} v{VERSION}")

        # Initialize services
        if not initialize_services():
            print()
            print("❌ Failed to initialize services")
            print("   Make sure you've run setup.ps1 first")
            print()
            return 1

        # Start ngrok
        if not start_ngrok():
            print()
            print("❌ Failed to start ngrok tunnel")
            print("   Make sure ngrok is configured with authtoken")
            print("   Run: ngrok config add-authtoken YOUR_TOKEN")
            print()
            return 1

        # Print startup banner
        print_startup_banner()

        # Start Flask server
        app.run(
            host='0.0.0.0',
            port=3000,
            debug=False,
            use_reloader=False
        )

        return 0

    except KeyboardInterrupt:
        print()
        print()
        logger.info("Server stopped by user")
        print("✅ Server stopped")
        return 0
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        print()
        print(f"❌ Fatal error: {e}")
        print("   Check agent-server.log for details")
        print()
        return 1

if __name__ == '__main__':
    sys.exit(main())
