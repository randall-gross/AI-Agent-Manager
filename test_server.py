# test_server.py
"""
Test script to verify server is working correctly
Checks all components: server, Google Drive, ngrok, agents
"""

import requests
import json
import time
import sys
from pathlib import Path

def print_header(text):
    """Print formatted header"""
    print()
    print("=" * 60)
    print(f"  {text}")
    print("=" * 60)
    print()

def print_test(name, passed, details=""):
    """Print test result"""
    status = "✅" if passed else "❌"
    print(f"{status} {name}")
    if details:
        print(f"   {details}")

def test_files_exist():
    """Test that required files exist"""
    print("Checking required files...")

    required_files = [
        'config.json',
        'credentials.json',
        'agent_server.py',
        'requirements.txt'
    ]

    all_exist = True
    for file in required_files:
        exists = Path(file).exists()
        print_test(f"File exists: {file}", exists)
        if not exists:
            all_exist = False

    return all_exist

def test_server_running():
    """Test if server is accessible"""
    print()
    print("Checking server status...")

    try:
        response = requests.get('http://localhost:3000/health', timeout=5)

        if response.status_code == 200:
            data = response.json()
            print_test("Server is running", True)
            print_test("Google Drive connected", data.get('google_drive') == 'connected')

            # Print server info
            print()
            print("Server Information:")
            print(f"   Status: {data.get('status')}")
            print(f"   Agent Folder: {data.get('agent_folder')}")
            print(f"   Public URL: {data.get('ngrok_url')}")
            print(f"   Version: {data.get('version')}")

            return True, data.get('ngrok_url')
        else:
            print_test("Server is running", False, f"Returned status {response.status_code}")
            return False, None

    except requests.exceptions.ConnectionError:
        print_test("Server is running", False, "Can't connect - is server started?")
        print()
        print("   Start the server with: start-server.bat")
        return False, None
    except requests.exceptions.Timeout:
        print_test("Server is running", False, "Connection timeout")
        return False, None
    except Exception as e:
        print_test("Server is running", False, str(e))
        return False, None

def test_agents():
    """Test agent listing"""
    print()
    print("Checking agents...")

    try:
        response = requests.get('http://localhost:3000/agents', timeout=10)

        if response.status_code == 200:
            data = response.json()
            agents = data.get('agents', [])

            # Updated: Expect 4 starter agents (including Agent Builder)
            expected_count = 4
            has_correct_count = len(agents) >= expected_count

            print_test(f"Found {len(agents)} agents", has_correct_count,
                      f"Expected at least {expected_count} starter agents")

            if agents:
                print()
                print("Available agents:")
                for agent in agents:
                    print(f"   - {agent['name']} (ID: {agent['id'][:20]}...)")

                # Check for Agent Builder specifically
                agent_names = [a['name'] for a in agents]
                has_agent_builder = 'Agent Builder' in agent_names
                print()
                print_test("Agent Builder found", has_agent_builder,
                          "This agent helps create new agents")

            return has_correct_count
        else:
            print_test("List agents", False, f"Status {response.status_code}")
            return False

    except Exception as e:
        print_test("List agents", False, str(e))
        return False

def test_agent_load():
    """Test loading an agent"""
    print()
    print("Testing agent load...")

    try:
        # Get first agent
        response = requests.get('http://localhost:3000/agents', timeout=10)
        if response.status_code != 200:
            print_test("Load agent", False, "Couldn't list agents")
            return False

        agents = response.json().get('agents', [])
        if not agents:
            print_test("Load agent", False, "No agents available to test")
            return False

        test_agent = agents[0]
        agent_id = test_agent['id']

        # Load the agent
        response = requests.get(f'http://localhost:3000/agents/{agent_id}', timeout=10)

        if response.status_code == 200:
            data = response.json()
            has_prompt = bool(data.get('prompt'))

            print_test(f"Load agent: {test_agent['name']}", has_prompt)

            if has_prompt:
                prompt_preview = data['prompt'][:100].replace('\n', ' ')
                print(f"   Prompt preview: {prompt_preview}...")

            return has_prompt
        else:
            print_test("Load agent", False, f"Status {response.status_code}")
            return False

    except Exception as e:
        print_test("Load agent", False, str(e))
        return False

def main():
    """Run all tests"""
    print_header("AI Agent Server - System Test")

    # Test 1: Files
    files_ok = test_files_exist()
    if not files_ok:
        print()
        print("⚠️  Some files are missing. Did you run setup.ps1?")
        return 1

    # Test 2: Server
    server_ok, ngrok_url = test_server_running()
    if not server_ok:
        print()
        print("⚠️  Server is not running. Start it with start-server.bat")
        return 1

    # Test 3: Agents
    agents_ok = test_agents()

    # Test 4: Load agent
    load_ok = test_agent_load()

    # Summary
    print_header("Test Summary")

    all_passed = files_ok and server_ok and agents_ok and load_ok

    if all_passed:
        print("🎉 All tests passed!")
        print()
        print("Your system is ready to use!")
        print()
        print("Next steps:")
        print("  1. Copy this URL for your ChatGPT:")
        print(f"     {ngrok_url}")
        print()
        print("  2. See GPT-CONFIG.txt for setup instructions")
        print()
        print("💡 TIP: Use the 'Agent Builder' agent when creating new agents!")
        print()
    else:
        print("⚠️  Some tests failed")
        print()
        print("Check the errors above and:")
        print("  - Make sure server is running (start-server.bat)")
        print("  - Check agent-server.log for errors")
        print("  - Try running setup.ps1 again")
        print()

    return 0 if all_passed else 1

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nTest cancelled by user")
        sys.exit(1)
