# Node Diagnostics (v24)

## Debugging and Inspection

- Use the inspector for interactive debugging.
- Keep source maps enabled for TypeScript to preserve stack traces.

## Diagnostics Reports

- Node can generate diagnostic reports containing stack traces, environment, resource usage, and more.
- Use CLI flags to trigger reports on fatal errors, uncaught exceptions, or signals.

Common flags:

- `--report-on-fatalerror`
- `--report-uncaught-exception`
- `--report-on-signal`
- `--report-signal=SIGUSR2`
- `--report-compact`
- `--report-directory=./reports`
- `--report-filename=report.json`
- `--report-exclude-env`
- `--report-exclude-network`

## CPU and Memory

- Capture CPU profiles to find hot paths.
- Take heap snapshots when memory grows over time.
- Look for retained objects and long-lived references.

## Quick Reference

| Tool | Command / API | Use When |
|---|---|---|
| Inspector | `node --inspect-brk app.js` | Interactive debugging with breakpoints |
| Diagnostic report | `--report-on-fatalerror` | Capturing crash details automatically |
| Report on signal | `--report-on-signal --report-signal=SIGUSR2` | On-demand report from running process |
| Report on exception | `--report-uncaught-exception` | Capturing unhandled exception context |
| Report directory | `--report-directory=./reports` | Organizing report output |
| Exclude env | `--report-exclude-env` | Prevent secrets in reports |
| Exclude network | `--report-exclude-network` | Reduce report noise |
| Compact format | `--report-compact` | Machine-readable JSON output |
| CPU profile | Inspector → Profile tab | Finding hot paths and slow functions |
| Heap snapshot | Inspector → Memory tab | Finding memory leaks and retained objects |

## Common Mistakes

**Profiling without a baseline** — A single profile is meaningless without comparison. Always capture before/after profiles to identify regressions.

**Leaving inspector enabled in production** — `--inspect` opens a debugging port. Never expose it in production without authentication.

**Including env/network in reports with secrets** — Diagnostic reports can contain env vars and network info. Use `--report-exclude-env` and `--report-exclude-network`.

**Using sampling profiler for micro-optimizations** — Sampling profiles show statistical hotspots, not exact timings. Don't optimize based on single-sample noise.

## Constraints and Edges

- Profiling adds overhead; avoid in latency-sensitive production paths unless necessary.
- Diagnostic reports can contain sensitive data; exclude env/network where required.
- Always capture a baseline before attributing regressions.

## Do / Don't

- Do capture a report at the moment of failure.
- Do record the exact Node version and flags used.
- Don't profile without a baseline; compare before and after.
- Don't rely on sampling profiles for micro-optimizations.

## Examples

### Enable reports on fatal errors

```bash
node --report-on-fatalerror app.js
```

### Enable reports via signal

```bash
node --report-on-signal --report-signal=SIGUSR2 app.js
```

### Write reports to a directory

```bash
node --report-directory=./reports --report-on-fatalerror app.js
```

## Verification

- Confirm report files are written where expected.
- Inspect reports for stack traces and resource usage.
