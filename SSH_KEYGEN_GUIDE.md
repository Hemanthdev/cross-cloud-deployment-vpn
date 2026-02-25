# SSH Key Generator for Multi-Cloud Infrastructure

Automated SSH key generation scripts for AWS, Azure, Google Cloud Platform (GCP), and Oracle Cloud Infrastructure (OCI) with ASCII graphs and progress visualization.

## Overview

Three scripts in different languages for maximum compatibility:

- **`ssh-keygen.sh`** - Bash/Shell script (Linux, macOS, WSL)
- **`ssh-keygen.py`** - Python 3 script (Windows, macOS, Linux)
- **`ssh-keygen.bat`** - Windows Batch script (Windows Command Prompt)

All scripts generate ED25519 or RSA-4096 SSH keys for each cloud provider with visual progress indicators and statistics.

## Features

✅ Generate SSH keys for all 4 cloud providers (AWS, Azure, GCP, OCI)  
✅ ASCII graphs and progress visualization  
✅ Key fingerprint display (SHA256)  
✅ SSH agent integration  
✅ Key statistics by cloud provider  
✅ Change key type (ED25519 vs RSA-4096)  
✅ Interactive menu system  
✅ Cross-platform support  

## Installation & Prerequisites

### Linux/macOS/WSL

```bash
# Make bash script executable
chmod +x ssh-keygen.sh

# Ensure OpenSSH is installed
# macOS:
brew install openssh

# Ubuntu/Debian:
sudo apt-get install openssh-client

# Run the script
./ssh-keygen.sh
```

### Windows (Option 1: Batch Script)

```cmd
# Run directly from Command Prompt
ssh-keygen.bat

# Or from PowerShell
.\ssh-keygen.bat
```

### Windows (Option 2: Python 3)

```powershell
# Install Python 3 (if not already installed)
# From https://www.python.org/downloads/

# Ensure OpenSSH is installed
# Settings > Apps > Apps & features > Optional features > Add OpenSSH Client

# Run the Python script
python ssh-keygen.py

# Or on some systems:
python3 ssh-keygen.py
```

## Usage

### Bash Script (Linux/macOS/WSL)

```bash
./ssh-keygen.sh
```

Menu options:
- `1` - Generate all keys
- `2` - Generate AWS key
- `3` - Generate Azure key
- `4` - Generate GCP key
- `5` - Generate OCI key
- `6` - View key locations
- `7` - Show statistics
- `8` - Change key type
- `9` - Add keys to SSH agent
- `10` - Exit

### Python Script (All Platforms)

```bash
python3 ssh-keygen.py
```

Same menu options as bash script.

### Windows Batch Script

```cmd
ssh-keygen.bat
```

Menu options:
- `1` - Generate all keys
- `2` - Generate AWS key
- `3` - Generate Azure key
- `4` - Generate GCP key
- `5` - Generate OCI key
- `6` - View key locations
- `7` - Show statistics
- `8` - Change key type
- `9` - Exit

## Key Generation Output

Generated keys are stored in: `~/.ssh/`

### File Structure

```
~/.ssh/
├── aws_id_ed25519          # AWS private key
├── aws_id_ed25519.pub      # AWS public key
├── azure_id_ed25519        # Azure private key
├── azure_id_ed25519.pub    # Azure public key
├── gcp_id_ed25519          # GCP private key
├── gcp_id_ed25519.pub      # GCP public key
├── oci_id_ed25519          # OCI private key
└── oci_id_ed25519.pub      # OCI public key
```

### File Permissions

- Private keys: `600` (rw-------)
- Public keys: `644` (rw-r--r--)

## Key Types

### ED25519 (Recommended)

```
Algorithm:  EdDSA
Key Size:   256 bits
Security:   High
Speed:      Very Fast
Compatibility: Modern systems (2020+)
File Size:  ~400 bytes
```

Recommended for:
- New deployments
- Security-first infrastructure
- Modern cloud providers

#### ED25519 Public Key Example

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKj5... multi-cloud-aws@2026-02-25
```

### RSA-4096

```
Algorithm:  RSA
Key Size:   4096 bits
Security:   High
Speed:      Moderate
Compatibility: Universal (works everywhere)
File Size:  ~3.3 KB
```

Recommended for:
- Legacy systems
- Maximum compatibility
- Older cloud environments

#### RSA-4096 Public Key Example

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDh2NkR... multi-cloud-aws@2026-02-25
```

## Adding Keys to SSH Agent

### Automatic (via Script)

Run option `9` (Linux/macOS) or use Python script to add all keys to SSH agent:

```bash
# Script handles this automatically
```

### Manual (Command Line)

```bash
# Start SSH agent
eval $(ssh-agent -s)

# Add individual keys
ssh-add ~/.ssh/aws_id_ed25519
ssh-add ~/.ssh/azure_id_ed25519
ssh-add ~/.ssh/gcp_id_ed25519
ssh-add ~/.ssh/oci_id_ed25519

# Verify keys are loaded
ssh-add -l
```

## Using Keys with Cloud Providers

### AWS (EC2)

1. Generate key: `./ssh-keygen.sh` → Option 2
2. Go to AWS Console → EC2 → Key Pairs → Import
3. Upload `~/.ssh/aws_id_ed25519.pub`
4. Use key for EC2 instances:
```bash
ssh -i ~/.ssh/aws_id_ed25519 ec2-user@instance-ip
```

