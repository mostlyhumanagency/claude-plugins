---
name: reading-gmail
description: Use when searching emails, reading message contents, checking new emails, or downloading attachments via the gog CLI
---

# Reading Gmail with gog

## Overview

Use `gog gmail` to search, read, and monitor Gmail. All commands require `--account user@gmail.com` (or omit if only one account is configured). Add `--json` for machine-readable output.

## When to Use

- Searching for specific emails by sender, subject, date, or content
- Reading full message contents by ID
- Checking for new emails since last check
- Reading entire threads
- Downloading attachments

## Core Commands

### Search Emails

```bash
# Search threads (default: 10 results)
gog gmail search "from:support subject:invoice" --account user@gmail.com

# More results
gog gmail search "newer_than:7d" --account user@gmail.com --max 50

# Search individual messages (not threads)
gog gmail messages search "has:attachment" --account user@gmail.com

# Include message body in results
gog gmail messages search "from:boss" --account user@gmail.com --include-body

# JSON output for parsing
gog gmail search "label:inbox is:unread" --account user@gmail.com --json

# Pagination
gog gmail search "..." --account user@gmail.com --page <token>
```

### Read a Message

```bash
# Full message (headers + body)
gog gmail get <messageId> --account user@gmail.com

# Metadata only (fast)
gog gmail get <messageId> --account user@gmail.com --format metadata

# Specific headers only
gog gmail get <messageId> --account user@gmail.com --format metadata --headers "From,Subject,Date"

# Raw MIME
gog gmail get <messageId> --account user@gmail.com --format raw

# JSON output
gog gmail get <messageId> --account user@gmail.com --json
```

### Check New Emails

```bash
# Check history (new emails since last check)
gog gmail history --account user@gmail.com

# With specific start point
gog gmail history --account user@gmail.com --since <historyId>

# JSON output
gog gmail history --account user@gmail.com --json
```

### Read Threads

```bash
# Get full thread
gog gmail thread get <threadId> --account user@gmail.com

# With full message bodies
gog gmail thread get <threadId> --account user@gmail.com --full

# Download thread attachments
gog gmail thread get <threadId> --account user@gmail.com --download

# Save attachments to specific directory
gog gmail thread get <threadId> --account user@gmail.com --download --out-dir ./downloads
```

### Download Attachments

```bash
# Download single attachment
gog gmail attachment <messageId> <attachmentId> --account user@gmail.com

# Save to specific path
gog gmail attachment <messageId> <attachmentId> --account user@gmail.com --out ./file.pdf

# List thread attachments first, then download
gog gmail thread attachments <threadId> --account user@gmail.com
```

## Quick Reference

| Task | Command |
|------|---------|
| Search threads | `gog gmail search "query"` |
| Search messages | `gog gmail messages search "query"` |
| Read message | `gog gmail get <id>` |
| Check new emails | `gog gmail history` |
| Read thread | `gog gmail thread get <id>` |
| Download attachment | `gog gmail attachment <msgId> <attId>` |
| Open in browser | `gog gmail url <threadId>` |

## Gmail Search Operators

| Operator | Example | What it does |
|----------|---------|--------------|
| `from:` | `from:john@example.com` | Sender |
| `to:` | `to:me` | Recipient |
| `subject:` | `subject:meeting` | Subject line |
| `has:attachment` | `has:attachment` | Has attachments |
| `label:` | `label:inbox` | Label/folder |
| `is:unread` | `is:unread` | Unread messages |
| `newer_than:` | `newer_than:7d` | Within time period |
| `older_than:` | `older_than:1m` | Older than period |
| `after:` | `after:2025/01/01` | After date |
| `before:` | `before:2025/06/01` | Before date |
| `filename:` | `filename:pdf` | Attachment type |

Combine operators: `from:boss newer_than:3d has:attachment subject:report`

See [reference.md](./reference.md) for output formats, global flags, and common workflows.
