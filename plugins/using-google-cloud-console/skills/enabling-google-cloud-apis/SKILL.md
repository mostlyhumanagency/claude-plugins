---
name: enabling-google-cloud-apis
description: Use when enabling Google APIs (Gmail, Calendar, Drive, Sheets, etc.) in a Google Cloud project via Chrome browser automation
---

# Enabling Google Cloud APIs

## Overview

Enable Google APIs in a Cloud project by navigating the API Library in Cloud Console via Chrome integration. APIs must be enabled before they can be used with OAuth credentials.

## Prerequisites

- Chrome integration active (`/chrome`)
- A Google Cloud project already created (see `creating-google-cloud-projects`)

## Enable an API

### Via Direct URL (Preferred)

Navigate directly to the API's library page using this pattern:

```
https://console.cloud.google.com/apis/library/<API_ID>
```

Then:
1. Verify the correct project is selected in the top-left
2. Click "Enable"
3. Wait for the page to confirm the API is enabled

### Common API Direct URLs

| API | URL |
|-----|-----|
| Gmail | `console.cloud.google.com/apis/library/gmail.googleapis.com` |
| Calendar | `console.cloud.google.com/apis/library/calendar-json.googleapis.com` |
| Drive | `console.cloud.google.com/apis/library/drive.googleapis.com` |
| Sheets | `console.cloud.google.com/apis/library/sheets.googleapis.com` |
| Docs | `console.cloud.google.com/apis/library/docs.googleapis.com` |
| Tasks | `console.cloud.google.com/apis/library/tasks.googleapis.com` |
| People | `console.cloud.google.com/apis/library/people.googleapis.com` |
| Chat | `console.cloud.google.com/apis/library/chat.googleapis.com` |
| Classroom | `console.cloud.google.com/apis/library/classroom.googleapis.com` |
| Cloud Identity | `console.cloud.google.com/apis/library/cloudidentity.googleapis.com` |
| Keep | `console.cloud.google.com/apis/library/keep.googleapis.com` |

### Via API Library Search

If the API ID is unknown:

1. Navigate to `https://console.cloud.google.com/apis/library`
2. Search for the API name (e.g., "Gmail")
3. Click the matching result
4. Click "Enable"

## Verify an API is Enabled

Navigate to `https://console.cloud.google.com/apis/dashboard`. The enabled APIs are listed on this page.

## Enable Multiple APIs

For tools that need several APIs (e.g., `gog` with gmail + calendar + drive), enable each one sequentially using the direct URLs above.

## Common Issues

| Issue | Fix |
|-------|-----|
| "Enable" button not visible | API may already be enabled — check the dashboard |
| "Billing account required" | Some APIs require billing. Navigate to `console.cloud.google.com/billing` to set up |
| Wrong project | Check project selector before enabling |
| API not found | Search the API Library — the name or ID may differ from expected |
