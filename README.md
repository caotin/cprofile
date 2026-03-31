# cprofile

`cprofile` is a small shell tool for managing multiple Claude Code profile directories on one machine.

It works by switching `~/.claude` to point at one saved profile under `~/.claude-profiles/<name>`. Plain `claude` then uses the currently active profile.

## Paths

`cprofile` uses these global locations:

- Command: `~/.local/bin/cprofile`
- Profile root: `~/.claude-profiles/`
- Active profile pointer: `~/.claude`
- Active profile state file: `~/.config/claude-profile-switch/active`

The script source in this repo is [bin/cprofile](/Users/tinhuynh/Desktop/tito/mk-research/bin/cprofile).

## Install

Local install from this repo:

```bash
bash install.sh
```

Public install with `curl` after you publish [install.sh](/Users/tinhuynh/Desktop/tito/mk-research/install.sh) at a raw public URL:

```bash
curl -fsSL https://<your-public-raw-url>/install.sh | bash
```

Example shape if you later host it on GitHub raw content:

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<branch>/install.sh | bash
```

## Commands

```bash
cprofile list
cprofile current
cprofile add <name>
cprofile use [--force] <name>
cprofile login [--force] <name> [-- <claude auth login args...>]
```

## Quick Start

List profiles:

```bash
cprofile list
```

Show the active profile:

```bash
cprofile current
```

Create a new profile:

```bash
cprofile add work
```

Switch Claude to that profile:

```bash
cprofile use work
```

Log into Claude for that profile:

```bash
cprofile login work
```

Pass login flags through to Claude:

```bash
cprofile login work -- --email you@example.com
cprofile login work -- --console
cprofile login work -- --help
```

If Claude is already running, close it before switching profiles. To override that check:

```bash
cprofile use --force work
```

## Create A New Profile And Edit Settings Quickly

Fastest workflow:

```bash
cprofile add myprofile
cp ~/.claude-profiles/default/settings.json ~/.claude-profiles/myprofile/settings.json
open -e ~/.claude-profiles/myprofile/settings.json
cprofile use myprofile
```

That creates a new profile, copies the default settings, opens the file in TextEdit, and activates the profile.

## Manual `settings.json` Editing

Each profile keeps its own `settings.json`.

Common files:

- Default profile settings: `~/.claude-profiles/default/settings.json`
- A named profile settings file: `~/.claude-profiles/work/settings.json`
- Active profile settings via symlink: `~/.claude/settings.json`

Edit the active profile:

```bash
open -e ~/.claude/settings.json
```

Edit a specific profile without switching:

```bash
open -e ~/.claude-profiles/work/settings.json
```

Example full `settings.json`:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_auth_token_here",
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-3-5-haiku-latest",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-1",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_MODEL": "claude-sonnet-4-5"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Example local proxy setup:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "proxy_token_here",
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:1234",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5.4-mini",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.4-mini",
    "ANTHROPIC_MODEL": "gpt-5.4-mini"
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

After saving changes, run:

```bash
cprofile use <name>
claude
```

## How It Works

`cprofile` manages these pieces:

- `~/.claude-profiles/<name>` stores one Claude profile directory
- `~/.claude` is a symlink to the active profile directory
- `~/.config/claude-profile-switch/active` stores the active profile name

On first bootstrap, the existing `~/.claude` directory is moved into `~/.claude-profiles/default`, then `~/.claude` becomes a symlink to that profile.

## Notes And Limitation

`cprofile` correctly switches the Claude profile directory and its `settings.json`, sessions, plugins, and local profile files.

During verification, an empty temporary profile still showed a logged-in Claude account. That suggests Claude Code may also read some authentication state from outside `~/.claude`. So profile switching is implemented and working, but first-party Claude login isolation may not be fully controlled by the profile directory alone.

Use this tool as a practical profile switcher, but do not assume it guarantees complete account isolation unless Claude Code’s auth storage behavior is fully confirmed.
