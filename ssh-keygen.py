#!/usr/bin/env python3

"""
Multi-Cloud SSH Key Generator with Visualization
Generates SSH keys for AWS, Azure, GCP, OCI with ASCII graphs
Compatible with: Windows, macOS, Linux
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime

# Colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    NC = '\033[0m'  # No Color

# Configuration
HOME = Path.home()
KEY_DIR = HOME / '.ssh'
KEY_TYPE = 'ed25519'  # or 'rsa'
CLOUDS = ['aws', 'azure', 'gcp', 'oci']

def print_header():
    """Print header with ASCII art"""
    os.system('clear' if os.name == 'posix' else 'cls')
    print("""
╔════════════════════════════════════════════════════════════════════════════╗
║       Multi-Cloud SSH Key Generator v1.0                                  ║
║       AWS | Azure | GCP | OCI                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
""")

def print_graph():
    """Print ASCII graph of cloud hierarchy"""
    graph = """
    ┌─────────────┐
    │    AWS      │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │   Azure     │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │     GCP     │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │     OCI     │
    │  Key Gen    │
    └─────────────┘
"""
    print(graph)

def progress_bar(duration=3):
    """Display progress bar"""
    import time
    steps = 20
    for i in range(steps + 1):
        percent = (i / steps) * 100
        filled = int(i)
        bar = '█' * filled + '-' * (steps - filled)
        print(f'\rProgress: [{bar}] {percent:.0f}%', end='', flush=True)
        time.sleep(duration / steps)
    print()

def generate_key(cloud):
    """Generate SSH key for cloud provider"""
    key_path = KEY_DIR / f'{cloud}_id_{KEY_TYPE}'
    
    print(f"\n{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.CYAN}Generating SSH key for {cloud.upper()}{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")
    
    # Check if key exists
    if key_path.exists():
        print(f"{Colors.YELLOW}⚠ Key already exists: {key_path}{Colors.NC}")
        response = input("Overwrite? (y/n): ").strip().lower()
        if response != 'y':
            print(f"{Colors.YELLOW}Skipped.{Colors.NC}")
            return
    
    # Ensure directory exists
    KEY_DIR.mkdir(parents=True, exist_ok=True)
    KEY_DIR.chmod(0o700)
    
    # Generate key
    comment = f"multi-cloud-{cloud}@{datetime.now().strftime('%Y-%m-%d')}"
    
    try:
        if KEY_TYPE == 'rsa':
            cmd = ['ssh-keygen', '-t', 'rsa', '-b', '4096', '-f', str(key_path), '-N', '', '-C', comment]
        else:
            cmd = ['ssh-keygen', '-t', 'ed25519', '-f', str(key_path), '-N', '', '-C', comment]
        
        subprocess.run(cmd, capture_output=True, check=True)
        
        # Set permissions
        os.chmod(str(key_path), 0o600)
        os.chmod(str(key_path.with_suffix('.pub')), 0o644)
        
        print(f"{Colors.GREEN}✓ Key generated successfully{Colors.NC}\n")
        
        # Display key details
        print(f"{Colors.MAGENTA}Key Details:{Colors.NC}")
        print(f"  Private: {Colors.GREEN}{key_path}{Colors.NC}")
        print(f"  Public:  {Colors.GREEN}{key_path}.pub{Colors.NC}\n")
        
        # Show fingerprint
        print(f"{Colors.MAGENTA}Fingerprint (SHA256):{Colors.NC}")
        result = subprocess.run(['ssh-keygen', '-l', '-f', str(key_path)], 
                              capture_output=True, text=True)
        fingerprint = result.stdout.split()[1]
        print(f"  {fingerprint}\n")
        
        # Show public key preview
        with open(f"{key_path}.pub", 'r') as f:
            pub_key = f.read().strip()[:50]
        print(f"{Colors.MAGENTA}Public Key (first 50 chars):{Colors.NC}")
        print(f"  {pub_key}...\n")
        
        progress_bar()
        
    except subprocess.CalledProcessError as e:
        print(f"{Colors.RED}✗ Failed to generate key: {e}{Colors.NC}")
    except FileNotFoundError:
        print(f"{Colors.RED}✗ ssh-keygen not found. Please install OpenSSH.{Colors.NC}")

def show_statistics():
    """Display key statistics"""
    print(f"\n{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.CYAN}Key Statistics{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")
    
    total_keys = 0
    rsa_count = 0
    ed25519_count = 0
    
    for cloud in CLOUDS:
        for key_file in KEY_DIR.glob(f'{cloud}_id_*'):
            if not key_file.name.endswith('.pub'):
                total_keys += 1
                if 'rsa' in key_file.name:
                    rsa_count += 1
                elif 'ed25519' in key_file.name:
                    ed25519_count += 1
    
    print(f"""
