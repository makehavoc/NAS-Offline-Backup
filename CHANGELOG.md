# Changelog

All notable changes to this project will be documented here.

## Versioning policy

This project follows [Semantic Versioning](https://semver.org/):

- **Patch** (`0.1.0 → 0.1.1`): Bug fixes, documentation corrections, no behaviour change
- **Minor** (`0.1.0 → 0.2.0`): New features, backwards-compatible changes
- **Major** (`0.x.x → 1.0.0`): Reserved for the first confirmed, fully tested, production-ready release

---

## [v0.1.0] — 2026-03-24 — First complete implementation

### Added
- `scripts/read_config.py` — Python helper for reading `config.yaml` values in bash scripts. Replaces the broken pattern of sourcing YAML as bash.
- `scripts/backup.sh` — Full rewrite. Now:
  - Reads config via `read_config.py`
  - Accepts NAS password via `NAS_PASSWORD` environment variable (not CLI arg)
  - Creates a temp credentials file for `mount.cifs` so password never appears in `ps` output
  - Validates that the VeraCrypt volume is mounted before starting
  - Mounts the NAS share, runs rsync with `--delete`, generates a hashdeep manifest, unmounts NAS
  - Uses a `trap` to guarantee NAS is unmounted even if rsync fails
  - Logs all output to `logs/backup.log` with timestamps
- `scripts/verify.sh` — Full rewrite. Now:
  - Reads config via `read_config.py`
  - Checks that the VeraCrypt volume is mounted
  - Checks that a manifest exists (gives a clear error if not — run backup first)
  - Runs `hashdeep -r -a -v -f` to audit current backup state against the manifest
  - Reports pass/fail clearly in the log
- `ui/app.py` — Updated:
  - Passes NAS password to `backup.sh` as `NAS_PASSWORD` env var instead of CLI argument
  - Checks for `veracrypt` on PATH at startup; warns if missing
  - Creates `logs/` directory on startup if it doesn't exist
  - Passes `veracrypt_installed` and `vc_mount_path` to templates
  - Uses absolute paths so app works from any working directory
- `ui/templates/index.html` — Rewritten with:
  - VeraCrypt not-installed warning banner
  - VeraCrypt not-mounted warning with mount instructions
  - Backup/Verify buttons disabled when VeraCrypt volume isn't mounted
  - Clean minimal CSS, no external dependencies
  - Full HTML comments throughout
- `ui/templates/logs.html` — Updated with clean styling and HTML comments
- `config.sample.yaml` — Fully commented; every field explained with valid values
- `install.sh` — Rewritten with header block, inline comments, and clear next-steps output
- `scripts/fetch-latest-veracrypt.sh` — Version bump to v0.1.0

### Fixed
- `backup.sh` and `verify.sh` were sourcing `config.yaml` as bash (broken — YAML is not bash)
- `backup.sh` was ignoring the NAS password argument and had no mount/unmount logic
- `verify.sh` was generating a manifest and immediately verifying against it (always passed)
- Neither script wrote to the log file the UI reads
- `VERSION` file said `0.0.1-test`, inconsistent with everything else

### Changed
- Version bumped from `0.0.1-test` to `0.1.0` across all files

---

## [pre-release] — Initial skeleton

- Flask UI with backup + verify buttons
- YAML-based config structure
- rsync and hashdeep script stubs
- VeraCrypt auto-download script
- Systemd unit file
- Install script skeleton
