---
description: "Audit LiftKit project health: setup, configuration, dependencies, and common misconfigurations"
---

# liftkit-doctor

Audit the health of a LiftKit project by checking setup configuration, dependencies, theme integration, and common misconfigurations.

## Process

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-liftkit-setup.sh` to validate project config
2. Read `components.json` and verify it's valid JSON with expected structure
3. Check `layout.tsx` or `layout.jsx` for `ThemeProvider` wrapping the app
4. Check `globals.css` for `@import url("@/lib/css/index.css")`
5. Check `package.json` for `@chainlift/liftkit` in devDependencies, verify React and Next.js present
6. Check for conflicting Tailwind CSS package (should not be installed alongside LiftKit)
7. Run `${CLAUDE_PLUGIN_ROOT}/scripts/list-liftkit-components.sh` to show installed components
8. Report each finding with severity (error/warning/info) and suggested fix
9. Summarize: total issues, health score, top priorities
