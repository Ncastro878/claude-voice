#!/bin/bash
# uninstall.sh - Remove claude-voice hook from local Claude Code settings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/.claude/settings.json"

echo "Uninstalling claude-voice..."

# Kill any running say process
if [ -f "/tmp/claude-voice.pid" ]; then
    pid=$(cat /tmp/claude-voice.pid 2>/dev/null || true)
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
    rm -f /tmp/claude-voice.pid
fi

# Remove hook from settings
if [ -f "$SETTINGS_FILE" ]; then
    tmp=$(mktemp)
    jq '
        if .hooks.Stop then
            .hooks.Stop = [.hooks.Stop[] | select(.command | contains("speak-response.sh") | not)]
        else
            .
        end |
        if .hooks.Stop == [] then del(.hooks.Stop) else . end |
        if .hooks == {} then del(.hooks) else . end
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    echo "Removed hook from $SETTINGS_FILE"
else
    echo "No settings file found at $SETTINGS_FILE"
fi

echo ""
echo "Uninstall complete. You can delete this directory if you no longer need it."
echo "Note: config.json was preserved in case you want to reinstall later."
