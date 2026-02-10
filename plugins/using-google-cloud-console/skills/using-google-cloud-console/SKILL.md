---
name: using-google-cloud-console
description: Use when performing any task in Google Cloud Console — creating projects, enabling APIs, configuring OAuth, or managing credentials
---

# Using Google Cloud Console

## Overview

Perform Google Cloud Console tasks using Claude's Chrome integration (`--chrome` / `/chrome`). Claude navigates the Console UI, clicks buttons, fills forms, and configures settings in a visible Chrome window.

## Prerequisites

- Claude Chrome integration active (run `/chrome` to check/connect)
- User logged into Google Cloud Console in Chrome

## Before Any Console Task

1. Verify Chrome integration: run `/chrome`. If not connected, ask the user to install the [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) and restart with `claude --chrome`.
2. Ask the user which Google account to use if they have multiple.
3. If Chrome integration is unavailable, fall back to giving the user URLs and step-by-step instructions.

## Route to Subskill

| Need | Skill |
|------|-------|
| Create a new Google Cloud project | `creating-google-cloud-projects` |
| Enable a Google API (Gmail, Calendar, Drive, etc.) | `enabling-google-cloud-apis` |
| Set up OAuth consent screen and create credentials | `configuring-google-cloud-oauth` |

## Console Navigation Tips

- **Project selector**: always verify the correct project is selected in the top-left dropdown before making changes.
- **Direct URLs**: prefer navigating to direct URLs (e.g., `console.cloud.google.com/apis/library/gmail.googleapis.com`) over clicking through menus — it's faster and more reliable.
- **Loading states**: Cloud Console pages often have loading spinners. Wait for the page to fully load before interacting.
- **Modals/dialogs**: some actions trigger confirmation dialogs. Look for and click through them.
- **Error banners**: if a red/yellow banner appears, read it and report to the user before continuing.
