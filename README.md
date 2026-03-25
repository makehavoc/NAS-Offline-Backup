# VeraCrypt NAS Backup

**Version:** 0.1.0 — [See CHANGELOG](CHANGELOG.md)

A simple, reliable tool for backing up a NAS share to a VeraCrypt-encrypted external drive on Linux. Built for homelabs. No unnecessary complexity.

---

## What it does

1. Mounts your NAS share (CIFS/SMB) using credentials you provide at runtime
2. Copies files to a VeraCrypt-encrypted external drive using `rsync`
3. Generates a file integrity manifest with `hashdeep`
4. Unmounts the NAS share
5. On demand: verifies the backup against the saved manifest

A minimal web UI (Flask, runs on port 5000) gives you buttons to trigger backup and verify, and a log viewer.

---

## How it works — the workflow

```
1. Plug in encrypted external drive
2. Mount the VeraCrypt volume (one command — you do this manually)
3. Open the UI in your browser: http://localhost:5000
4. Enter your NAS password (held in memory only — never written to disk)
5. Click "Run Backup"
   └─ Script mounts NAS, rsyncs files, generates manifest, unmounts NAS
6. Click "Run Verify" (optional — confirms everything copied correctly)
7. Close the UI, unmount VeraCrypt volume, unplug the drive
```

---

## Prerequisites

Before installing, make sure you have:

- **Ubuntu or Debian-based Linux** (x86_64)
- **sudo access**
- **Internet access** (for the initial install)
- **A NAS share** accessible over CIFS/SMB on your local network
- **A VeraCrypt-encrypted external drive** (create the volume in VeraCrypt before first use)

### Install VeraCrypt

The install script will attempt to download and install VeraCrypt automatically. If that fails, install it manually:

**Option 1 — Use the included script:**
```bash
bash scripts/fetch-latest-veracrypt.sh
```

**Option 2 — Manual install:**
1. Go to: https://www.veracrypt.fr/en/Downloads.html
2. Download the `.deb` for your platform:
   - x86_64 Ubuntu/Debian: `veracrypt-X.X.X-Debian-11-amd64.deb`
3. Install it:
   ```bash
   sudo dpkg -i veracrypt-*.deb
   sudo apt-get install -f
   ```
4. Confirm it works:
   ```bash
   veracrypt --version
   ```

> **You must have VeraCrypt installed and working before running any backups.**

---

## Installation

```bash
# 1. Clone the repo
git clone https://github.com/makehavoc/NAS-Offline-Backup.git
cd NAS-Offline-Backup

# 2. Run the installer
./install.sh
```

The installer will:
- Install system packages: `rsync`, `hashdeep`, `cifs-utils`, `python3`, `curl`
- Install VeraCrypt (if not already present)
- Create a Python virtual environment at `~/.veracrypt-backup-env`
- Install `flask` and `pyyaml` into the venv
- Create the `logs/` directory

---

## Configuration

```bash
cp config.sample.yaml config.yaml
nano config.yaml
```

`config.yaml` is already in `.gitignore` — it will never be committed. See `config.sample.yaml` for full documentation of every field.

**Key settings to fill in:**

| Setting | What it is |
|---|---|
| `nas.share` | Network path to your NAS share, e.g. `//192.168.1.42/backups` |
| `nas.mount_point` | Local directory to mount the NAS at, e.g. `/mnt/nas` |
| `nas.username` | Your NAS username |
| `backup.source_dir` | Directory to back up (usually the NAS mount point, with trailing `/`) |
| `backup.destination_dir` | Where your VeraCrypt volume is mounted, e.g. `/mnt/veracrypt-volume/` |

> **Do not put your NAS password in `config.yaml`.** Enter it in the web UI at runtime.

---

## Running the UI

```bash
# Activate the Python virtual environment
source ~/.veracrypt-backup-env/bin/activate

# Start the web server
python3 ui/app.py
```

Open your browser at: **http://localhost:5000**

The UI is also accessible from other machines on your local network at:
**http://YOUR_IP:5000**

---

## Mounting your VeraCrypt volume

Before running a backup, mount your VeraCrypt volume manually:

```bash
# Find your external drive's device name
lsblk

# Mount the VeraCrypt volume (replace /dev/sdX with your device)
sudo veracrypt /dev/sdX /mnt/veracrypt-volume
```

You'll be prompted for the VeraCrypt password. The UI will detect that the volume is mounted and enable the backup buttons.

When you're done, close the volume:
```bash
sudo veracrypt -d /mnt/veracrypt-volume
```

---

