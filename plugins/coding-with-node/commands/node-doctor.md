---
description: "Audit Node.js project health: package.json, engine compatibility, deprecated APIs, and misconfigurations"
---

# node-doctor

Audit the health of a Node.js project by checking package.json configuration, engine compatibility, deprecated API usage, and common misconfigurations.

## Process

1. Read package.json and validate required fields (name, version, main/exports, engines)
2. Check engines.node against installed Node.js version
3. Detect deprecated Node.js APIs in source files (new Buffer(), url.parse(), querystring.parse(), domain, util.pump, fs.exists())
4. Check for missing "type" field (ambiguous module system)
5. Validate "exports" field structure if present
6. Check for common misconfigurations: "main" pointing to nonexistent file, missing "files" field, "scripts.start" missing
7. Check for .nvmrc / .node-version consistency with engines.node
8. Report each finding with severity (error, warning, info) and suggested fix
9. Summarize: total issues, health score, top priorities
