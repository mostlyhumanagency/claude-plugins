# using-gmail-with-gog-cli

A Claude Code plugin for reading Gmail via the `gog` CLI — auth setup, searching, reading messages, and checking new emails.

## Skills

| Skill | Description |
|---|---|
| `using-gog-gmail` | Router — routes to auth setup or reading skills |
| `setting-up-gog-auth` | Google Cloud project, OAuth credentials, account management, token lifecycle, troubleshooting |
| `reading-gmail` | Search emails, read messages, check history, threads, attachments |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/using-gmail-with-gog-cli
```

## Prerequisites

- `gog` CLI installed (`brew install gog` or see [gog releases](https://github.com/tmc/gog))
- A Google account
- For auth setup: Claude Chrome extension (for guided Cloud Console navigation)
