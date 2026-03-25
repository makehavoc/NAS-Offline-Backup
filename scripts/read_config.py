#!/usr/bin/env python3
"""
read_config.py v0.1.0
---------------------
A small helper that reads a single value from config.yaml and prints it to stdout.
Used by the bash scripts (backup.sh, verify.sh) so they can read YAML config
without needing any external YAML-parsing tools like yq.

Usage:
    python3 scripts/read_config.py <dotted.key.path>

Examples:
    python3 scripts/read_config.py backup.source_dir
    python3 scripts/read_config.py nas.mount_point
    python3 scripts/read_config.py nas.username

Exit codes:
    0 - success, value printed to stdout
    1 - key not found or config file missing
"""

import sys
import os
import yaml


def main():
    # Expect exactly one argument: the dotted key path (e.g. "backup.source_dir")
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <dotted.key.path>", file=sys.stderr)
        sys.exit(1)

    key_path = sys.argv[1]

    # config.yaml should be in the project root, one directory above scripts/
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "..", "config.yaml")

    # Make sure the config file actually exists before trying to open it
    if not os.path.exists(config_path):
        print(f"Error: config.yaml not found at {config_path}", file=sys.stderr)
        print("Have you copied config.sample.yaml to config.yaml and filled it in?", file=sys.stderr)
        sys.exit(1)

    # Load and parse the YAML config
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)

    # Walk down the dotted key path (e.g. "backup.source_dir" → config["backup"]["source_dir"])
    value = config
    for key in key_path.split("."):
        if not isinstance(value, dict) or key not in value:
            print(f"Error: key '{key_path}' not found in config.yaml", file=sys.stderr)
            sys.exit(1)
        value = value[key]

    # Print the value — bash will capture this via $( ... )
    print(value)


if __name__ == "__main__":
    main()
