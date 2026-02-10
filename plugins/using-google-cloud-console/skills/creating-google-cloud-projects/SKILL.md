---
name: creating-google-cloud-projects
description: Use when creating a new Google Cloud project via Chrome browser automation
---

# Creating Google Cloud Projects

## Overview

Create Google Cloud projects by navigating the Cloud Console via Chrome integration. Projects are containers for APIs, credentials, billing, and resources.

## Prerequisites

- Chrome integration active (`/chrome`)
- User logged into Google Cloud Console

## Create a Project

Navigate to `https://console.cloud.google.com/projectcreate`. Then:

1. Fill in "Project name" (e.g., "my-app", "gog-cli", "dev-tools")
2. Organization: leave default unless user specifies otherwise
3. Location: leave default unless user specifies otherwise
4. Click "Create"
5. Wait for the notification toast confirming project creation (can take 10-30 seconds)
6. Verify: the project selector in the top-left should now show the new project

## Select an Existing Project

If the project already exists:

1. Click the project selector dropdown in the top-left of any Cloud Console page
2. Search for the project name
3. Click to select it

Or navigate directly: `https://console.cloud.google.com/home/dashboard?project=PROJECT_ID`

## Verify Project

After creation or selection, confirm by checking:
- Project name in the top-left selector
- Navigate to `https://console.cloud.google.com/home/dashboard` — it should show the project overview

## Common Issues

| Issue | Fix |
|-------|-----|
| "You don't have permission" | User needs Owner or Editor role on the org/folder |
| Project name already taken | Project IDs are globally unique — pick a different name |
| Project not appearing after creation | Wait 30 seconds, then refresh the page |
| Wrong project selected | Always check the project selector before making changes |
