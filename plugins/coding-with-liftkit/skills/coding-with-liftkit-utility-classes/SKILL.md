---
name: coding-with-liftkit-utility-classes
description: Use when applying LiftKit utility classes for spacing, colors, borders, shadows, responsive breakpoints, or when seeing class naming conflicts — NOT compatible with Tailwind
---

# LiftKit Utility Classes

## Overview

LiftKit provides Tailwind-like utility classes for spacing, colors, typography, and layout. They use similar naming conventions but are **not compatible with Tailwind** — installing both causes conflicts. Classes are designed to be used sparingly (1-2 per element), not stacked heavily.

## When to Use

- Applying quick styles without custom CSS
- Using responsive visibility classes
- Adding shadows, borders, or opacity
- Spacing elements with margin/padding classes

**When NOT to use:** Alongside Tailwind. Choose one or the other.

## Core Patterns

### Spacing (Margins & Padding)

Uses golden-ratio derived sizes: `3xs` through `4xl`.

```tsx
<div className="p-md">          {/* padding all sides */}
<div className="px-lg py-sm">   {/* horizontal + vertical */}
<div className="mt-xl mb-md">   {/* margin top + bottom */}
```

### Colors

Background and text colors use token names:

```tsx
<div className="bg-primary">           {/* background */}
<div className="bg-surfacecontainerhigh">
<p className="color-onprimary">         {/* text color */}
<p className="color-onsurface">
```

### Borders

```tsx
<div className="border-sm border-color-outline">
<div className="border-radius-md">
```

### Shadows

```tsx
<div className="shadow1">  {/* subtle */}
<div className="shadow3">  {/* medium */}
<div className="shadow5">  {/* strong */}
```

### Responsive Visibility

```tsx
<div className="show__desktopOnly">    {/* >= 992px */}
<div className="show__tabletDown">     {/* <= 991px */}
<div className="show__landscapeDown">  {/* <= 760px */}
<div className="show__portraitOnly">   {/* <= 479px */}
```

### Display & Flexbox

```tsx
<div className="display-flex">
<div className="display-grid">
<div className="display-none">
```

### Typography

```tsx
<span className="overflow-ellipsis">   {/* truncate with ... */}
<span className="inline-text-wrap">    {/* inline wrapping */}
```

See [utility-classes-reference.md](./utility-classes-reference.md) for the full category list.

## Quick Reference

| Category | Prefix/Pattern | Example |
|---|---|---|
| Padding | `p-`, `px-`, `py-`, `pt-`, `pb-`, `pl-`, `pr-` | `p-md`, `px-lg` |
| Margin | `m-`, `mx-`, `my-`, `mt-`, `mb-`, `ml-`, `mr-` | `mt-xl`, `mx-sm` |
| Background | `bg-{token}` | `bg-primary`, `bg-surface` |
| Text color | `color-{token}` | `color-onprimary` |
| Border color | `border-color-{token}` | `border-color-outline` |
| Border radius | `border-radius-{size}` | `border-radius-md` |
| Shadow | `shadow{1-5}` | `shadow3` |
| Display | `display-{value}` | `display-flex` |
| Visibility | `show__{breakpoint}` | `show__desktopOnly` |

### Size Scale

`3xs` | `2xs` | `xs` | `sm` | `md` | `lg` | `xl` | `2xl` | `3xl` | `4xl`

All derived from golden ratio with subpixel accuracy.

### Responsive Breakpoints

| Breakpoint | Max Width | Class |
|---|---|---|
| Desktop only | >= 992px | `show__desktopOnly` |
| Tablet down | <= 991px | `show__tabletDown` |
| Landscape down | <= 760px | `show__landscapeDown` |
| Portrait only | <= 479px | `show__portraitOnly` |

## Common Mistakes

**Installing Tailwind alongside LiftKit** — Both use similar class names. LiftKit's `tailwind.config.ts` is required but Tailwind itself should not be installed.

**Stacking many utility classes** — LiftKit utilities are meant for 1-2 classes per element. For complex styling, use component props or custom CSS.

**Wrong size token** — LiftKit uses `3xs`-`4xl`, not Tailwind's numeric scale (`1`, `2`, `4`, `8`).
