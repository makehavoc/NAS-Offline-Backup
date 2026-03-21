# install.sh v0.1.3 🐀
#!/bin/bash
# install.sh v0.1.2 🐀
set -e

echo "🐀 Installing VeraCrypt NAS Backup (v0.1.2-dev)..."

ARCH=$(uname -m)
KERNEL=$(uname -r)
DISTRO=$(lsb_release -si || echo "Unknown")
RELEASE=$(lsb_release -sr || echo "Unknown")

echo "🔍 Detected system: $DISTRO $RELEASE ($ARCH, kernel $KERNEL)"

echo "📦 Updating and installing system packages..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv rsync hashdeep cifs-utils unzip curl

# Check if veracrypt is already installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v veracrypt >/dev/null 2>&1; then
    echo "✅ VeraCrypt is already installed. Skipping download."
else
    bash "$SCRIPT_DIR/scripts/fetch-latest-veracrypt.sh"
fi

echo "🔧 Setting up Python venv..."
python3 -m venv ~/.veracrypt-backup-env
source ~/.veracrypt-backup-env/bin/activate
pip install flask pyyaml

echo "📁 Creating log directory..."
mkdir -p logs

echo "✅ Done!"
echo "📝 Please edit config.yaml before starting."
echo "🐁 Run Flask app: source ~/.veracrypt-backup-env/bin/activate && python3 ui/app.py"
