---
description: "Analyze dependencies: find unused packages, outdated versions, known vulnerabilities, and duplicates"
---

# node-deps

Analyze project dependencies to find unused packages, outdated versions, known vulnerabilities, and duplicates across the dependency tree.

## Process

1. Run `npm audit --json` (or `pnpm audit --json`) to check for known vulnerabilities; summarize by severity
2. Run `npm outdated --json` (or `pnpm outdated --json`) to find outdated dependencies; group by major/minor/patch updates
3. Scan source files for require() and import statements; compare against dependencies in package.json to find unused deps
4. Check for packages in dependencies that should be in devDependencies (test frameworks, linters, build tools, type packages)
5. Check for duplicate packages in node_modules with `npm ls --all`
6. Flag deprecated packages
7. Report findings grouped by category with actionable fixes
