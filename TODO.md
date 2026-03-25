# TODO — VeraCrypt NAS Backup

This file tracks known issues, limitations, and planned improvements.
Items are roughly prioritised: top of each section = do first.

---

## Versioning reminder

| Change type | Version bump |
|---|---|
| Bug fix | Patch: `0.1.0 → 0.1.1` |
| New feature | Minor: `0.1.0 → 0.2.0` |
| Confirmed, fully tested, production-ready | Major: `0.x.x → 1.0.0` |

---

## Known issues / bugs

- [ ] Systemd unit file (`systemd/veracrypt-backup-ui.service`) has not been tested with the current v0.1.0 codebase. Paths and venv activation need verification.
- [ ] `backup.sh` uses `sudo mount` and `sudo umount` — requires passwordless sudo for these commands. This is documented in README.md but not enforced or checked at install time.
- [ ] No automated tests exist. All testing is manual at this stage.
- [ ] The Flask development server is used (`app.run()`). Not suitable for exposure beyond the local network. Do not expose port 5000 to the internet.

---

## Path to v1.0.0 (production-ready)

These are the things that need to be done — and confirmed working — before this project earns v1.0.0:

- [ ] End-to-end test on real hardware: NAS mount → rsync → manifest → verify → unmount
- [ ] Test on a fresh Ubuntu machine using only the install script
- [ ] Confirm systemd service starts and runs the UI correctly on boot
- [ ] Confirm backup and verify work when triggered from the UI (not just the command line)
- [ ] Confirm `logs/backup.log` is written correctly and visible in the UI log viewer
- [ ] Confirm the backup/verify buttons are correctly disabled when VeraCrypt is not mounted
- [ ] Confirm graceful handling if the NAS password is wrong (error visible in log, NAS not left mounted)
- [ ] Review sudo requirements and document exactly what's needed

---

## Planned improvements (post v1.0.0)

These are future features — do NOT start on these until v1.0.0 is done and confirmed.

- [ ] **Notifications** — Send a Pushover or webhook alert on backup success or failure
- [ ] **Multi-share support** — Allow multiple NAS shares in config.yaml
- [ ] **Restore preview** — Read-only view of what's in the backup, without requiring a full restore
- [ ] **Session timeout** — Clear the in-memory NAS password after a configurable idle period
- [ ] **Backup history** — Track timestamps and sizes of past backup runs
- [ ] **Dark theme** — Optional dark mode for the UI

---

## Will not do

These are things that are explicitly out of scope for this project:

- Docker / containers — not needed, adds complexity with no benefit here
- Ansible / configuration management — overkill for a single-machine tool
- Cloud backup targets (S3, Backblaze, etc.) — out of scope; this is for local encrypted backups
- GUI desktop app — the web UI is sufficient
- Windows support — Linux only by design
