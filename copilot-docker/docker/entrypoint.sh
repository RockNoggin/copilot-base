#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.copilot"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Ensure trusted_folders includes /workspace
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    echo '{"trusted_folders":["/workspace"]}' > "$CONFIG_FILE"
elif ! grep -q '/workspace' "$CONFIG_FILE" 2>/dev/null; then
    # Add /workspace to trusted_folders using node (available in this image)
    node -e "
      const fs = require('fs');
      const c = JSON.parse(fs.readFileSync('$CONFIG_FILE','utf8'));
      if (!c.trusted_folders) c.trusted_folders = [];
      if (!c.trusted_folders.includes('/workspace')) c.trusted_folders.push('/workspace');
      fs.writeFileSync('$CONFIG_FILE', JSON.stringify(c));
    "
fi

# Validate authentication token
if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "WARNING: Neither GH_TOKEN nor GITHUB_TOKEN is set."
    echo "         Copilot CLI will require interactive authentication."
    echo "         Set GH_TOKEN in your environment or .env file."
fi

# If a command was passed (e.g. docker run --rm <image> copilot ...),
# execute it directly instead of staying alive
if [ $# -gt 0 ]; then
    exec "$@"
fi

# Default: keep container alive for docker exec usage
echo "Copilot container ready. Use 'docker exec' to interact."
exec tail -f /dev/null
