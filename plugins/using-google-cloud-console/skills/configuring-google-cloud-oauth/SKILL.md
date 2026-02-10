---
name: configuring-google-cloud-oauth
description: Use when configuring OAuth consent screen, creating OAuth client credentials, or downloading credentials JSON in Google Cloud Console via Chrome browser automation
---

# Configuring OAuth in Google Cloud Console

## Overview

Set up OAuth 2.0 for CLI tools and applications by configuring the consent screen and creating client credentials, using Chrome integration to navigate Cloud Console.

## Prerequisites

- Chrome integration active (`/chrome`)
- A Google Cloud project with the required API(s) enabled (see `enabling-google-cloud-apis`)

## Step 1: Configure OAuth Consent Screen

Navigate to `https://console.cloud.google.com/apis/credentials/consent`. Then:

1. **User type**: select "External" (unless the user has a Workspace org and wants "Internal")
2. Click "Create"
3. Fill in the required fields:
   - **App name**: name of the tool (e.g., "gog-cli", "my-app")
   - **User support email**: select the user's email from the dropdown
   - **Developer contact email**: type the user's email address
4. Click "Save and Continue"
5. **Scopes page**: click "Save and Continue" (most CLI tools request scopes at auth time, not here)
6. **Test users page**: click "Add Users", type the user's email address, click "Add", then "Save and Continue"
7. Click "Back to Dashboard"

### About Test Users

While the app is in "Testing" status (not published), only users listed as test users can authorize. This is the recommended state for personal CLI tools — publishing requires Google's verification process.

## Step 2: Create OAuth Client ID

Navigate to `https://console.cloud.google.com/apis/credentials`. Then:

1. Click "Create Credentials" at the top of the page
2. Select "OAuth client ID" from the dropdown menu
3. **Application type**: choose based on use case:

| Use Case | Application Type |
|----------|-----------------|
| CLI tool (gog, gcloud, custom scripts) | Desktop app |
| Web application with callback URL | Web application |
| Mobile app | Android / iOS |

4. **Name**: descriptive name (e.g., "gog-cli", "my-app-desktop")
5. Click "Create"
6. A dialog appears with the client ID and secret

## Step 3: Download Credentials JSON

In the dialog that appears after creating the client:

1. Click "Download JSON"
2. Note the download path (typically `~/Downloads/client_secret_<id>.json`)

If the dialog was dismissed, re-download from the credentials list:

1. Navigate to `https://console.cloud.google.com/apis/credentials`
2. Find the OAuth client in the list
3. Click the download icon on the right side

## Verify Setup

After downloading credentials:

1. The credentials JSON file should contain `client_id`, `client_secret`, and `redirect_uris`
2. The OAuth consent screen should show "Testing" status
3. The user's email should be listed as a test user

## Managing Existing Credentials

### Edit Consent Screen

Navigate to `https://console.cloud.google.com/apis/credentials/consent` to:
- Update app name or contact emails
- Add or remove test users
- Add scopes (usually not needed — most tools request scopes at auth time)

### Edit or Delete Client

Navigate to `https://console.cloud.google.com/apis/credentials` to:
- Click a client name to edit redirect URIs or other settings
- Click the trash icon to delete a client

### Regenerate Client Secret

1. Navigate to `https://console.cloud.google.com/apis/credentials`
2. Click the client name
3. Click "Reset Secret"
4. Download the new credentials JSON

## Common Issues

| Issue | Fix |
|-------|-----|
| "Access blocked: app not verified" | User must be added as a test user in consent screen |
| "Redirect URI mismatch" | Ensure the app type matches (Desktop for CLI, Web for web apps) |
| Can't find "Create Credentials" button | Check you're on the Credentials page, not the Consent screen |
| OAuth consent screen shows "Published" | Reset to "Testing" unless you've gone through Google verification |
| Consent screen requires privacy policy URL | Only required for "Published" apps — keep in "Testing" mode |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Choosing "Web application" for CLI tools | Must be "Desktop app" for tools that run locally |
| Not adding yourself as test user | Required while app status is "Testing" |
| Publishing the app to production | Keep in "Testing" for personal use — avoids verification requirement |
| Committing credentials JSON to git | Contains client secret — add to `.gitignore` |
| Configuring scopes in the consent screen | Most CLI tools request scopes at auth time — leave scopes empty |
