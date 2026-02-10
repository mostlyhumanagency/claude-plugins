---
description: "Scaffold a new page with LiftKit components based on a page type template"
argument-hint: "[landing|dashboard|auth|settings|blog]"
---

# liftkit-add-page

Scaffold a new Next.js page using LiftKit components, choosing from predefined page type templates for consistent structure and styling.

## Process

1. Determine page type from `$ARGUMENTS` or ask user (landing, dashboard, auth, settings, blog)
2. Read the appropriate template from `${CLAUDE_PLUGIN_ROOT}/templates/` for reference
3. Ask for any customization (page name, route path, specific components needed)
4. Generate the page file with proper LiftKit imports, Section/Container/Grid structure
5. Include appropriate material effects and responsive patterns
6. Add the page to the Next.js app directory at the specified route
7. Verify all components used are installed (check `components.json`), install missing ones
