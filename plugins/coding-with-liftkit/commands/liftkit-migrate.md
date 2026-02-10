---
description: "Analyze and migrate a project from Tailwind CSS or plain CSS to LiftKit"
---

# liftkit-migrate

Analyze an existing project using Tailwind CSS or plain CSS and generate a migration plan to LiftKit, with file-by-file guided changes.

## Process

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-liftkit-tokens.sh` to find hardcoded colors
2. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-component-usage.sh` to find replaceable HTML
3. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-responsive.sh` to find responsive anti-patterns
4. Scan for Tailwind utility classes in `.tsx`/`.jsx` files and map to LiftKit equivalents
5. Generate a migration report: total findings by category, suggested changes
6. Prioritize changes by impact (layout structure > components > utility classes > colors)
7. Offer to apply changes file-by-file with user confirmation
