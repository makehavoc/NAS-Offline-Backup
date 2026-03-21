# VeraCrypt NAS Backup (v0.1.0) 🐀

Secure, simple, rat-themed backup system for syncing a NAS share to a VeraCrypt-encrypted external drive on Linux.

## 🧰 Installation

Run the following to install dependencies and set up the project:

```bash
./install.sh
```

Make sure to edit your config file after install:

```bash
cp config.sample.yaml config.yaml
nano config.yaml
```

---

## 🧰 Manual VeraCrypt Installation (If Needed)

If the install script fails to install VeraCrypt automatically:

1. Visit: https://www.veracrypt.fr/en/Downloads.html  
2. Choose the correct `.deb` package for your platform:
   - 🐭 Raspberry Pi 64-bit (Ubuntu 24.04): `veracrypt-1.26.7-Debian-11-arm64.deb`
   - 🖥️ x86_64 Ubuntu: `veracrypt-1.26.7-Debian-11-amd64.deb`
3. Install it manually:
   ```bash
   sudo dpkg -i veracrypt-*.deb
   sudo apt-get install -f
   ```
4. Test it:
   ```bash
   veracrypt --version
   ```

🚨 **You must have VeraCrypt working before running backups!**

