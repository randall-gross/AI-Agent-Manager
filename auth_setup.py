# auth_setup.py
"""
Google OAuth setup - runs once during initial setup
Opens browser for user to authorize Google Drive access
"""

from google_auth_oauthlib.flow import InstalledAppFlow
import json
import os
import sys
import win32crypt

SCOPES = [
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive.file'
]

def load_oauth_client_config():
    """Load OAuth client configuration from oauth_client.json"""
    if not os.path.exists('oauth_client.json'):
        print()
        print("❌ ERROR: oauth_client.json not found")
        print()
        print("Please create oauth_client.json with your Google Cloud OAuth credentials.")
        print("You can use oauth_client.json.template as a reference.")
        print()
        print("Steps:")
        print("  1. Copy oauth_client.json.template to oauth_client.json")
        print("  2. Edit oauth_client.json and replace placeholders with your actual credentials")
        print("  3. Get credentials from: https://console.cloud.google.com/apis/credentials")
        print()
        sys.exit(1)

    try:
        with open('oauth_client.json', 'r', encoding='utf-8') as f:
            config = json.load(f)

        # Validate config has required fields
        if 'installed' not in config:
            raise ValueError("Missing 'installed' key in oauth_client.json")

        client_id = config['installed'].get('client_id', '')
        if 'YOUR_CLIENT_ID' in client_id or not client_id:
            print()
            print("❌ ERROR: oauth_client.json contains placeholder values")
            print()
            print("Please edit oauth_client.json and replace the placeholders with")
            print("your actual Google Cloud OAuth credentials.")
            print()
            sys.exit(1)

        return config
    except json.JSONDecodeError as e:
        print()
        print(f"❌ ERROR: Invalid JSON in oauth_client.json: {e}")
        print()
        sys.exit(1)
    except Exception as e:
        print()
        print(f"❌ ERROR: Failed to load oauth_client.json: {e}")
        print()
        sys.exit(1)

def encrypt_credentials(credentials_json):
    """Encrypt credentials using Windows DPAPI"""
    try:
        credentials_bytes = credentials_json.encode('utf-8')
        encrypted_data = win32crypt.CryptProtectData(credentials_bytes, "AI Agent Manager", None, None, None, 0)
        return encrypted_data
    except Exception as e:
        print(f"⚠️  Warning: Failed to encrypt credentials: {e}")
        print("   Credentials will be saved unencrypted")
        return None

def main():
    """Run OAuth flow and save credentials"""
    try:
        print("🔐 Starting Google authorization...")
        print()

        # Load OAuth client configuration
        client_config = load_oauth_client_config()

        print("   A browser will open. Please sign in and click 'Allow'")
        print()

        # Run OAuth flow
        flow = InstalledAppFlow.from_client_config(client_config, SCOPES)
        creds = flow.run_local_server(port=8080)

        # Get credentials as JSON
        creds_json = creds.to_json()

        # Try to encrypt credentials
        encrypted = encrypt_credentials(creds_json)

        if encrypted:
            # Save encrypted credentials
            with open('credentials.json.encrypted', 'wb') as f:
                f.write(encrypted)

            print()
            print("✅ Authorization successful!")
            print("✅ Encrypted credentials saved to credentials.json.encrypted")
            print("   (Using Windows DPAPI for encryption)")
        else:
            # Fallback: save unencrypted
            with open('credentials.json', 'w', encoding='utf-8') as f:
                f.write(creds_json)

            print()
            print("✅ Authorization successful!")
            print("✅ Credentials saved to credentials.json")
            print("⚠️  Warning: Credentials are NOT encrypted")

        return 0

    except Exception as e:
        print()
        print(f"❌ Authorization failed: {e}")
        print()
        print("Common issues:")
        print("  - Make sure oauth_client.json exists and has valid credentials")
        print("  - Make sure you clicked 'Allow' in the browser")
        print("  - Check that no firewall is blocking localhost:8080")
        print("  - Try running setup again")
        return 1

if __name__ == '__main__':
    sys.exit(main())
