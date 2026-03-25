"""
app.py v0.1.0
-------------
Flask web UI for the VeraCrypt NAS Backup tool.

This is the entry point for the web interface. It provides a simple browser-based
UI that lets you:
  - Enter your NAS password (held in memory for the session, never written to disk)
  - Run a backup (calls scripts/backup.sh)
  - Verify a backup (calls scripts/verify.sh)
  - View the backup log

Design decisions:
  - The NAS password is stored only in the server-side `session_password` variable.
    It is NOT stored in a cookie, a file, or a database.
  - The password is passed to backup.sh via an environment variable (NAS_PASSWORD),
    not as a command-line argument. This prevents it from appearing in `ps` output.
  - VeraCrypt mounting is intentionally left to the user. The UI checks whether
    the configured VeraCrypt mount point is mounted and warns if it isn't.

Usage:
  source ~/.veracrypt-backup-env/bin/activate
  python3 ui/app.py

Then open http://localhost:5000 in your browser.

Dependencies:
  flask, pyyaml (installed by install.sh into the Python venv)
"""

import os
import subprocess
import shutil
import yaml
from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Paths — resolved relative to this file so the app works from any cwd.
# ---------------------------------------------------------------------------
UI_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(UI_DIR)
CONFIG_PATH = os.path.join(PROJECT_ROOT, "config.yaml")
LOG_FILE = os.path.join(PROJECT_ROOT, "logs", "backup.log")
SCRIPTS_DIR = os.path.join(PROJECT_ROOT, "scripts")

# ---------------------------------------------------------------------------
# Session password — stored in memory only, cleared when the server restarts.
# The user must re-enter the password each time the Flask app is restarted.
# ---------------------------------------------------------------------------
session_password = None


def load_config():
    """
    Load and return the parsed config.yaml as a Python dict.
    Raises FileNotFoundError with a helpful message if config.yaml is missing.
    """
    if not os.path.exists(CONFIG_PATH):
        raise FileNotFoundError(
            f"config.yaml not found at {CONFIG_PATH}. "
            "Copy config.sample.yaml to config.yaml and fill in your settings."
        )
    with open(CONFIG_PATH, "r") as f:
        return yaml.safe_load(f)


def check_veracrypt_installed():
    """
    Return True if the `veracrypt` command is available on PATH, False otherwise.
    Used to show a warning banner in the UI if VeraCrypt isn't installed.
    """
    return shutil.which("veracrypt") is not None


@app.route("/", methods=["GET", "POST"])
def index():
    """
    Main page. Shows mount status and backup/verify buttons.

    GET:  Render the dashboard showing NAS mount status and VeraCrypt mount status.
    POST: Accept the NAS password from the password form and store it in memory.
    """
    global session_password

    config = load_config()

    # Check whether the NAS share and VeraCrypt volume are currently mounted.
    # mountpoint -q returns 0 if mounted, non-zero if not. os.path.ismount does
    # the same check from Python without needing a subprocess call.
    nas_mounted = os.path.ismount(config["nas"]["mount_point"])
    vc_mounted = os.path.ismount(config["backup"]["destination_dir"])

    # Check that VeraCrypt is installed — show a warning banner if not.
    veracrypt_installed = check_veracrypt_installed()

    if request.method == "POST":
        # Accept and store the NAS password from the form submission.
        # This is the only time the password is handled — it goes into memory
        # and is never written anywhere else.
        session_password = request.form.get("password")
        return redirect(url_for("index"))

    return render_template(
        "index.html",
        nas=nas_mounted,
        vc=vc_mounted,
        password_set=(session_password is not None),
        veracrypt_installed=veracrypt_installed,
        vc_mount_path=config["backup"]["destination_dir"],
    )


@app.route("/backup", methods=["POST"])
def backup():
    """
    Trigger a backup run by calling scripts/backup.sh.

    The NAS password is passed as the NAS_PASSWORD environment variable —
    NOT as a command-line argument — to prevent it appearing in `ps` output.

    Redirects back to the main page when done. The user can check the log
    to see whether the backup succeeded.
    """
    if session_password is None:
        # Password hasn't been set yet — redirect to main page to prompt for it.
        return redirect(url_for("index"))

    # Build the environment for the subprocess: inherit the current environment
    # and add NAS_PASSWORD so backup.sh can pick it up.
    env = {**os.environ, "NAS_PASSWORD": session_password}

    subprocess.run(
        ["bash", os.path.join(SCRIPTS_DIR, "backup.sh")],
        env=env,
        cwd=PROJECT_ROOT,
    )

    return redirect(url_for("index"))


@app.route("/verify", methods=["POST"])
def verify():
    """
    Trigger a verify run by calling scripts/verify.sh.

    No password is needed for verify — it only reads the backup destination
    and the manifest file, both of which should already be accessible.

    Redirects back to the main page when done.
    """
    subprocess.run(
        ["bash", os.path.join(SCRIPTS_DIR, "verify.sh")],
        cwd=PROJECT_ROOT,
    )

    return redirect(url_for("index"))


@app.route("/logs")
def logs():
    """
    Display the contents of logs/backup.log in the browser.
    Shows a placeholder message if the log file doesn't exist yet.
    """
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            log_content = f.read()
    else:
        log_content = "No log file yet. Run a backup to generate one."

    return render_template("logs.html", logs=log_content)


if __name__ == "__main__":
    # Ensure the logs directory exists when the app starts.
    os.makedirs(os.path.join(PROJECT_ROOT, "logs"), exist_ok=True)

    # Warn on startup if VeraCrypt isn't installed.
    if not check_veracrypt_installed():
        print("WARNING: veracrypt is not installed or not on PATH.")
        print("See README.md for installation instructions.")

    # Run on all interfaces (0.0.0.0) so it's accessible from other machines
    # on the local network (e.g. opening the Pi's UI from your desktop browser).
    app.run(host="0.0.0.0", port=5000)
