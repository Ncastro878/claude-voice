# claude-voice

Text-to-speech for Claude Code. Hear Claude's responses spoken aloud as you work.

## Requirements

- **macOS** (uses the built-in `say` command)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- `jq` (install with `brew install jq`)

## Installation

### Quick Install (curl)

Navigate to your project directory and run:

```bash
curl -fsSL https://raw.githubusercontent.com/Ncastro878/claude-voice/main/install.sh | bash
```

### Manual Install

1. Clone this repository
2. Run the install script from your project directory:

```bash
/path/to/claude-voice/install.sh
```

After installation, **restart Claude Code** for changes to take effect.

## Usage

Control voice output with slash commands:

| Command | Description |
|---------|-------------|
| `/voice on` | Enable voice output |
| `/voice off` | Disable voice output (stops current speech) |
| `/voice status` | Show current settings |
| `/voice test` | Test the voice output |
| `/voice voices` | List available macOS voices |
| `/voice config voice <name>` | Change voice (e.g., Daniel, Samantha) |
| `/voice config rate <num>` | Change speech rate (words per minute) |
| `/voice config max <num>` | Change max characters before truncation |
| `/voice uninstall` | Remove claude-voice from this project |

## Configuration

Settings are stored in `claude-voice/config.json`:

```json
{
  "enabled": true,
  "voice": "Samantha",
  "rate": 200,
  "max_chars": 3000
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `enabled` | `true` | Whether voice output is active |
| `voice` | `Samantha` | macOS voice name (run `/voice voices` to see options) |
| `rate` | `200` | Speech rate in words per minute |
| `max_chars` | `3000` | Maximum characters to speak (longer responses are truncated) |

## How It Works

claude-voice uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to intercept responses:

1. A **Stop hook** triggers after each Claude response
2. The hook script reads the conversation transcript
3. It extracts the latest assistant message
4. The macOS `say` command speaks the response aloud

The `/voice` slash command is implemented as a [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills) that provides a convenient interface for controlling the feature.

## Limitations

- **macOS only** — Relies on the built-in `say` command, which is not available on Windows or Linux
- **Basic voice synthesis** — Uses macOS's built-in voices, which are functional but not as natural as modern AI voice synthesis
- **Response truncation** — Long responses are truncated to prevent excessively long audio (configurable via `max_chars`)
- **Sequential playback** — Only one response plays at a time; new responses interrupt any currently playing audio
- **No streaming** — Waits for the complete response before speaking (cannot speak as tokens stream in)

## Roadmap

Future improvements under consideration:

- **Wispr integration** — Support for [Wispr](https://wispr.ai/) for more natural voice synthesis
- **ElevenLabs / OpenAI TTS** — Integration with cloud-based voice APIs for higher quality voices
- **Cross-platform support** — Linux support via `espeak` or `festival`, Windows support via PowerShell speech synthesis
- **Streaming audio** — Speak responses as they stream in rather than waiting for completion

## Uninstalling

Run `/voice uninstall` in Claude Code, or manually:

1. Remove the `claude-voice/` directory from your project
2. Remove the Stop hook from `.claude/settings.json`
3. Remove `.claude/skills/voice/` directory

## License

MIT