## Sudo requirements

The backup script uses `sudo` to mount and unmount the NAS share. To avoid being prompted for a password during automated backups, add passwordless sudo for these specific commands:

```bash
sudo visudo
```

Add this line (replace `yourusername`):
```
yourusername ALL=(ALL) NOPASSWD: /bin/mount, /bin/umount, /bin/mkdir
```

---

## Testing your setup

Follow these steps after installation to confirm everything works before trusting it with real data.

### Step 1 — Check dependencies

```bash
veracrypt --version   # Should print a version number
rsync --version       # Should print a version number
hashdeep -V           # Should print a version number
python3 --version     # Should be 3.8 or higher
```

### Step 2 — Check config reads correctly

```bash
source ~/.veracrypt-backup-env/bin/activate
python3 scripts/read_config.py nas.share
python3 scripts/read_config.py backup.source_dir
python3 scripts/read_config.py backup.destination_dir
```

Each command should print the corresponding value from your `config.yaml`.

### Step 3 — Mount a test VeraCrypt volume

```bash
lsblk                                                  # find your device
sudo veracrypt /dev/sdX /mnt/veracrypt-volume          # mount it
mountpoint /mnt/veracrypt-volume                       # should say "is a mountpoint"
```

### Step 4 — Start the UI and check status

```bash
source ~/.veracrypt-backup-env/bin/activate
python3 ui/app.py
```

Open http://localhost:5000. You should see:
- No "VeraCrypt not installed" warning
- VeraCrypt mount: ✅ Mounted
- A password prompt

### Step 5 — Run a backup

1. Enter your NAS password in the UI
2. Click **Run Backup**
3. Wait for it to complete (may take a while depending on data size)
4. Click **View Backup Log** — you should see timestamped rsync output

### Step 6 — Run verify

1. Click **Run Verify**
2. Check the log — should end with `Verify complete: PASSED`

---

## File structure

```
NAS-Offline-Backup/
├── scripts/
│   ├── backup.sh               # Mounts NAS, rsyncs, generates manifest, unmounts
│   ├── verify.sh               # Verifies backup against manifest
│   ├── read_config.py          # Reads config.yaml values for use in bash scripts
│   └── fetch-latest-veracrypt.sh  # Downloads and installs latest VeraCrypt
├── ui/
│   ├── app.py                  # Flask web application
│   └── templates/
│       ├── index.html          # Main dashboard
│       └── logs.html           # Log viewer
├── systemd/
│   └── veracrypt-backup-ui.service  # Optional: run UI as a systemd service
├── logs/                       # Created on first run — contains backup.log
├── config.sample.yaml          # Template config — copy to config.yaml
├── install.sh                  # Sets up dependencies and Python venv
├── CHANGELOG.md                # Version history
├── TODO.md                     # Known issues and future plans
└── VERSION                     # Current version number
```

---

## Running as a systemd service (optional)

If you want the UI to start automatically on boot:

```bash
# Copy and edit the service file
sudo cp systemd/veracrypt-backup-ui.service /etc/systemd/system/
sudo nano /etc/systemd/system/veracrypt-backup-ui.service
# Update WorkingDirectory and ExecStart paths to match your setup

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable veracrypt-backup-ui
sudo systemctl start veracrypt-backup-ui

# Check it's running
sudo systemctl status veracrypt-backup-ui
```

---

## Troubleshooting

**"VeraCrypt is not installed" warning in UI**
Run `bash scripts/fetch-latest-veracrypt.sh` or install manually (see Prerequisites above).

**"VeraCrypt volume not mounted" in UI**
Mount the volume with `sudo veracrypt /dev/sdX /mnt/veracrypt-volume` before starting a backup.

**Backup fails immediately**
Check `logs/backup.log`. Common causes:
- NAS password was wrong (CIFS mount failed)
- NAS share path is incorrect in config.yaml
- VeraCrypt volume not mounted

**Verify fails**
Files have changed since the manifest was generated. Either re-run the backup (to update the manifest) or investigate what changed in the backup destination.

**"No log file yet"**
You haven't run a backup yet. Run one first.

**Flask UI won't start**
Make sure you've activated the venv: `source ~/.veracrypt-backup-env/bin/activate`
Make sure `config.yaml` exists: `cp config.sample.yaml config.yaml`

---

## See also

- [CHANGELOG.md](CHANGELOG.md) — Version history
- [TODO.md](TODO.md) — Known issues and planned improvements
- [!Dev-and-Debugging/README.md](!Dev-and-Debugging/README.md) — Developer notes
