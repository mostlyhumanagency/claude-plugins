#!/bin/bash
# SessionEnd hook: stop the LSP daemon and clean up.

INFO_FILE="/tmp/cc-tslsp-info.json"

if [ -f "$INFO_FILE" ]; then
  PID=$(jq -r '.pid' "$INFO_FILE" 2>/dev/null)
  SOCK=$(jq -r '.socketPath' "$INFO_FILE" 2>/dev/null)

  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null
  fi

  [ -n "$SOCK" ] && rm -f "$SOCK"
  rm -f "$INFO_FILE"
fi

exit 0
