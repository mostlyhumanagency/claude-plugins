---
name: coding-with-liftkit-typography
description: "Use when styling text, choosing font sizes, using the Text or Heading component, applying fontClass or LkFontClass, implementing golden-ratio typography, or troubleshooting font sizing issues in LiftKit."
---

# LiftKit Typography

## Overview

LiftKit derives all typography sizes from the golden ratio (1.618). Font sizes scale responsively — 17.28px at large viewports, 16px at standard, 15px on mobile — with all other sizes computed as proportional steps. Uses Inter for body text and Roboto Mono for code.

## When to Use

- Using Text or Heading components
- Applying `fontClass` props to components
- Setting up custom type scales
- Troubleshooting font sizing or scaling issues

## Core Patterns

### Text Component

Renders any semantic tag with font class control:

```tsx
<Text fontClass="body" tag="p" color="onsurface">
  Body text content
</Text>

<Text fontClass="display1" tag="div" color="primary">
  Large display text
</Text>

<Text fontClass="caption" tag="span">
  Small caption
</Text>
```

| Prop | Type | Description |
|---|---|---|
| `fontClass` | `LkFontClass` | Font size/weight class |
| `tag` | `LkSemanticTag` | HTML tag (`p`, `div`, `span`, `footer`, etc.) |
| `color` | `LkColor` | Text color token |
| `content` | `string` | Text (alternative to children) |

### Heading Component

Shorthand for heading elements:

```tsx
<Heading tag="h1" fontClass="display1-bold">Page Title</Heading>
<Heading tag="h2" fontClass="display2-bold">Section Title</Heading>
<Heading tag="h3" fontClass="title1">Subsection</Heading>
```

| Prop | Type | Default | Description |
|---|---|---|---|
| `tag` | `LkHeadingTag` | `"h2"` | `h1` through `h6` |
| `fontClass` | `string` | `"display2-bold"` | Font class |
| `fontColor` | `string` | — | Applied as `color-{fontColor}` class |

### fontClass as Sizing Prop

Many components use `fontClass` to control their size proportionally:

```tsx
<Icon name="search" fontClass="title2" />
<IconButton icon="menu" fontClass="body" />
<Card scaleFactor="body">...</Card>
```

## Quick Reference

### Font Class Scale

LiftKit font classes follow a hierarchy (largest to smallest):

| Class | Variant | Use For |
|---|---|---|
| `display1` | `display1-bold` | Hero text, page titles |
| `display2` | `display2-bold` | Section headings |
| `title1` | `title1-bold` | Subsection headings |
| `title2` | `title2-bold` | Card titles, labels |
| `body` | `body-bold`, `body-mono` | Default body text |
| `caption` | `caption-bold`, `caption-mono` | Small text, metadata |

### Responsive Breakpoints

| Viewport | Body Font Size |
|---|---|
| >= 1728px | 17.28px |
| 1440px - 1728px | 16px (standard) |
| <= 768px | 15px (mobile) |

All other sizes scale proportionally from the body size using golden ratio steps.

### Font Families

- **Inter** (300-700): Body and heading text
- **Roboto Mono** (300-700): Code and monospace content

## Common Mistakes

**Using raw px for font sizes** — Use `fontClass` props instead. Raw pixel values break the proportional system.

**Heading without fontClass** — Heading defaults to `display2-bold`. Set `fontClass` explicitly when you need a different size.

**Confusing fontClass and size** — Some components (Button) use `size` prop, others (Icon, Card) use `fontClass`. Check the component docs.
