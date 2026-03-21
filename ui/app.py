# app.py v0.1.3 🐀
# app.py v0.1.2-dev 🐀
# app.py v0.1.1-dev 🐀
from flask import Flask, render_template, request, redirect, url_for
import subprocess, yaml, os

app = Flask(__name__)
session_password = None
CONFIG_PATH = "config.yaml"
LOG_FILE = "logs/backup.log"

def load_config():
    with open(CONFIG_PATH, 'r') as f:
        return yaml.safe_load(f)

@app.route("/", methods=["GET", "POST"])
def index():
    global session_password
    config = load_config()
    nas_mounted = os.path.ismount(config['nas']['mount_point'])
    vc_mounted = os.path.ismount(config['backup']['destination_dir'])

    if request.method == "POST":
        session_password = request.form.get("password")
        return redirect(url_for("index"))

    return render_template("index.html", nas=nas_mounted, vc=vc_mounted, password_required=(session_password is None))

@app.route("/backup", methods=["POST"])
def backup():
    if session_password is None:
        return redirect(url_for("index"))
    subprocess.run(["bash", "scripts/backup.sh", session_password])
    return redirect(url_for("index"))

@app.route("/verify", methods=["POST"])
def verify():
    subprocess.run(["bash", "scripts/verify.sh"])
    return redirect(url_for("index"))

@app.route("/logs")
def logs():
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            log_content = f.read()
    else:
        log_content = "No logs yet."
    return render_template("logs.html", logs=log_content)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
