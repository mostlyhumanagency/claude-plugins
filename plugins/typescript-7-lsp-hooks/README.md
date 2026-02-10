# claude-plugin-typescript-7-lsp

TypeScript diagnostics for Claude Code — uses tsgo (TypeScript 7 Go compiler) as a fast LSP server to surface type errors after edits.

## What It Does

- **SessionStart**: Launches a tsgo LSP server in the background
- **PostToolUse** (Edit/Write): Checks TypeScript diagnostics on changed files and reports errors
- **SessionEnd**: Stops the LSP server

## Why This Over Built-in LSP Support?

Claude Code has native LSP support, but it runs asynchronously — diagnostics arrive on the *next* turn, after the model has already moved on. This plugin uses PostToolUse hooks to run diagnostics synchronously after every Edit/Write, injecting type errors into the same turn so Claude can fix them immediately without an extra round-trip.

## Installation

### As a plugin (recommended)

```sh
/plugin marketplace add mostlyhumanagency/claude-plugins
/plugin install typescript-7-lsp@mostlyhumanagency
```

### Manual

Place this directory inside `~/.claude/plugins/`:

```sh
git clone https://github.com/mostlyhumanagency/claude-plugin-typescript-7-lsp.git
ln -s "$(pwd)/claude-plugin-typescript-7-lsp" ~/.claude/plugins/typescript-7-lsp
```

## Prerequisites

- `tsgo` binary installed and available in PATH
