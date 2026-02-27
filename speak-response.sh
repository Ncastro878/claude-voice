#!/bin/bash
# speak-response.sh - Speaks Claude Code responses aloud using macOS say
# This script is called by Claude Code's Stop hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
PID_FILE="/tmp/claude-voice.pid"

# Read stdin (JSON from Claude Code hook)
INPUT=$(cat)

# Check if stop_hook_active to prevent loops
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Load config (or use defaults)
ENABLED="true"
VOICE="Samantha"
RATE="200"
MAX_CHARS="1000"

if [ -f "$CONFIG_FILE" ]; then
    ENABLED=$(jq -r '.enabled // true' "$CONFIG_FILE" 2>/dev/null || echo "true")
    VOICE=$(jq -r '.voice // "Samantha"' "$CONFIG_FILE" 2>/dev/null || echo "Samantha")
    RATE=$(jq -r '.rate // 200' "$CONFIG_FILE" 2>/dev/null || echo "200")
    MAX_CHARS=$(jq -r '.max_chars // 1000' "$CONFIG_FILE" 2>/dev/null || echo "1000")
fi

# Exit if disabled
if [ "$ENABLED" != "true" ]; then
    exit 0
fi

# Get transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# Get the last assistant message with text content from the transcript
# Read from end (tac) to find most recent quickly
RESPONSE=""
while IFS= read -r line; do
    msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    if [ "$msg_type" = "assistant" ]; then
        # Join all text content blocks with newlines
        text=$(echo "$line" | jq -r '[.message.content[] | select(.type == "text") | .text] | join("\n")' 2>/dev/null)
        if [ -n "$text" ]; then
            RESPONSE="$text"
            break
        fi
    fi
done < <(tac "$TRANSCRIPT_PATH")

# Exit if no response
if [ -z "$RESPONSE" ]; then
    exit 0
fi

# Kill any previous say process
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
fi

# Truncate if too long
if [ ${#RESPONSE} -gt "$MAX_CHARS" ]; then
    RESPONSE="${RESPONSE:0:$MAX_CHARS}... Response truncated."
fi

# Clean up the text for speech (remove markdown artifacts)
RESPONSE=$(echo "$RESPONSE" | sed 's/```[a-z]*//g' | sed 's/```//g' | sed 's/\*\*//g' | sed 's/`//g')

# Speak in background
say -v "$VOICE" -r "$RATE" "$RESPONSE" &
echo $! > "$PID_FILE"

exit 0
