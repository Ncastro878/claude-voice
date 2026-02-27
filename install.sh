#!/bin/bash
# install.sh - Install claude-voice hook into local Claude Code settings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="$SCRIPT_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
HOOK_SCRIPT="$SCRIPT_DIR/speak-response.sh"

echo "Installing claude-voice (local to this repo)..."

# Make scripts executable
chmod +x "$SCRIPT_DIR/speak-response.sh"
chmod +x "$SCRIPT_DIR/claude-voice"

# Create default config if it doesn't exist
if [ ! -f "$SCRIPT_DIR/config.json" ]; then
    cat > "$SCRIPT_DIR/config.json" << 'EOF'
{
  "enabled": true,
  "voice": "Samantha",
  "rate": 200,
  "max_chars": 1000
}
EOF
    echo "Created config.json with defaults"
fi

# Ensure local .claude directory exists
mkdir -p "$SETTINGS_DIR"

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Check if hook already exists
if jq -e '.hooks.Stop[]?.hooks[]?.command | select(contains("speak-response.sh"))' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "Hook already installed in $SETTINGS_FILE"
else
    # Add the hook (nested format required by Claude Code)
    HOOK_CMD="bash $HOOK_SCRIPT"

    tmp=$(mktemp)
    jq --arg cmd "$HOOK_CMD" '
        .hooks //= {} |
        .hooks.Stop //= [] |
        .hooks.Stop += [{"hooks": [{"type": "command", "command": $cmd}]}]
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

    echo "Added Stop hook to $SETTINGS_FILE"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Commands (run from this directory):"
echo "  ./claude-voice on      # Enable speech"
echo "  ./claude-voice off     # Disable speech"
echo "  ./claude-voice status  # Show current settings"
echo "  ./claude-voice test    # Test voice output"
echo "  ./claude-voice voices  # List available voices"
echo ""
echo "claude-voice is now enabled for this repo only."
echo "Start Claude Code from this directory to use it."
