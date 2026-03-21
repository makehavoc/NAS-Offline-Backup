# 🧪 VeraCrypt NAS Backup – Developer README 🐀

This is your secret ratmap. If you're poking around this project and need to debug, modify, or extend it — this file is for you.

## 🧰 Tech Stack
- **Flask** (UI)
- **Bash scripts** (backup + verify)
- **rsync** (primary backup tool)
- **hashdeep** (verification)
- **YAML** (config)
- **Python venv** (dependency isolation)
- **Systemd optional** (for service management)

---

## 🐭 Developer Checklist

1. Clone repo and run `./install.sh` (or manually install deps).
2. Copy and edit `config.sample.yaml` → `config.yaml`.
3. Mount your VeraCrypt volume manually.
4. Run the Flask UI:
   ```bash
   source ~/.veracrypt-backup-env/bin/activate
   python3 ui/app.py
   ```

---

## 🐁 File Structure

```bash
scripts/         # Bash scripts for backup + verification
ui/              # Flask UI
ui/templates/    # HTML templates
logs/            # Where logs go
systemd/         # Optional systemd unit
```

---

## 🧀 Debugging Tips

- **Flask UI not running?**
  Make sure you're in the venv and `config.yaml` exists.

- **Backup didn't run?**
  Check `logs/backup.log` for 🐀 sass and `rsync` output.

- **Verify failed?**
  `verify.sh` uses `hashdeep -rav -f manifest.txt`. If files changed, it'll squeak.

- **VeraCrypt not found?**
  Check the install section in the main `README.md` or install manually.

---

## 🐾 Versioning

Each script contains a commented-out version at the top like:
```bash
# backup.sh v0.1.0
```
Don't forget to update this if you modify it.

---

## 🍴 Contribution Notes

- Keep it simple. Kitchen Stadium rules apply.
- No Docker. No Ansible. No Jenkins. Just elegance.
- Sass level must remain at **11**.

---

## 🎉 Future Ideas

- Pushover or webhook alerts on success/failure
- Multiple share support in config.yaml
- Restore preview tool (read-only)
- Rat-mode dark theme

---

## 💀 What Not To Do

- ❌ Do not hardcode passwords
- ❌ Do not add cron unless you hate your backups
- ❌ Do not remove the rats

---

Stay squeaky. 🧀🐀

