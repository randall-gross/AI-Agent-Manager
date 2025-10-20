# install_autostart.py
"""
Optional: Install auto-start on Windows boot
Adds server to Windows startup programs
"""

import os
import sys
import winreg

def install_autostart():
    """Add server to Windows startup"""
    try:
        # Get path to start script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        start_script = os.path.join(script_dir, 'start-server.bat')

        if not os.path.exists(start_script):
            print("❌ ERROR: start-server.bat not found")
            return 1

        # Add to Windows startup registry
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r'Software\Microsoft\Windows\CurrentVersion\Run',
            0,
            winreg.KEY_SET_VALUE
        )

        winreg.SetValueEx(
            key,
            'AIAgentServer',
            0,
            winreg.REG_SZ,
            start_script
        )

        winreg.CloseKey(key)

        print("✅ Auto-start installed!")
        print()
        print("The server will now start automatically when you log in.")
        print()
        print("To disable auto-start:")
        print("  1. Press Win+R")
        print("  2. Type: shell:startup")
        print("  3. Delete 'AIAgentServer' shortcut")
        print()

        return 0

    except PermissionError:
        print("❌ ERROR: Permission denied")
        print("   Try running as administrator")
        return 1
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return 1

def uninstall_autostart():
    """Remove server from Windows startup"""
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r'Software\Microsoft\Windows\CurrentVersion\Run',
            0,
            winreg.KEY_SET_VALUE
        )

        try:
            winreg.DeleteValue(key, 'AIAgentServer')
            print("✅ Auto-start removed")
        except FileNotFoundError:
            print("ℹ️  Auto-start was not installed")

        winreg.CloseKey(key)
        return 0

    except Exception as e:
        print(f"❌ ERROR: {e}")
        return 1

def main():
    """Main entry point"""
    print("AI Agent Server - Auto-Start Manager")
    print()
    print("1. Install auto-start")
    print("2. Remove auto-start")
    print("3. Cancel")
    print()

    choice = input("Enter choice (1-3): ").strip()

    if choice == '1':
        return install_autostart()
    elif choice == '2':
        return uninstall_autostart()
    else:
        print("Cancelled")
        return 0

if __name__ == '__main__':
    sys.exit(main())
