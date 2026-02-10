---
name: setting-up-gog-auth
description: Use when setting up gog CLI authentication — storing OAuth credentials, adding Gmail accounts, refreshing tokens, or troubleshooting gog auth issues
---

# Setting Up gog Auth for Gmail

## Overview

`gog` requires OAuth client credentials from Google Cloud Console. Use the `using-google-cloud-console` skills to create the project and credentials, then this skill to store them in `gog` and authorize accounts.

## Prerequisites

- `gog` installed (`/opt/homebrew/bin/gog`)
- A Google account

## Setup Flow

### Step 1: Cloud Console Setup

Use these skills (in order) to create the project, enable the API, and get credentials:

1. **`creating-google-cloud-projects`** — Create a project named "gog-cli"
2. **`enabling-google-cloud-apis`** — Enable the Gmail API (URL: `console.cloud.google.com/apis/library/gmail.googleapis.com`)
3. **`configuring-google-cloud-oauth`** — Configure consent screen (External, add user's email as test user) and create a Desktop OAuth client. Download the credentials JSON.

### Step 2: Store Credentials in gog

```bash
# Find the downloaded credentials file
ls -t ~/Downloads/client_secret_*.json | head -1

# Store it in gog (use the actual filename)
gog auth credentials set ~/Downloads/client_secret_<id>.json

# Verify
gog auth credentials list
```

### Step 3: Authorize Gmail Account

```bash
gog auth add user@gmail.com --services gmail
```

This opens a browser OAuth flow. The user may need to:
- Click through "Google hasn't verified this app" warning (click "Advanced" > "Go to gog-cli")
- Grant Gmail permissions

Verify:
```bash
gog auth list
```

## Managing Accounts

```bash
gog auth add other@gmail.com --services gmail    # Add account
gog auth add user@gmail.com --readonly            # Read-only access
gog auth remove user@gmail.com                    # Remove account
gog auth list                                     # List accounts
```

## Token Lifecycle

```bash
# Force re-consent (expired token or scope changes)
gog auth add user@gmail.com --services gmail --force-consent

# Export/import tokens (backup or transfer)
gog auth tokens export user@gmail.com --out token.json
gog auth tokens import token.json

# Delete token
gog auth tokens delete user@gmail.com

# Browserless auth (SSH, CI)
gog auth add user@gmail.com --services gmail --manual
```

## Keyring

```bash
gog auth status                  # Check backend
gog auth keyring keychain        # macOS Keychain (default)
gog auth keyring file            # File-based storage
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "No OAuth client credentials stored" | Run `gog auth credentials set credentials.json` |
| "No tokens stored" | Run `gog auth add user@gmail.com --services gmail` |
| 401 / token expired | `gog auth add user@gmail.com --services gmail --force-consent` |
| "Access blocked: app not verified" | Add yourself as test user (see `configuring-google-cloud-oauth`) |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping API enablement | Gmail API must be enabled before auth works (see `enabling-google-cloud-apis`) |
| Using "Web application" credential type | Must be "Desktop app" for CLI use (see `configuring-google-cloud-oauth`) |
| Not adding test user | Required while app is in "Testing" status |
| Committing credentials.json | Add to `.gitignore` — contains client secret |
