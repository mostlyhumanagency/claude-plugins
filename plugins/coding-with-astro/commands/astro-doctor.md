---
description: "Audit Astro project health: configuration, adapters, TypeScript setup, content collections, and common misconfigurations"
---

# astro-doctor

Audit the health of an Astro project by checking configuration, dependencies, and common issues.

## Process

1. Read astro.config.mjs and validate configuration (output mode, adapter, integrations)
2. Check package.json for astro version and installed integrations
3. Verify tsconfig.json extends astro/tsconfigs/base with strictNullChecks
4. Check src/content.config.ts exists if content collections are used
5. Validate adapter matches deployment target
6. Scan for deprecated APIs (Astro.glob in v5+, legacy content collections, legacy ViewTransitions)
7. Check for missing prerender exports on SSR routes
8. Verify image configuration (domains, remotePatterns) if remote images used
9. Check for common misconfigurations:
   - Missing adapter with SSR routes
   - client: directives on Astro components (not supported)
   - Accessing cookies/headers in prerendered pages
   - Missing alt attributes on Image components
10. Report findings with severity (error, warning, info) and suggested fix
11. Summarize: total issues, health score, top priorities
