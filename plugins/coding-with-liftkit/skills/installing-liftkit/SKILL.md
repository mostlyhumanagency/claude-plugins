---
name: installing-liftkit
description: Use when setting up LiftKit in a new or existing Next.js project, running npx liftkit init, installing components, or troubleshooting LiftKit installation
---

# Installing LiftKit

## Overview

LiftKit installs as a dev dependency into Next.js projects. It copies component source files and CSS into your project — no runtime package dependency, just config files and source code you own.

## When to Use

- Starting a new project with LiftKit
- Adding LiftKit to an existing Next.js app
- Installing specific components
- Seeing errors about missing LiftKit CSS or types
- `components.json` or `tailwind.config.ts` not found

**When NOT to use:** For non-Next.js frameworks (not officially supported yet).

## Core Patterns

### New Project (Template Clone)

```bash
git clone https://github.com/Chainlift/liftkit-template.git my-app
cd my-app
npm install
```

This gives you a blank Next.js project with LiftKit Core pre-configured.

### Existing Next.js Project

```bash
npm install @chainlift/liftkit --save-dev
npx liftkit init
```

This creates `components.json` and `tailwind.config.ts` in your project root. Tailwind itself is **not** required — only the config file is needed.

### Installing Components

```bash
# All components + CSS + types
npm run add all

# Single component (kebab-case)
npm run add button
npm run add text-input
npm run add theme-controller

# Base CSS and types only (no components)
npm run add base
```

Dependencies install automatically — adding `dropdown` pulls in `card`, `state-layer`, etc.

### Import CSS

After installing, add to `globals.css`:

```css
@import url("@/lib/css/index.css");
```

## Quick Reference

| Task | Command |
|---|---|
| New project | `git clone https://github.com/Chainlift/liftkit-template.git` |
| Init in existing | `npx liftkit init` |
| Add all components | `npm run add all` |
| Add one component | `npm run add component-name` |
| Add base only | `npm run add base` |

## Common Mistakes

**Skipping CSS import** — Components render unstyled without `@import url("@/lib/css/index.css")` in `globals.css`.

**React 19 peer dep warning** — If prompted about React 19 compatibility, select "Use --force". This is expected.

**Installing Tailwind** — LiftKit only needs `tailwind.config.ts`, not the Tailwind package. Installing both causes class conflicts.

**Wrong component name casing** — Use kebab-case: `npm run add icon-button`, not `iconButton` or `IconButton`.
