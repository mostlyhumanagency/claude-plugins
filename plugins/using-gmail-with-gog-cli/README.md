# skill-using-gmail

A Claude Code plugin for reading Gmail via the `gog` CLI — auth setup, searching, reading messages, and checking new emails.

## Skills

| Skill | Description |
|---|---|
| `using-gog-gmail` | Router — routes to auth setup or reading skills |
| `setting-up-gog-auth` | Google Cloud project, OAuth credentials, account management, token lifecycle, troubleshooting |
| `reading-gmail` | Search emails, read messages, check history, threads, attachments |

## Installation

### As a plugin (recommended)

```sh
/plugin marketplace add mostlyhumanagency/skill-using-gmail
```

### Manual

Symlink each skill directory into `~/.claude/skills/`:

```sh
git clone <repo-url>
for skill in skills/using-gog-gmail skills/setting-up-gog-auth skills/reading-gmail; do
  ln -s "$(pwd)/$skill" ~/.claude/skills/$(basename "$skill")
done
```

## Prerequisites

- `gog` CLI installed (`brew install gog` or see [gog releases](https://github.com/tmc/gog))
- A Google account
- For auth setup: Claude Chrome extension (for guided Cloud Console navigation)
