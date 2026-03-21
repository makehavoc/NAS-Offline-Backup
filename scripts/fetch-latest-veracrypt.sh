# fetch-latest-veracrypt.sh v0.1.3 🐀
# fetch-latest-veracrypt.sh v0.1.1 🐀
#!/bin/bash
# fetch-latest-veracrypt.sh v0.1.0 🐀
set -e

ARCH=$(uname -m)
VC_TMP="/tmp/veracrypt"
mkdir -p "$VC_TMP"
cd "$VC_TMP"

echo "🔍 Checking latest VeraCrypt version for architecture: $ARCH"

if [[ "$ARCH" == "aarch64" ]]; then
    ARCH_SUFFIX="arm64"
elif [[ "$ARCH" == "armv7l" ]]; then
    ARCH_SUFFIX="armhf"
elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH_SUFFIX="amd64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

# Fetch and parse Launchpad download page for latest matching .deb
VC_PAGE="https://launchpad.net/veracrypt/trunk/+download"
VC_DEB=$(curl -s "$VC_PAGE" | grep -oP "veracrypt-[\d\.]+-Debian-11-${ARCH_SUFFIX}\.deb" | sort -V | tail -n 1)

if [[ -z "$VC_DEB" ]]; then
    echo "❌ Could not find a VeraCrypt .deb for your architecture ($ARCH_SUFFIX)."
    exit 1
fi

echo "📦 Found latest package: $VC_DEB"
VC_URL="https://launchpad.net/veracrypt/trunk/+download/$VC_DEB"
curl -LO "$VC_URL"

echo "🔐 Installing VeraCrypt: $VC_DEB"
sudo dpkg -i "$VC_DEB" || sudo apt -f install -y

# Verify install
if command -v veracrypt >/dev/null 2>&1; then
    echo "✅ VeraCrypt installed successfully."
else
    echo "❌ VeraCrypt install failed."
    exit 1
fi

cd ~
rm -rf "$VC_TMP"