┌─────────────────────────────────┐
│  Total Keys Generated: {total_keys:<8} │
│  ED25519 Keys: {ed25519_count:<18} │
│  RSA Keys: {rsa_count:<23} │
└─────────────────────────────────┘
""")
    
    # Bar chart by cloud
    print(f"{Colors.MAGENTA}Keys by Cloud Provider:{Colors.NC}\n")
    
    for cloud in CLOUDS:
        count = 1 if (KEY_DIR / f'{cloud}_id_{KEY_TYPE}').exists() else 0
        bar = '█' * (count * 10)
        print(f"{cloud.upper():<8} │ {bar} {count}")
    print()

def show_key_locations():
    """Display SSH key file locations"""
    print(f"\n{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.CYAN}SSH Key Locations{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")
    
    for cloud in CLOUDS:
        key_path = KEY_DIR / f'{cloud}_id_{KEY_TYPE}'
        if key_path.exists():
            size = key_path.stat().st_size / 1024  # KB
            print(f"{Colors.GREEN}✓{Colors.NC} {cloud.upper():<8} Private: {Colors.GREEN}{key_path}{Colors.NC} ({size:.1f} KB)")
            print(f"         Public:  {Colors.GREEN}{key_path}.pub{Colors.NC}")
        else:
            print(f"{Colors.YELLOW}○{Colors.NC} {cloud.upper()}: Not generated yet")
        print()

def add_to_agent():
    """Add keys to SSH agent"""
    print(f"\n{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.CYAN}Adding Keys to SSH Agent{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")
    
    try:
        # Start SSH agent
        subprocess.run(['ssh-agent', '-s'], capture_output=True)
        
        for cloud in CLOUDS:
            key_path = KEY_DIR / f'{cloud}_id_{KEY_TYPE}'
            if key_path.exists():
                subprocess.run(['ssh-add', str(key_path)], capture_output=True)
                print(f"{Colors.GREEN}✓ Added {cloud.upper()} key to agent{Colors.NC}")
        
        print()
        print(f"{Colors.MAGENTA}SSH Agent Keys:{Colors.NC}")
        result = subprocess.run(['ssh-add', '-l'], capture_output=True, text=True)
        for line in result.stdout.strip().split('\n'):
            print(f"  {line}")
        print()
        
    except FileNotFoundError:
        print(f"{Colors.RED}✗ ssh-add not found. Please install OpenSSH.{Colors.NC}")

def show_menu():
    """Display main menu"""
    print()
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.CYAN}Select Option:{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")
    print(f"  {Colors.CYAN}1){Colors.NC} Generate All Keys (AWS, Azure, GCP, OCI)")
    print(f"  {Colors.CYAN}2){Colors.NC} Generate AWS Key")
    print(f"  {Colors.CYAN}3){Colors.NC} Generate Azure Key")
    print(f"  {Colors.CYAN}4){Colors.NC} Generate GCP Key")
    print(f"  {Colors.CYAN}5){Colors.NC} Generate OCI Key")
    print(f"  {Colors.CYAN}6){Colors.NC} View Key Locations")
    print(f"  {Colors.CYAN}7){Colors.NC} Show Statistics")
    print(f"  {Colors.CYAN}8){Colors.NC} Add Keys to SSH Agent")
    print(f"  {Colors.CYAN}9){Colors.NC} Exit")
    print()

def main():
    """Main function"""
    global KEY_TYPE
    
    # Create SSH directory if needed
    KEY_DIR.mkdir(parents=True, exist_ok=True)
    KEY_DIR.chmod(0o700)
    
    while True:
        print_header()
        print_graph()
        show_menu()
        
        choice = input("Enter choice: ").strip()
        
        if choice == '1':
            for cloud in CLOUDS:
                generate_key(cloud)
        elif choice == '2':
            generate_key('aws')
        elif choice == '3':
            generate_key('azure')
        elif choice == '4':
            generate_key('gcp')
        elif choice == '5':
            generate_key('oci')
        elif choice == '6':
            print_header()
            show_key_locations()
        elif choice == '7':
            print_header()
            show_statistics()
        elif choice == '8':
            print_header()
            add_to_agent()
        elif choice == '9':
            print(f"\n{Colors.GREEN}Thank you for using SSH Key Generator!{Colors.NC}\n")
            sys.exit(0)
        else:
            print(f"{Colors.RED}Invalid choice. Please try again.{Colors.NC}")
        
        input("Press Enter to continue...")

if __name__ == '__main__':
    main()
