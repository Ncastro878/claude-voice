#!/bin/bash
# install.sh - Install claude-voice into current project directory
# Can be run locally or piped from curl

set -euo pipefail

# Installation target is always current working directory
PROJECT_DIR="$(pwd)"
INSTALL_DIR="$PROJECT_DIR/claude-voice"
SETTINGS_DIR="$PROJECT_DIR/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# GitHub raw URL for downloading files
REPO_URL="https://raw.githubusercontent.com/Ncastro878/claude-voice/main"

echo "Installing claude-voice into $INSTALL_DIR..."

# Check for required dependencies
if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

if ! command -v say &>/dev/null; then
    echo "Error: 'say' command not found. This tool requires macOS."
    exit 1
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# Check if we're running from curl (no local files) or locally
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
LOCAL_DIR=""

if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
    LOCAL_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
fi

# Download or copy files
if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/speak-response.sh" ]; then
    echo "Installing from local files..."
    cp "$LOCAL_DIR/speak-response.sh" "$INSTALL_DIR/"
    cp "$LOCAL_DIR/claude-voice/claude-voice" "$INSTALL_DIR/"
    if [ -f "$LOCAL_DIR/config.json.example" ]; then
        cp "$LOCAL_DIR/config.json.example" "$INSTALL_DIR/"
    fi
else
    echo "Downloading files from GitHub..."
    curl -fsSL "$REPO_URL/speak-response.sh" -o "$INSTALL_DIR/speak-response.sh"
    curl -fsSL "$REPO_URL/claude-voice/claude-voice" -o "$INSTALL_DIR/claude-voice"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/speak-response.sh"
chmod +x "$INSTALL_DIR/claude-voice"

# Create default config if it doesn't exist
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    cat > "$INSTALL_DIR/config.json" << 'EOF'
{
  "enabled": true,
  "voice": "Samantha",
  "rate": 200,
  "max_chars": 3000
}
EOF
    echo "Created config.json"
fi

# Set up the Claude Code hook
mkdir -p "$SETTINGS_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Check if hook already exists
if jq -e '.hooks.Stop[]?.hooks[]?.command | select(contains("speak-response.sh"))' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "Hook already configured"
else
    # Add the hook
    HOOK_CMD="bash $INSTALL_DIR/speak-response.sh"

    tmp=$(mktemp)
    jq --arg cmd "$HOOK_CMD" '
        .hooks //= {} |
        .hooks.Stop //= [] |
        .hooks.Stop += [{"hooks": [{"type": "command", "command": $cmd}]}]
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

    echo "Added hook to .claude/settings.json"
fi

# Create the /voice skill for slash command support
SKILL_DIR="$SETTINGS_DIR/skills/voice"
SKILL_FILE="$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR"

cat > "$SKILL_FILE" << 'SKILLEOF'
---
name: voice
description: Control text-to-speech for Claude responses
---

Control the claude-voice text-to-speech feature.

## Available Commands

- `/voice on` - Enable voice output
- `/voice off` - Disable voice output (stops current speech)
- `/voice status` - Show current settings
- `/voice test` - Test the voice output
- `/voice voices` - List available macOS voices
- `/voice config voice <name>` - Change voice (e.g., Daniel, Samantha)
- `/voice config rate <num>` - Change speech rate (words/min)
- `/voice config max <num>` - Change max characters before truncation
- `/voice uninstall` - Remove claude-voice from this project

## Action

Run the following command with the user's arguments:

```bash
bash ./claude-voice/claude-voice $ARGUMENTS
```
SKILLEOF

echo "Created /voice skill"

echo ""
echo "Installation complete!"
echo ""
echo "After restarting Claude Code, use these commands:"
echo "  /voice on        Enable speech"
echo "  /voice off       Disable speech"
echo "  /voice status    Show settings"
echo "  /voice test      Test the voice"
echo "  /voice uninstall Remove claude-voice"
echo ""
echo "Restart Claude Code for changes to take effect."
