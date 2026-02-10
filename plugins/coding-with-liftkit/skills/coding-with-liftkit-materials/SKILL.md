---
name: coding-with-liftkit-materials
description: This skill should be used when the user asks to "add glass effect", "use MaterialLayer", "use StateLayer", "apply material", "optical correction", "opticIconShift", "glass", "flat", "rubber" material, or debugs visual layering issues in LiftKit
---

# LiftKit Materials & Optical Corrections

## Overview

LiftKit provides three material presets — glass, flat, and rubber — that apply consistent visual treatments (backdrop blur, tint, lighting) across components. Optical corrections fix perceptual spacing imbalances caused by line-height, icon alignment, and padding calculations.

## When to Use

- Applying glass/blur effects to cards or containers
- Customizing material thickness and tint
- Using StateLayer for hover/active feedback
- Fixing visual padding asymmetry with `opticalCorrection`
- Debugging components that "look off" despite correct padding values

## Core Patterns

### Material Presets on Components

Most container components accept a `material` prop:

```tsx
<Card material="glass">Glassmorphism card</Card>
<Card material="flat">Default flat card</Card>
<Card material="rubber">Rubber/elevated card</Card>

<NavBar material="glass" />
```

### MaterialLayer (Advanced)

For custom material effects on any relatively-positioned parent:

```tsx
<div style={{ position: "relative" }}>
  <MaterialLayer
    type="glass"
    materialProps={{
      thickness: "normal",
      tint: "primary",
      tintOpacity: 0.4,
      light: true,
      lightExpression: "linear-gradient(90deg, rgba(255,255,255,1) 0%, rgba(255,255,255,0.18) 100%)"
    }}
  />
  <div style={{ position: "relative", zIndex: 1 }}>
    Content on top of material
  </div>
</div>
```

MaterialLayer creates three sub-layers: backdrop filter, tint overlay, and lighting gradient. The parent **must** be `position: relative`.

| Prop | Type | Description |
|---|---|---|
| `type` | `LkMaterialType` | `"glass"`, `"flat"`, `"rubber"` |
| `materialProps` | `LkMatProps` | Thickness, tint, opacity, light settings |
| `zIndex` | `number` | Layer stacking order |

### StateLayer (Interaction Feedback)

Provides hover/active/focus visual feedback:

```tsx
<div style={{ position: "relative" }}>
  <StateLayer bgColor="onprimary" />
  Hoverable content
</div>

{/* Force a specific state (e.g., for selected items) */}
<StateLayer bgColor="primary" forcedState="active" />
```

| Prop | Type | Description |
|---|---|---|
| `bgColor` | `LkColor \| "currentColor"` | Overlay color |
| `forcedState` | `"hover" \| "active" \| "focus"` | Static state |

Default opacity: hover 10%, active 20%. Uses `pointer-events: none` so it doesn't block clicks.

### Optical Corrections

**Card padding correction** — line-height adds invisible whitespace. Use `opticalCorrection` to trim it:

```tsx
<Card opticalCorrection="y">   {/* trim top + bottom */}
<Card opticalCorrection="all"> {/* trim all sides */}
<Card opticalCorrection="top"> {/* trim top only */}
```

**Button icon shift** — icons in buttons sit slightly too low by default. `opticIconShift` (default `true`) pulls them up:

```tsx
<Button label="Send" startIcon="send" />              {/* correction on */}
<Button label="Send" startIcon="send" opticIconShift={false} /> {/* correction off */}
```

**Icon optical shift** — standalone icons can also be shifted:

```tsx
<Icon name="check" opticShift />
```

## Quick Reference

| Material | Effect | Best For |
|---|---|---|
| `"flat"` | No backdrop effect, solid | Default cards, containers |
| `"glass"` | Backdrop blur + tint + light | Overlays, modals, elevated UI |
| `"rubber"` | Elevated, tactile feel | Buttons, interactive elements |

## Common Mistakes

**Missing position:relative** — MaterialLayer and StateLayer are `position: absolute`. Their parent **must** be `position: relative` or they won't render correctly.

**Stacking MaterialLayer content** — Content placed after MaterialLayer needs `position: relative` and a higher `z-index` to appear above the material.

**Disabling opticIconShift** — It's on by default for a reason. Only disable it if you're doing custom icon positioning.
