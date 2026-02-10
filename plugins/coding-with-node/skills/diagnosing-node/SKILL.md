---
name: diagnosing-node
description: Use when diagnosing Node.js v24 runtime issues — slow endpoints, CPU spikes, memory growth/leaks, crashes, capturing diagnostic reports, heap snapshots, CPU profiles — or when you see ERR_INSPECTOR_NOT_AVAILABLE, OOM crashes, or need post-mortem debugging.
---

# Diagnosing Node

## Overview

Built-in tools for debugging, profiling, and diagnostics reporting.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Investigating slow endpoints or CPU spikes.
- Tracking memory growth or suspected leaks.
- Capturing crash details for postmortems.
- Debugging live processes safely.

## When Not to Use

- You are looking for code-level linting or style issues.
- You need performance testing under load; use a load-testing tool.
- You need framework-specific tracing instrumentation.

## Quick Reference

- Use the inspector for interactive debugging.
- Capture CPU profiles and heap snapshots for analysis.
- Enable diagnostic reports on fatal error or signals.
- Exclude env/network from reports when sensitive.

## Examples

### Enable reports on fatal errors

```bash
node --report-on-fatalerror app.js
```

### Capture on signal

```bash
node --report-on-signal --report-signal=SIGUSR2 app.js
```

### Write reports to a directory

```bash
node --report-directory=./reports --report-on-fatalerror app.js
```

### Start with inspector

```bash
node --inspect-brk app.js
```

## Common Errors

| Code / Issue | Message Fragment | Fix |
|---|---|---|
| ERR_INSPECTOR_NOT_AVAILABLE | Inspector is not available | Node was built without inspector; use official build |
| ERR_INSPECTOR_ALREADY_ACTIVATED | Inspector already activated | Don't call `inspector.open()` twice |
| FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed | JavaScript heap out of memory | Increase `--max-old-space-size` or fix memory leak |
| ERR_DIAGNOSTIC_DIR | Report directory not writable | Check permissions on `--report-directory` path |
| SIGUSR2 no report | Signal sent but no report generated | Ensure `--report-on-signal` flag is set at startup |

## References

- `diagnostics.md`
