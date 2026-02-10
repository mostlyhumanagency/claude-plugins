---
name: coding-with-liftkit-layout
description: This skill should be used when the user asks to "build a page layout", "use Section", "use Container", "use Grid", "use Row", "use Column", "responsive layout", or troubleshoots page structure issues with LiftKit
---

# LiftKit Layout

## Overview

LiftKit structures pages using a Section > Container > content hierarchy. Sections control padding, Containers control max-width, and Grid/Row/Column handle content arrangement. All spacing derives from the golden ratio.

## When to Use

- Building page structure with sections and containers
- Creating grid or flex layouts
- Troubleshooting content width or padding issues
- Making layouts responsive

**When NOT to use:** For individual component styling — use coding-with-liftkit-components instead.

## Core Patterns

### Page Structure

```tsx
<Section py="lg">
  <Container maxWidth="md">
    <Grid columns={2} gap="md">
      <Card>...</Card>
      <Card>...</Card>
    </Grid>
  </Container>
</Section>
```

**Rule:** Sections own padding. Containers own max-width. Never nest Containers.

### Section

Establishes vertical rhythm with padding control:

```tsx
<Section padding="lg">        {/* uniform */}
<Section py="xl" px="md">     {/* axis shortcuts */}
<Section pt="lg" pb="sm">     {/* individual sides */}
<Section padding="none">       {/* no padding */}
```

Props: `padding`, `pt`, `pb`, `pl`, `pr`, `px`, `py` — all accept `SpacingSize`.

### Container

Centers content with max-width constraint:

```tsx
<Container maxWidth="sm">  {/* narrow */}
<Container maxWidth="md">  {/* default */}
<Container maxWidth="lg">  {/* wide */}
```

### Grid

CSS Grid with convenience props:

```tsx
<Grid columns={3} gap="md">
  <div>Col 1</div>
  <div>Col 2</div>
  <div>Col 3</div>
</Grid>

{/* Auto-responsive: adapts columns to screen size */}
<Grid columns={4} gap="lg" autoResponsive>
  {items.map(item => <Card key={item.id}>...</Card>)}
</Grid>
```

### Responsive Behavior

Grid's `autoResponsive` adapts columns based on viewport:

| Viewport | Behavior |
|---|---|
| Desktop (>= 992px) | Full column count |
| Tablet (768-991px) | Columns halved (4 -> 2, 3 -> 2) |
| Mobile (< 768px) | Single column stack |

Without `autoResponsive`, Grid maintains its column count at all sizes. Use responsive utility classes for manual control:

```tsx
<Grid columns={3} gap="md" autoResponsive>
  {/* Automatically adapts from 3 -> 2 -> 1 columns */}
</Grid>
```

Nesting rules:
- Sections can contain other Sections (for nested padding)
- Grid can contain Cards, Rows, Columns, or any content
- Never nest Container inside Container
- Row/Column can nest inside Grid cells

### Row and Column (Flexbox)

```tsx
<Row gap="md" justifyContent="space-between" alignItems="center">
  <Button label="Left" />
  <Button label="Right" />
</Row>

<Column gap="lg" alignItems="center">
  <Heading tag="h1">Title</Heading>
  <Text>Description</Text>
</Column>
```

## Quick Reference

| Component | Purpose | Key Props |
|---|---|---|
| `Section` | Page section with padding | `padding`, `py`, `px`, `pt`, `pb`, `pl`, `pr` |
| `Container` | Max-width wrapper, auto-centered | `maxWidth` (`"sm"`, `"md"`, `"lg"`) |
| `Grid` | CSS Grid layout | `columns`, `gap`, `autoResponsive` |
| `Row` | Horizontal flexbox | `gap`, `justifyContent`, `alignItems`, `wrapChildren` |
| `Column` | Vertical flexbox | `gap`, `justifyContent`, `alignItems`, `wrapChildren` |

### Flex Alignment Values

- `alignItems`: `"start"` | `"center"` | `"end"` | `"stretch"`
- `justifyContent`: `"start"` | `"center"` | `"end"` | `"space-between"` | `"space-around"`
- `defaultChildBehavior`: `"auto-grow"` | `"auto-shrink"` | `"ignoreFlexRules"` | `"ignoreIntrinsicSize"`

### Gap/Spacing Sizes

LiftKit uses `LkSizeUnit` values: `"3xs"`, `"2xs"`, `"xs"`, `"sm"`, `"md"`, `"lg"`, `"xl"`, `"2xl"`, `"3xl"`, `"4xl"` — all derived from the golden ratio.

## Common Mistakes

**Nesting Containers** — Containers should be direct children of Sections, never nested inside other Containers.

**Using Section for content width** — Sections only handle padding. Use Container for max-width constraints.

**Missing autoResponsive** — Grid columns don't adapt to mobile by default. Add `autoResponsive` for responsive behavior.
