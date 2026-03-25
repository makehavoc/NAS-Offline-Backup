# Developer Notes — VeraCrypt NAS Backup v0.1.0

This file is for developers and maintainers. If you're extending, debugging, or modifying this project — start here.

---

## Tech stack

| Component | Technology |
|---|---|
| Web UI | Python / Flask |
| Config | YAML (`config.yaml`) |
| Config reader | `scripts/read_config.py` (Python + PyYAML) |
| File sync | `rsync` |
| Integrity verification | `hashdeep` |
| NAS mounting | `mount.cifs` (from `cifs-utils`) |
| Encryption | VeraCrypt (user manages this manually) |
| Python environment | `venv` at `~/.veracrypt-backup-env` |
| Service management | systemd (optional) |

---

## File structure

```
scripts/
  backup.sh               — Mounts NAS, runs rsync, generates manifest, unmounts
  verify.sh               — Verifies backup state against saved manifest
  read_config.py          — Reads a dotted key from config.yaml, prints the value
  fetch-latest-veracrypt.sh — Downloads and installs latest VeraCrypt .deb

ui/
  app.py                  — Flask app: routes, password handling, subprocess calls
  templates/
    index.html            — Dashboard: mount status, password form, action buttons
    logs.html             — Log viewer

systemd/
  veracrypt-backup-ui.service — Optional systemd unit for running UI on boot

config.sample.yaml        — Documented template — copy to config.yaml
install.sh                — Dependency installer
logs/                     — Created at runtime; contains backup.log
VERSION                   — Single-line version string
CHANGELOG.md              — Version history and change notes
TODO.md                   — Known issues and planned improvements
```

---

## Developer setup

```bash
git clone https://github.com/makehavoc/NAS-Offline-Backup.git
cd NAS-Offline-Backup
./install.sh
cp config.sample.yaml config.yaml
nano config.yaml
```

Start the Flask UI:
```bash
source ~/.veracrypt-backup-env/bin/activate
python3 ui/app.py
```

---

## How config reading works

Bash cannot parse YAML natively. `scripts/read_config.py` bridges this gap.

```bash
# In any bash script, read a config value like this:
VALUE=$(python3 scripts/read_config.py some.dotted.key)
```

The script walks the dotted key path into the parsed YAML and prints the value to stdout. If the key doesn't exist or `config.yaml` is missing, it prints a clear error to stderr and exits non-zero.

---

## How the password is handled

1. User enters NAS password in the web UI form
2. `app.py` stores it in the module-level `session_password` variable (memory only)
3. When backup runs, `app.py` passes it as `NAS_PASSWORD` env var to `backup.sh`
4. `backup.sh` writes it to a `chmod 600` temp file for `mount.cifs`, then deletes the temp file on exit
5. The password is **never** written to `config.yaml`, `logs/`, a cookie, or a database

---

## How backup and verify work together

**Backup** (`backup.sh`):
1. Reads config
2. Validates VeraCrypt volume is mounted
3. Mounts NAS share
4. Runs `rsync -avh --delete source/ dest/`
5. Runs `hashdeep -r -c md5,sha256 -l .` inside the destination — saves manifest to `backup_manifest.txt`
6. Unmounts NAS (via `trap` so this always runs)

**Verify** (`verify.sh`):
1. Reads config
2. Validates VeraCrypt volume is mounted
3. Checks manifest file exists (error if not — run backup first)
4. Runs `hashdeep -r -a -v -f manifest.txt` — audits current state against manifest
5. Reports pass/fail

The manifest is stored **inside** the VeraCrypt volume so it travels with the backup.

---

## Debugging tips

**Flask UI won't start**
- Activate the venv: `source ~/.veracrypt-backup-env/bin/activate`
- Ensure `config.yaml` exists: `cp config.sample.yaml config.yaml`
- Check for Python errors in the terminal where you ran `python3 ui/app.py`

**Backup script fails**
- Check `logs/backup.log` for the exact error message
- Test config reading manually: `python3 scripts/read_config.py nas.share`
- Test NAS mount manually: `sudo mount -t cifs //IP/share /mnt/nas -o username=X,password=Y`

**Verify always fails**
- Check whether the manifest was generated: `ls -la /mnt/veracrypt-volume/backup_manifest.txt`
- If it doesn't exist, run a backup first
- Check `logs/backup.log` for hashdeep output

**VeraCrypt not found**
- Run `bash scripts/fetch-latest-veracrypt.sh`
- Or install manually — see main `README.md`

---

## Versioning

Follows semantic versioning:

| Change type | Version bump | Example |
|---|---|---|
| Bug fix | Patch | `0.1.0 → 0.1.1` |
| New feature | Minor | `0.1.0 → 0.2.0` |
| Production-ready, fully tested | Major | `0.x.x → 1.0.0` |

Update the version in:
- `VERSION`
- Script header comments (e.g. `# backup.sh v0.1.1`)
- `CHANGELOG.md`
- `README.md` header

---

## Known limitations (v0.1.0)

See `TODO.md` for the full list. Key items:

- No automated tests — tested manually only at this stage
- No notifications (Pushover, email, webhook) on success/failure
- Single NAS share only — no multi-share support
- No restore functionality — backup only
- Systemd unit file exists but hasn't been tested with the current version

---

## Contribution guidelines

- Keep it simple. If you need to explain it in more than two sentences, it's probably too complex.
- No Docker. No Ansible. No over-engineering.
- Every script gets a header block. Every function gets a comment.
- Bump the version and update CHANGELOG.md with every change.
- Don't call it v1.0.0 until it's confirmed working in production.
