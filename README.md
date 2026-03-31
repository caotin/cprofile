# cprofile

`cprofile` is a small shell tool for managing multiple Claude Code profile directories on one machine.

It works by switching `~/.claude` to point at one saved profile under `~/.claude-profiles/<name>`. Plain `claude` then uses the currently active profile.

Repo: [caotin/cprofile](https://github.com/caotin/cprofile)

## Paths

`cprofile` uses these global locations:

- Command: `~/.local/bin/cprofile`
- Profile root: `~/.claude-profiles/`
- Active profile pointer: `~/.claude`
- Active profile state file: `~/.config/claude-profile-switch/active`

The script source in this repo is [bin/cprofile](https://github.com/caotin/cprofile/blob/main/bin/cprofile).

## Install

Local install from a checked out copy:

```bash
bash install.sh
```

Public install with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/caotin/cprofile/main/install.sh | bash
```

Public files:

- Repo: [caotin/cprofile](https://github.com/caotin/cprofile)
- Installer: [install.sh](https://raw.githubusercontent.com/caotin/cprofile/main/install.sh)
- Script: [bin/cprofile](https://raw.githubusercontent.com/caotin/cprofile/main/bin/cprofile)

## Commands

```bash
cprofile list
cprofile current
cprofile add <name>
cprofile add <name> --wizard
cprofile add <name> -w
cprofile update <name> --wizard
cprofile update <name> -w
cprofile clone <name>
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

Create a new profile and fill Claude settings from terminal input:

```bash
cprofile add local --wizard
```

Short form:

```bash
cprofile add local -w
```

That prompts for:

- host name
- model opus
- sonnet model
- model haiku

Example:

```text
Host name: http://127.0.0.1:1234
Model opus: gpt-5.4
Model sonnet: gpt-5.4-mini
Model haiku: gpt-5.4-mini
```

Update an existing profile with the same wizard flow:

```bash
cprofile update local --wizard
```

Short form:

```bash
cprofile update local -w
```

Clone the current active Claude settings into a new profile:

```bash
cprofile clone local-copy
```

That copies:

- `~/.claude/settings.json`
- `~/.claude/statusline-command.sh` if it exists

Then it prints the new settings path so you can edit it directly.

`update` also prints the profile settings path after rewriting it.

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

You can also generate the settings file directly during profile creation:

```bash
cprofile add myprofile --wizard
```

To edit an existing profile with prompts instead of opening the file manually:

```bash
cprofile update myprofile -w
```

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
