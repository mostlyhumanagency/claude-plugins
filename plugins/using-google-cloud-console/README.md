# using-google-cloud-console

A Claude Code plugin for navigating Google Cloud Console via Chrome integration — creating projects, enabling APIs, and configuring OAuth credentials.

## Skills

| Skill | Description |
|---|---|
| `using-google-cloud-console` | Router — routes to project, API, or OAuth skills |
| `creating-google-cloud-projects` | Create and select Google Cloud projects |
| `enabling-google-cloud-apis` | Enable Google APIs (Gmail, Calendar, Drive, etc.) |
| `configuring-google-cloud-oauth` | OAuth consent screen, client credentials, downloading JSON |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/using-google-cloud-console
```

## Prerequisites

- Claude Chrome integration (`claude --chrome` or `/chrome`)
- [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) v1.0.36+
- Google account with Cloud Console access
