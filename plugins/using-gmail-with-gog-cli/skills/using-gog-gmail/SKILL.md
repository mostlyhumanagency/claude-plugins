---
name: using-gog-gmail
description: Use when reading, searching, or checking Gmail via the gog CLI tool
---

# Using gog for Gmail

## Overview

`gog` is a CLI tool for Google services installed at `/opt/homebrew/bin/gog`. For Gmail, it provides search, read, history, threads, and attachments. Tokens are stored in the system keyring.

## When to Use

Route to the appropriate subskill:

| Need | Skill |
|------|-------|
| First-time setup, OAuth credentials, adding accounts | `setting-up-gog-auth` |
| Search emails, read messages, check new emails, attachments | `reading-gmail` |

## Quick Check

```bash
gog auth list          # See authenticated accounts
gog auth status        # Check keyring backend and config
```

If `gog auth list` shows "No tokens stored", use `setting-up-gog-auth` first.
