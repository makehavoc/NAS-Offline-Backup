#!/bin/bash
# =============================================================================
# backup.sh v0.1.0
# =============================================================================
# Purpose:
#   Mounts the NAS share, syncs its contents to the VeraCrypt-encrypted backup
#   volume using rsync, generates a file integrity manifest, then unmounts the
#   NAS share cleanly.
#
# Usage:
#   Called by the Flask UI (ui/app.py). Do not run directly unless testing.
#   bash scripts/backup.sh
#
# Required environment variable:
#   NAS_PASSWORD  — The CIFS/SMB password for the NAS share.
#                   Set by app.py before calling this script.
#                   NEVER hardcoded here or in config.yaml.
#
# Dependencies:
#   - python3 + pyyaml (for read_config.py)
#   - rsync
#   - hashdeep
#   - sudo (for mount/umount — user must have passwordless sudo for these)
#   - cifs-utils (provides mount.cifs)
#
# Logs:
#   All output is written to logs/backup.log (appended, with timestamps).
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Resolve the project root directory so this script works regardless of where
# it is called from (e.g. the Flask app calls it from the project root).
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/backup.log"

# -----------------------------------------------------------------------------
# log()
# Writes a timestamped message to both stdout and the log file.
# Usage: log "Your message here"
# -----------------------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# Ensure the logs directory exists before we try to write to it.
# -----------------------------------------------------------------------------
mkdir -p "$PROJECT_ROOT/logs"

log "========================================================"
log "🐀 Starting backup run"
log "========================================================"

# -----------------------------------------------------------------------------
# Read all required config values from config.yaml using the Python helper.
# Each value is read individually so errors are specific and easy to diagnose.
# -----------------------------------------------------------------------------
log "📖 Reading config..."

NAS_SHARE=$(python3 "$SCRIPT_DIR/read_config.py" nas.share)
NAS_MOUNT=$(python3 "$SCRIPT_DIR/read_config.py" nas.mount_point)
NAS_USER=$(python3 "$SCRIPT_DIR/read_config.py" nas.username)
SOURCE_DIR=$(python3 "$SCRIPT_DIR/read_config.py" backup.source_dir)
DEST_DIR=$(python3 "$SCRIPT_DIR/read_config.py" backup.destination_dir)
MANIFEST_FILE=$(python3 "$SCRIPT_DIR/read_config.py" backup.manifest_file)

log "  NAS share:      $NAS_SHARE"
log "  NAS mount:      $NAS_MOUNT"
log "  Source:         $SOURCE_DIR"
log "  Destination:    $DEST_DIR"
log "  Manifest file:  $MANIFEST_FILE"

# -----------------------------------------------------------------------------
# Validate that NAS_PASSWORD was set by the caller (app.py).
# If it's missing, we can't mount the NAS — fail clearly.
# -----------------------------------------------------------------------------
if [[ -z "${NAS_PASSWORD:-}" ]]; then
    log "❌ ERROR: NAS_PASSWORD environment variable is not set."
    log "   Enter your NAS password in the web UI before running a backup."
    exit 1
fi

# -----------------------------------------------------------------------------
# Validate that the VeraCrypt destination volume is already mounted.
# The user is expected to mount this manually before starting a backup.
# We do NOT attempt to mount it here — that would require the VeraCrypt
# password and device path, which adds complexity we're deliberately avoiding.
# -----------------------------------------------------------------------------
if ! mountpoint -q "$DEST_DIR"; then
    log "❌ ERROR: VeraCrypt volume is not mounted at $DEST_DIR"
    log "   Please mount your VeraCrypt volume first:"
    log "   sudo veracrypt /dev/sdX $DEST_DIR"
    exit 1
fi
log "✅ VeraCrypt volume confirmed mounted at $DEST_DIR"

# -----------------------------------------------------------------------------
# Ensure the NAS mount point directory exists.
# mount.cifs requires the mount point to exist before mounting.
# -----------------------------------------------------------------------------
sudo mkdir -p "$NAS_MOUNT"

# -----------------------------------------------------------------------------
# Cleanup trap — runs on script exit (success or failure).
# This ensures the NAS is always unmounted, even if rsync fails midway.
# Without this, a failed backup would leave the NAS share mounted.
# -----------------------------------------------------------------------------
cleanup() {
    log "🔌 Unmounting NAS share at $NAS_MOUNT..."
    sudo umount "$NAS_MOUNT" 2>/dev/null && log "✅ NAS unmounted." || log "⚠️  NAS was not mounted or already unmounted."
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Mount the NAS share using CIFS (SMB).
# uid/gid ensure the mounted files are owned by the current (non-root) user.
# The password is passed via the credentials option in the mount options string
# to avoid it appearing in the process list via command-line arguments.
# -----------------------------------------------------------------------------
log "🔌 Mounting NAS share $NAS_SHARE → $NAS_MOUNT..."

# Write a temporary credentials file so the password never appears in ps output
CREDS_FILE=$(mktemp)
chmod 600 "$CREDS_FILE"
echo "username=$NAS_USER" > "$CREDS_FILE"
echo "password=$NAS_PASSWORD" >> "$CREDS_FILE"

# Clean up the credentials file on exit (in addition to unmounting)
trap 'cleanup; rm -f "$CREDS_FILE"' EXIT

sudo mount -t cifs "$NAS_SHARE" "$NAS_MOUNT" \
    -o "credentials=$CREDS_FILE,uid=$(id -u),gid=$(id -g),iocharset=utf8"

log "✅ NAS mounted successfully."

# -----------------------------------------------------------------------------
# Run rsync to sync source → destination.
#
# Flags explained:
#   -a  archive mode: preserves permissions, timestamps, symlinks, etc.
#   -v  verbose: logs each file transferred
#   -h  human-readable file sizes in output
#   --delete  remove files from destination that no longer exist on source
#             (keeps the backup a true mirror of the NAS)
#
# All rsync output is appended to the log file for a full transfer record.
# -----------------------------------------------------------------------------
log "🔄 Starting rsync: $SOURCE_DIR → $DEST_DIR"
rsync -avh --delete "$SOURCE_DIR" "$DEST_DIR" >> "$LOG_FILE" 2>&1
log "✅ rsync complete."

# -----------------------------------------------------------------------------
# Generate a hashdeep manifest of the backup destination.
# This manifest is used later by verify.sh to confirm nothing has changed.
#
# The manifest file is stored inside the destination (VeraCrypt volume) so it
# travels with the backup and doesn't require the destination path to be the
# same on every machine.
#
# Flags:
#   -r   recursive
#   -c md5,sha256  compute both MD5 and SHA-256 for each file
#   -l   use relative paths in the manifest (portable across machines)
# -----------------------------------------------------------------------------
log "📋 Generating integrity manifest at $DEST_DIR/$MANIFEST_FILE..."
cd "$DEST_DIR"
hashdeep -r -c md5,sha256 -l . > "$MANIFEST_FILE" 2>> "$LOG_FILE"
log "✅ Manifest generated."

log "========================================================"
log "🐀 Backup complete."
log "========================================================"
