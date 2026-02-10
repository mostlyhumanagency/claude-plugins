# Reading Gmail Reference

## Output Formats

### Global Flags

Every `gog gmail` command supports these output flags:

| Flag | Effect |
|------|--------|
| `--json` | JSON output (best for scripting/parsing) |
| `--plain` | TSV output, no colors (stable, parseable) |
| `--color=never` | Disable colored output |
| `--account user@gmail.com` | Target specific account (required if multiple accounts) |

### Search Output

**Text (default):** Thread summary with date, sender, subject, snippet.

**JSON (`--json`):** Full thread metadata including thread ID, message IDs, labels, dates.

**Plain (`--plain`):** Tab-separated values for scripting.

### Message Output

**Full (`--format full`):** Headers + decoded body (default).

**Metadata (`--format metadata`):** Headers only, no body. Use `--headers` to select specific headers.

**Raw (`--format raw`):** Raw MIME content (base64 encoded in JSON mode).

## Common Workflows

### Find and Read a Specific Email

```bash
# 1. Search for it
gog gmail search "from:amazon subject:order" --account user@gmail.com --max 5

# 2. Get thread ID from results, read the full thread
gog gmail thread get <threadId> --account user@gmail.com --full

# Or get a specific message
gog gmail get <messageId> --account user@gmail.com
```

### Check for New Emails

```bash
# First run stores the history ID; subsequent runs show new messages
gog gmail history --account user@gmail.com

# JSON for automated processing
gog gmail history --account user@gmail.com --json
```

### Find and Download Attachments

```bash
# 1. Search for emails with attachments
gog gmail messages search "has:attachment from:accounting" --account user@gmail.com

# 2. List attachments in a thread
gog gmail thread attachments <threadId> --account user@gmail.com

# 3. Download all attachments from a thread
gog gmail thread get <threadId> --account user@gmail.com --download --out-dir ./downloads

# 4. Or download a single attachment by ID
gog gmail attachment <messageId> <attachmentId> --account user@gmail.com --out ./invoice.pdf
```

### Search with Body Content

```bash
# Include message body in search results (messages, not threads)
gog gmail messages search "from:hr" --account user@gmail.com --include-body --json
```

### Open Email in Browser

```bash
# Get Gmail web URL for a thread
gog gmail url <threadId>
```

## Search: Threads vs Messages

| Command | Returns | Use When |
|---------|---------|----------|
| `gog gmail search` | Threads (grouped conversations) | Finding conversations |
| `gog gmail messages search` | Individual messages | Finding specific messages, using `--include-body` |

## Timezone Handling

```bash
# Use specific timezone
gog gmail search "newer_than:1d" --account user@gmail.com -z America/New_York

# Force local timezone (default)
gog gmail search "newer_than:1d" --account user@gmail.com --local

# Show oldest message date instead of newest
gog gmail search "from:team" --account user@gmail.com --oldest
```

## Pagination

When results exceed `--max`, the output includes a page token:

```bash
# First page
gog gmail search "label:inbox" --account user@gmail.com --max 10

# Next page (use token from previous output)
gog gmail search "label:inbox" --account user@gmail.com --max 10 --page <pageToken>
```
