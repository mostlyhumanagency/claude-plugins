---
name: securing-node-applications
description: Use when hardening a Node.js app against attacks, validating user input, preventing injection vulnerabilities, reviewing code for security issues, managing secrets, setting HTTP security headers, or configuring the Node.js permission model — covers input sanitization, prototype pollution prevention, path traversal protection, command injection defense, dependency auditing, CORS, CSP, and --allow-fs/--allow-child-process flags.
---

# Securing Node Applications

## Overview

Apply defense-in-depth to Node.js applications through input validation, permission controls, and secure coding patterns.

## Version Scope

Covers Node.js v24 (current) through latest LTS. The permission model (--allow-*) is v24+ and may be experimental.

## When to Use

- Validating user input at system boundaries.
- Configuring the Node.js permission model.
- Reviewing code for injection, path traversal, or prototype pollution.
- Setting up dependency auditing and secret management.
- Adding HTTP security headers to a server.

## When Not to Use

- TLS certificate configuration — use node:tls docs.
- Authentication/authorization logic for specific frameworks — use framework docs.
- Cryptographic operations — use `using-node-crypto`.

## Quick Reference

- Never trust user input; validate at every system boundary.
- Use `--allow-fs-read`, `--allow-fs-write` to restrict file system access.
- Use `Object.create(null)` for lookup maps to prevent prototype pollution.
- Use `path.resolve()` + `startsWith()` to prevent path traversal.
- Never pass user input to `eval()`, `Function()`, or `child_process` with `shell: true`.
- Run `npm audit` regularly; review lockfile integrity.
- Store secrets in environment variables, never in source code.

## Examples

### Permission model

```bash
node --allow-fs-read=/app/data --allow-fs-write=/app/logs app.js
```

### Safe path handling

```js
import { resolve, join } from 'node:path';

function safePath(baseDir, userInput) {
  const resolved = resolve(baseDir, userInput);
  if (!resolved.startsWith(resolve(baseDir))) {
    throw new Error('Path traversal detected');
  }
  return resolved;
}
```

### Prototype pollution prevention

```js
// Safe lookup map
const config = Object.create(null);
config.key = 'value';
// config has no __proto__, constructor, or toString
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_ACCESS_DENIED | Permission denied | Add the required --allow-* flag for the operation |
| ERR_INVALID_ARG_VALUE | Invalid input | Validate and sanitize input before passing to APIs |

## References

- `security.md`
