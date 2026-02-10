# Node Security (v24)

## Permission Model (v24+)

The permission model restricts what a Node.js process can access. Enable specific permissions with flags:

| Flag | Controls |
|---|---|
| `--allow-fs-read=path` | File system read access |
| `--allow-fs-write=path` | File system write access |
| `--allow-child-process` | Spawning child processes |
| `--allow-worker` | Creating Worker threads |
| `--allow-addons` | Loading native addons |

```bash
# Only allow reading from /app and writing to /app/logs
node --allow-fs-read=/app --allow-fs-write=/app/logs server.js

# Allow reading all files but no child processes or workers
node --allow-fs-read=* server.js

# Multiple paths
node --allow-fs-read=/app/config --allow-fs-read=/app/data server.js
```

When a denied operation is attempted, Node throws `ERR_ACCESS_DENIED`.

## Input Validation

- Validate all user input at system boundaries (HTTP requests, CLI args, file reads).
- Reject invalid input early; don't try to sanitize and reuse.
- Use allowlists over denylists.

```js
function validateUsername(input) {
  if (typeof input !== 'string') throw new Error('Username must be a string');
  if (input.length < 3 || input.length > 30) throw new Error('Username must be 3-30 characters');
  if (!/^[a-zA-Z0-9_-]+$/.test(input)) throw new Error('Username contains invalid characters');
  return input;
}
```

## Prototype Pollution Prevention

Prototype pollution occurs when an attacker modifies `Object.prototype` through unsafe object merging.

### Vulnerable pattern

```js
// BAD — merge from untrusted source pollutes prototype
function merge(target, source) {
  for (const key in source) {
    target[key] = source[key]; // __proto__ can be set here
  }
}
```

### Safe patterns

```js
// Use Object.create(null) for lookup maps
const lookup = Object.create(null);

// Freeze objects that should not change
const config = Object.freeze({ port: 3000, host: 'localhost' });

// Filter dangerous keys when merging
function safeMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue;
    target[key] = source[key];
  }
}

// Use Map instead of plain objects for dynamic keys
const sessions = new Map();
```

## Path Traversal Defense

Never concatenate user input directly into file paths.

```js
import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';

const BASE_DIR = resolve('/app/public');

async function serveFile(userPath) {
  const resolved = resolve(BASE_DIR, userPath);
  if (!resolved.startsWith(BASE_DIR + '/') && resolved !== BASE_DIR) {
    throw new Error('Path traversal detected');
  }
  return readFile(resolved);
}
```

**Why `startsWith(BASE_DIR + '/')` and not just `startsWith(BASE_DIR)`?** Because `/app/public-secret` starts with `/app/public` but is outside the base directory.

## Command Injection

Never pass user input to shell commands.

```js
import { execFile } from 'node:child_process';

// BAD — shell injection
import { exec } from 'node:child_process';
exec(`ls ${userInput}`); // userInput: "; rm -rf /"

// GOOD — no shell, arguments as array
execFile('ls', [userInput]);

// BAD — shell: true with user input
import { spawn } from 'node:child_process';
spawn('cmd', [userInput], { shell: true });

// GOOD — shell: false (default)
spawn('cmd', [userInput]);
```

**Rules:**
- Never use `exec()` with user input — it spawns a shell.
- Never set `shell: true` in `spawn`/`execFile` with user input.
- Never pass user input to `eval()`, `Function()`, or `vm.runInNewContext()`.

## Dependency Security

### npm audit

```bash
# Check for known vulnerabilities
npm audit

# Fix automatically where possible
npm audit fix

# Production only
npm audit --omit=dev
```

### Lockfile integrity

- Always commit `package-lock.json`.
- Use `npm ci` in CI/CD (installs from lockfile exactly).
- Review lockfile changes in pull requests.

### Supply chain attacks

- Pin dependencies to exact versions for critical applications.
- Use `npm pack --dry-run` to inspect what a package publishes.
- Be cautious of typosquatting (e.g., `lodash` vs `1odash`).
- Consider using `npm config set ignore-scripts true` for untrusted packages.

## HTTP Security Headers

For Node.js HTTP servers, set these headers:

```js
function setSecurityHeaders(res) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '0'); // Disabled; use CSP instead
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
}
```

## Secret Management

- Store secrets in environment variables.
- Never hardcode secrets in source code.
- Never commit `.env` files to git — add to `.gitignore`.
- Use a secrets manager in production (cloud provider vaults, etc.).

```js
// Read from environment
const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('API_KEY environment variable is required');

// .env file (for local development only)
// Load with a library like dotenv or use --env-file flag (v24+)
```

```bash
# Node v24+ built-in .env support
node --env-file=.env app.js
```

## Quick Reference

| Threat | Defense |
|---|---|
| Prototype pollution | `Object.create(null)`, `Object.freeze()`, filter keys |
| Path traversal | `resolve()` + `startsWith()` check |
| Command injection | `execFile()` without shell, no `eval()` |
| SQL injection | Parameterized queries (see using-node-sqlite) |
| Dependency attacks | `npm audit`, lockfile, pin versions |
| Secret exposure | Environment variables, .gitignore .env |
| Missing headers | Set CSP, HSTS, X-Content-Type-Options |
| Unrestricted access | Permission model flags (--allow-*) |

## Common Mistakes

**Using `eval()` or `Function()` with user input** — These execute arbitrary code. There is almost never a valid reason to use them with dynamic input.

**Using `exec()` instead of `execFile()`** — `exec()` spawns a shell, enabling injection. Use `execFile()` with arguments as an array.

**Concatenating user input into file paths** — Always resolve and validate against a base directory.

**Trusting `req.body` without validation** — Always validate shape, type, and bounds of incoming data.

**Committing secrets to git** — Even if removed later, secrets remain in git history. Rotate compromised secrets immediately.

**Ignoring `npm audit` warnings** — Run audits regularly and update vulnerable dependencies.

## Do / Don't

- Do validate all input at system boundaries.
- Do use the permission model to restrict process capabilities.
- Do use `Object.create(null)` for lookup objects with dynamic keys.
- Do use `execFile()` instead of `exec()` for child processes.
- Do run `npm audit` regularly.
- Do store secrets in environment variables.
- Don't pass user input to `eval()`, `Function()`, or shell commands.
- Don't concatenate user input into file paths or SQL queries.
- Don't commit `.env` files or secrets to version control.
- Don't use `Object.assign()` or spread with untrusted data without filtering.
- Don't ignore security headers on HTTP responses.

## Examples

### Permission model in practice

```bash
# Minimal permissions for a web server
node \
  --allow-fs-read=/app \
  --allow-fs-write=/app/logs \
  server.js
```

### Safe request handler

```js
import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';

const PUBLIC_DIR = resolve('/app/public');

const server = createServer(async (req, res) => {
  setSecurityHeaders(res);

  const url = new URL(req.url, `http://${req.headers.host}`);
  const filePath = resolve(PUBLIC_DIR, '.' + url.pathname);

  if (!filePath.startsWith(PUBLIC_DIR + '/') && filePath !== PUBLIC_DIR) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  try {
    const content = await readFile(filePath);
    res.writeHead(200);
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end('Not Found');
  }
});
```

## Verification

- Run `npm audit` to check dependency vulnerabilities.
- Test permission model by running without flags and confirming `ERR_ACCESS_DENIED`.
- Review code for `eval`, `exec`, and unsanitized path joins.
