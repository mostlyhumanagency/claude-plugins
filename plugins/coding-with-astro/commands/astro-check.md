---
description: "Scan Astro codebase for anti-patterns: missing client directives, hydration issues, deprecated APIs, and suboptimal configurations"
---

# astro-check

Scan the codebase for common Astro anti-patterns and suggest improvements.

## Process

1. Find all .astro files and scan for:
   - Framework components without client: directives (interactive components rendered as static HTML)
   - Browser API usage in frontmatter (window, document, localStorage)
   - Missing alt on Image/Picture components
   - Inline styles that could be scoped
   - Non-serializable props passed to hydrated components
2. Check content collections:
   - Schemas without proper date coercion (z.coerce.date())
   - Missing optional() on non-required fields
   - Hardcoded content paths instead of using getCollection
3. Check routing:
   - getStaticPaths functions that could miss paths
   - Dynamic routes without error handling for missing params
   - Redirect chains (A→B→C)
4. Check SSR patterns:
   - Response modifications in child components instead of pages
   - Missing prerender = false on dynamic routes
   - Session access without null checks
5. Check view transitions:
   - Missing transition:name causing animation glitches
   - Scripts not wrapped in astro:page-load listeners
   - Forms without data-astro-reload when needed
6. Report each finding with file path, line number, severity, and fix
7. Summarize: total issues by severity, recommended action order
