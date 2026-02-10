#!/bin/bash
# SessionStart hook: launch the TS LSP daemon if this is a TypeScript project.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"

# Check for tsconfig.json
if [ ! -f "$PROJECT_DIR/tsconfig.json" ]; then
  exit 0
fi

# Check for tsgo
if ! command -v tsgo &>/dev/null; then
  # Notify Claude that tsgo is missing so it can offer to install
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The typescript-lsp-diagnostics plugin is installed but cannot start because 'tsgo' was not found. Tell the user: the plugin uses TypeScript 7's native Go compiler (tsgo) as a fast LSP server to surface type errors after edits. This is installed separately from the project's TypeScript version — the project can use any TS version, tsgo is only used by this plugin for diagnostics. To install: npm install -g @typescript/native-preview. Offer to run this command for them."}}
EOF
  exit 0
fi

# Kill any existing daemon
INFO_FILE="/tmp/cc-tslsp-info.json"
if [ -f "$INFO_FILE" ]; then
  OLD_PID=$(jq -r '.pid' "$INFO_FILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null
    sleep 0.2
  fi
  rm -f "$INFO_FILE"
fi

# Launch daemon fully detached — redirect all output, nohup, disown
DAEMON="$PLUGIN_DIR/hooks/lsp-daemon.mjs"
nohup node "$DAEMON" "$PROJECT_DIR" > /dev/null 2>&1 &
disown

# Wait up to 5s for the info file (means LSP initialized + socket ready)
for i in $(seq 1 50); do
  if [ -f "$INFO_FILE" ]; then
    break
  fi
  sleep 0.1
done

if [ ! -f "$INFO_FILE" ]; then
  exit 0
fi

# Export socket path for PostToolUse hooks
if [ -n "$CLAUDE_ENV_FILE" ]; then
  SOCK=$(jq -r '.socketPath' "$INFO_FILE")
  PID=$(jq -r '.pid' "$INFO_FILE")
  echo "export CC_TSLSP_SOCK=\"$SOCK\"" >> "$CLAUDE_ENV_FILE"
  echo "export CC_TSLSP_PID=\"$PID\"" >> "$CLAUDE_ENV_FILE"
fi

exit 0
