# coding-with-liftkit

Claude Code plugin for LiftKit UI framework — 10 skills, 4 agents, 4 commands, 5 scripts, and 6 templates for building golden-ratio UIs with Next.js.

## Skills

| Skill | Description |
|---|---|
| `coding-with-liftkit` | Router — routes to the most specific LiftKit subskill |
| `installing-liftkit` | Setup, npx liftkit init, component installation, troubleshooting |
| `coding-with-liftkit-components` | Button, Card, Dropdown, Select, Tabs, TextInput, Navbar, Snackbar, Badge, IconButton |
| `coding-with-liftkit-layout` | Section, Container, Grid, Row, Column, page structure |
| `coding-with-liftkit-materials` | Glass, flat, rubber effects, MaterialLayer, StateLayer, optical corrections |
| `coding-with-liftkit-theming` | Themes, colors, dark mode, Theme/ThemeController, CSS custom properties |
| `coding-with-liftkit-typography` | Text, Heading, LkFontClass, golden-ratio type scaling, fontClass prop |
| `coding-with-liftkit-utility-classes` | Spacing, colors, borders, shadows, responsive breakpoints |
| `coding-with-liftkit-forms` | Forms with TextInput, Select, validation patterns, login/signup/settings |
| `coding-with-liftkit-recipes` | Complete UI patterns — hero, auth, dashboard, settings, card grid, sidebar |

## Agents

| Agent | Model | Description |
|---|---|---|
| `liftkit-expert` | opus | General-purpose LiftKit expert — installation, components, theming, layout |
| `liftkit-debugger` | sonnet | Diagnose rendering issues, broken styles, config errors |
| `liftkit-design-reviewer` | sonnet | Audit design system compliance — tokens, spacing, materials |
| `liftkit-a11y-auditor` | sonnet | WCAG 2.1 accessibility audit — contrast, ARIA, keyboard nav |

## Commands

| Command | Description |
|---|---|
| `/liftkit-doctor` | Audit project health: setup, config, dependencies, misconfigurations |
| `/liftkit-theme` | Generate or customize a LiftKit theme with custom colors and dark mode |
| `/liftkit-add-page` | Scaffold a new page from a template (landing, dashboard, auth, settings, blog) |
| `/liftkit-migrate` | Analyze and migrate from Tailwind CSS or plain CSS to LiftKit |

## Scripts

| Script | Description |
|---|---|
| `check-liftkit-setup.sh` | Validate project configuration (components.json, ThemeProvider, CSS import, deps) |
| `check-liftkit-tokens.sh` | Find hardcoded colors that should use LiftKit tokens |
| `check-component-usage.sh` | Find raw HTML replaceable by LiftKit components |
| `check-responsive.sh` | Detect responsive anti-patterns (hardcoded px, missing autoResponsive) |
| `list-liftkit-components.sh` | List installed LiftKit components from components.json |

## Templates

| Template | Description |
|---|---|
| `layout-root.tsx` | Next.js root layout with ThemeProvider, fonts, CSS import |
| `page-landing.tsx` | Landing page with hero, features grid, CTA |
| `page-dashboard.tsx` | Dashboard with navbar, stats grid, tabs |
| `component-form.tsx` | Form component with TextInput, Select, validation |
| `navbar.tsx` | Responsive navbar with theme toggle |
| `theme-custom.css` | CSS custom property overrides for light/dark modes |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/coding-with-liftkit
```
