# verify.sh v0.1.3 🐀
# verify.sh v0.1.1 🐀

#!/bin/bash
set -e
. ./config.yaml

echo "🧪 Verifying backup with hashdeep..."
cd "$destination_dir"
hashdeep -r -c md5 -l > "$manifest_file"
hashdeep -rav -f "$manifest_file" > /dev/null
