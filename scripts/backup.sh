# backup.sh v0.1.3 🐀
# backup.sh v0.1.1 🐀

#!/bin/bash
set -e
. ./config.yaml

echo "🔄 Syncing from $source_dir to $destination_dir"
rsync -avh --delete "$source_dir" "$destination_dir"
