#!/bin/bash
# =============================================================================
# install.sh v0.1.0
# =============================================================================
# Purpose:
#   Sets up everything needed to run the VeraCrypt NAS Backup tool on a fresh
#   Ubuntu/Debian x86 machine.
#
#   What this script does:
#     1. Detects system architecture and OS version
#     2. Installs required system packages (rsync, hashdeep, cifs-utils, etc.)
#     3. Installs VeraCrypt if not already present
#     4. Creates a Python virtual environment and installs Flask + PyYAML
#     5. Creates the logs/ directory
#     6. Prints next steps
#
# Usage:
#   ./install.sh
#
# Requirements:
#   - Ubuntu or Debian-based Linux
#   - sudo access
#   - Internet access (for apt and VeraCrypt download)
#
# After running this script:
#   1. Copy config.sample.yaml to config.yaml and fill in your NAS details
#   2. Mount your VeraCrypt volume
#   3. Start the UI:
#        source ~/.veracrypt-backup-env/bin/activate
#        python3 ui/app.py
# =============================================================================

set -euo pipefail

echo "=============================================="
echo " VeraCrypt NAS Backup — Installer v0.1.0"
echo "=============================================="

# -----------------------------------------------------------------------------
# Detect and display system information. Useful for debugging install issues.
# -----------------------------------------------------------------------------
ARCH=$(uname -m)
KERNEL=$(uname -r)
DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
RELEASE=$(lsb_release -sr 2>/dev/null || echo "Unknown")

echo ""
echo "System info:"
echo "  OS:           $DISTRO $RELEASE"
echo "  Architecture: $ARCH"
echo "  Kernel:       $KERNEL"
echo ""

# -----------------------------------------------------------------------------
# Install required system packages via apt.
#
# Packages:
#   python3          — Required to run the Flask UI and read_config.py
#   python3-pip      — Python package manager (used to set up venv)
#   python3-venv     — For creating the isolated Python virtual environment
#   rsync            — The core file-sync tool used for backups
#   hashdeep         — File integrity hashing (generates and checks manifests)
#   cifs-utils       — Provides mount.cifs for mounting SMB/CIFS NAS shares
#   unzip            — May be needed for VeraCrypt package extraction
#   curl             — Used by fetch-latest-veracrypt.sh to download VeraCrypt
# -----------------------------------------------------------------------------
echo "Installing system packages..."
sudo apt update -qq
sudo apt install -y python3 python3-pip python3-venv rsync hashdeep cifs-utils unzip curl
echo "System packages installed."
echo ""

# -----------------------------------------------------------------------------
# Install VeraCrypt if it's not already present.
# fetch-latest-veracrypt.sh auto-detects your architecture and downloads the
# correct .deb from the official VeraCrypt download page.
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v veracrypt >/dev/null 2>&1; then
    echo "VeraCrypt is already installed. Skipping download."
    veracrypt --version
else
    echo "VeraCrypt not found. Downloading and installing..."
    bash "$SCRIPT_DIR/scripts/fetch-latest-veracrypt.sh"
fi
echo ""

# -----------------------------------------------------------------------------
# Create an isolated Python virtual environment for the Flask UI.
# Using a venv keeps Flask and PyYAML separate from system Python packages,
# which avoids version conflicts and keeps the system clean.
# -----------------------------------------------------------------------------
echo "Setting up Python virtual environment at ~/.veracrypt-backup-env..."
python3 -m venv ~/.veracrypt-backup-env
source ~/.veracrypt-backup-env/bin/activate
pip install --quiet flask pyyaml
echo "Python venv ready."
echo ""

# -----------------------------------------------------------------------------
# Create the logs directory if it doesn't already exist.
# backup.sh and verify.sh both write to logs/backup.log.
# -----------------------------------------------------------------------------
echo "Creating logs directory..."
mkdir -p "$SCRIPT_DIR/logs"
echo "logs/ directory ready."
echo ""

# -----------------------------------------------------------------------------
# Done — print next steps for the user.
# -----------------------------------------------------------------------------
echo "=============================================="
echo " Installation complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Copy and edit the config file:"
echo "       cp config.sample.yaml config.yaml"
echo "       nano config.yaml"
echo ""
echo "  2. Mount your VeraCrypt volume:"
echo "       sudo veracrypt /dev/sdX /mnt/veracrypt-volume"
echo "     (replace /dev/sdX with your actual device — check with: lsblk)"
echo ""
echo "  3. Start the web UI:"
echo "       source ~/.veracrypt-backup-env/bin/activate"
echo "       python3 ui/app.py"
echo ""
echo "  4. Open in your browser:"
echo "       http://localhost:5000"
echo ""
echo "See README.md for full documentation."
echo ""
