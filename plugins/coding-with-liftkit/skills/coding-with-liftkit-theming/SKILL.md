---
name: coding-with-liftkit-theming
description: This skill should be used when the user asks to "customize LiftKit theme", "add dark mode", "change colors", "use ThemeProvider", "ThemeController", "color tokens", or sees CSS variable errors like "--light__*_clv" or "--dark__*_clv"
---

# LiftKit Theming

## Overview

LiftKit's color system uses Material Design 3 tokens as CSS custom properties. The `Theme` component provides colors via React context on `:root`, and `ThemeController` offers a live control panel for real-time adjustments.

## When to Use

- Setting up theme provider in layout
- Customizing colors or adding dark mode
- Using `ThemeController` for live preview
- Seeing color variable errors or unstyled components
- Working with `LkColorWithOnToken` or `LkColor` types

## Core Patterns

### Theme Provider Setup

Wrap your app in `ThemeProvider` in the root layout:

```tsx
import ThemeProvider from "@/registry/nextjs/components/theme";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

### Live Theme Controller

Drop anywhere to get a real-time theme adjustment panel:

```tsx
import ThemeController from "@/registry/nextjs/components/theme-controller";

<ThemeController />
```

### Dark Mode

Automatic via media query:
```css
@media (prefers-color-scheme: dark) { /* auto-remaps tokens */ }
```

Manual override with data attributes:
```html
<html data-color-mode="dark">
<div data-force-dark-mode="true">
```

### Custom Theme Colors

Override MD3 tokens with CSS custom properties:

```css
:root {
  --light__primary_clv: #6750A4;
  --light__onprimary_clv: #FFFFFF;
  --light__secondary_clv: #625B71;
  --light__tertiary_clv: #7D5260;
  --dark__primary_clv: #D0BCFF;
  --dark__onprimary_clv: #381E72;
}
```

### Programmatic Theme Switching

```tsx
"use client";
import { useState } from "react";

function ThemeToggle() {
  const [isDark, setIsDark] = useState(false);

  return (
    <Button
      label={isDark ? "Light Mode" : "Dark Mode"}
      onClick={() => {
        document.documentElement.setAttribute(
          "data-color-mode",
          isDark ? "light" : "dark"
        );
        setIsDark(!isDark);
      }}
    />
  );
}
```

## Quick Reference

See [color-tokens-reference.md](./color-tokens-reference.md) for the full token list.

| Token Category | Examples | Use For |
|---|---|---|
| Primary/Secondary/Tertiary | `primary`, `secondary`, `tertiary` | Brand colors, accents |
| Surface containers | `surface`, `surfacecontainerhigh`, `surfacecontainerlow` | Background layering |
| Semantic | `error`, `warning`, `success`, `info` | Status feedback |
| On-tokens | `onprimary`, `onsurface`, `onerror` | Text/icon on colored backgrounds |
| Inverse | `inverseprimary`, `inversesurface` | Contrast switching |

### CSS Variable Pattern

```css
/* Light mode */
var(--light__primary_clv)
var(--light__surfacecontainerhigh_clv)

/* Dark mode (auto-mapped) */
var(--dark__primary_clv)
```

## Common Mistakes

**Missing ThemeProvider** — Colors won't resolve without `<ThemeProvider>` wrapping the app.

**Using hex values instead of tokens** — Always use LiftKit color tokens (`color="primary"`) so dark mode works automatically.

**Confusing on-tokens** — `onprimary` is the text/icon color to use **on top of** `primary` backgrounds, not a variant of primary.