### Azure

1. Generate key: `./ssh-keygen.sh` → Option 3
2. Create VM in Azure Portal
3. Paste contents of `~/.ssh/azure_id_ed25519.pub` as SSH public key
4. Connect to VM:
```bash
ssh -i ~/.ssh/azure_id_ed25519 azureuser@vm-ip
```

### GCP (Compute Engine)

1. Generate key: `./ssh-keygen.sh` → Option 4
2. Go to Compute Engine → Metadata → SSH Keys → Add Entry
3. Add username and public key from `~/.ssh/gcp_id_ed25519.pub`
4. SSH to instance:
```bash
ssh -i ~/.ssh/gcp_id_ed25519 username@instance-ip
```

### OCI (Compute)

1. Generate key: `./ssh-keygen.sh` → Option 5
2. Create Instance → Paste public key from `~/.ssh/oci_id_ed25519.pub`
3. Connect to instance:
```bash
ssh -i ~/.ssh/oci_id_ed25519 opc@instance-ip
```

## Security Best Practices

### 1. Key Protection

```bash
# Never share private keys
# Keep private key permissions restricted
chmod 600 ~/.ssh/*_id_*

# Use SSH agent to avoid typing passphrases
eval $(ssh-agent -s)
ssh-add ~/.ssh/aws_id_ed25519
```

### 2. Key Rotation

Rotate keys every 90 days:

```bash
# Generate new key
./ssh-keygen.sh  # or python ssh-keygen.py

# Update cloud provider
# Test new key before removing old one
# Remove old key

# Remove old key from SSH agent
ssh-add -d ~/.ssh/old_key
```

### 3. Access Control

- Store keys in encrypted storage (macOS Keychain, Windows Credential Manager)
- Use different keys per environment (dev/staging/prod)
- Audit key usage via cloud provider logs

### 4. Compliance

```bash
# Generate compliant RSA-4096 keys if required
./ssh-keygen.sh  # Option 8 → Choose RSA-4096
```

## Troubleshooting

### Issue: ssh-keygen command not found

**Solution:** Install OpenSSH

```bash
# macOS
brew install openssh

# Ubuntu/Debian
sudo apt-get install openssh-client

# Windows
Settings → Apps → Optional features → Add OpenSSH Client
```

### Issue: Permission denied on ~/.ssh

**Solution:** Fix directory permissions

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*_id_*
chmod 644 ~/.ssh/*.pub
```

### Issue: SSH connection fails with wrong key

**Solution:** Verify correct key usage

```bash
# Check which key is needed
ssh -v username@host  # Shows key attempts

# Use specific key
ssh -i ~/.ssh/aws_id_ed25519 ec2-user@instance-ip
```

### Issue: Key not added to SSH agent

**Solution:** Manually add key

```bash
# Start agent
eval $(ssh-agent -s)

# Add key with passphrase prompt if needed
ssh-add ~/.ssh/aws_id_ed25519

# Verify
ssh-add -l
```

## Advanced Usage

### Using Config File

Create `~/.ssh/config`:

```
Host aws-instance
    HostName 10.0.1.100
    User ec2-user
    IdentityFile ~/.ssh/aws_id_ed25519

Host azure-vm
    HostName 10.10.1.100
    User azureuser
    IdentityFile ~/.ssh/azure_id_ed25519

Host gcp-instance
    HostName 10.20.1.100
    User ubuntu
    IdentityFile ~/.ssh/gcp_id_ed25519

Host oci-instance
    HostName 10.30.1.100
    User opc
    IdentityFile ~/.ssh/oci_id_ed25519
```

Then connect simply:
```bash
ssh aws-instance
ssh azure-vm
ssh gcp-instance
ssh oci-instance
```

### Generating with Custom Comment

Modify scripts to add custom comments:

```bash
# Before generating, edit script and change comment:
comment = "my-custom-identifier-${cloud}@$(date +%Y-%m-%d)"
```

### Batch Key Distribution

Create script to transfer public keys to servers:

```bash
#!/bin/bash
SERVERS=(aws-instance azure-vm gcp-instance oci-instance)

for server in "${SERVERS[@]}"; do
    ssh-copy-id -i ~/.ssh/${server%%-*}_id_ed25519 $server
done
```

## Statistics Output Example

```
╔───────────────────────────────────────────────────────────╗
│  Key Statistics                                           │
┌───────────────────────────────────────────────────────────┐
│  Total Keys Generated: 4                                 │
│  ED25519 Keys: 4                                         │
│  RSA Keys: 0                                             │
└───────────────────────────────────────────────────────────┘

Keys by Cloud Provider:

AWS    │ ██████████ 1
AZURE  │ ██████████ 1
GCP    │ ██████████ 1
OCI    │ ██████████ 1
```

## License

MIT License - Free for personal and commercial use

## Support

For issues or questions:
1. Check cloud provider documentation
2. Verify OpenSSH installation
3. Review file permissions (`chmod 700 ~/.ssh`)
4. Check SSH config file syntax

---

**Last Updated:** 2026-02-25  
**Version:** 1.0  
**Compatibility:** Windows 10+, macOS 10.12+, Linux (all distributions), WSL 2
