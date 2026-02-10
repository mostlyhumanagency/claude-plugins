# LiftKit Utility Classes — Full Category Reference

## Prerequisites

LiftKit must be initialized and Base must be installed:
```bash
npx liftkit init
npm run add base
```

## All Categories

### Layout & Display
| Category | Purpose |
|---|---|
| `display` | Element display type (block, flex, grid, inline, none) |
| `flexboxes` | Flexbox container properties |
| `align-items` | Flex/grid item alignment (cross axis) |
| `align-self` | Individual element alignment override |
| `justify-content` | Flex content distribution (main axis) |
| `justify-items` | Grid item justification |
| `position` | Positioning (absolute, relative, fixed, sticky) |
| `z-index` | Stacking order |
| `overflow` | Content overflow behavior |
| `column-span` | Grid column spanning |

### Spacing
| Category | Purpose |
|---|---|
| `padding` | Inner spacing (`p-`, `px-`, `py-`, `pt-`, `pb-`, `pl-`, `pr-`) |
| `margins` | Outer spacing (`m-`, `mx-`, `my-`, `mt-`, `mb-`, `ml-`, `mr-`) |
| `gaps` | Flex/grid gap between items |

### Sizing
| Category | Purpose |
|---|---|
| `width` | Element width values |
| `height` | Element height values |
| `aspect-ratios` | Element aspect ratio constraints |
| `scale` | Element scaling transformations |

### Visual
| Category | Purpose |
|---|---|
| `background-color` | Background color via token (`bg-{token}`) |
| `text-color` | Text color via token (`color-{token}`) |
| `border-color` | Border color via token |
| `borders` | Border sizing and application |
| `border-style` | Border line style (solid, dashed, etc.) |
| `border-radius` | Corner rounding (`border-radius-{size}`) |
| `shadows` | Drop shadow elevation (`shadow1` - `shadow5`) |
| `opacity` | Transparency levels |
| `material` | Material Design system classes |
| `scrim` | Semi-transparent overlay layers |

### Typography
| Category | Purpose |
|---|---|
| `typography` | Font size, weight, and text styling classes |
| `text-alignment` | Text justification and alignment |
| `text-columns` | Multi-column text layout |
| `whitespace` | Whitespace handling behavior |
| `code` | Code block and inline code styling |

### Interaction
| Category | Purpose |
|---|---|
| `cursor` | Mouse cursor appearance |
| `pointer-events` | Mouse event interaction control |

### Responsive
| Category | Purpose |
|---|---|
| `breaks` | Responsive breakpoint handling |

**Breakpoint classes:**
- `.show__desktopOnly` — visible >= 992px
- `.show__tabletDown` — visible <= 991px
- `.show__landscapeDown` — visible <= 760px
- `.show__portraitOnly` — visible <= 479px

### System
| Category | Purpose |
|---|---|
| `liftkit-core` | Core framework classes |
| `liftkitvars` | CSS custom property variables |
| `inputs` | Form input base styling |

## Color Tokens Available for Utility Classes

All tokens from the LiftKit color system work in `bg-{token}`, `color-{token}`, and `border-color-{token}`:

`primary`, `onprimary`, `primarycontainer`, `onprimarycontainer`,
`secondary`, `onsecondary`, `secondarycontainer`, `onsecondarycontainer`,
`tertiary`, `ontertiary`, `tertiarycontainer`, `ontertiarycontainer`,
`surface`, `onsurface`, `onsurfacevariant`,
`surfacecontainer`, `surfacecontainerhigh`, `surfacecontainerhighest`,
`surfacecontainerlow`, `surfacecontainerlowest`,
`surfacebright`, `surfacedim`,
`background`, `onbackground`,
`error`, `onerror`, `errorcontainer`, `onerrorcontainer`,
`warning`, `onwarning`, `success`, `onsuccess`, `info`, `oninfo`,
`outline`, `outlinevariant`,
`inverseprimary`, `inversesurface`
