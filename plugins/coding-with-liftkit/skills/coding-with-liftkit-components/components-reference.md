# LiftKit Components Reference

## Installation

```bash
npm run add all              # Everything
npm run add component-name   # Single (kebab-case)
npm run add base             # CSS + types only
```

## Interactive Components

### Button
| Prop | Type | Default | Description |
|---|---|---|---|
| `label` | `string` | — | Button text |
| `variant` | `"fill" \| "outline" \| "text"` | `"fill"` | Visual style |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Dimensions |
| `color` | `LkColorWithOnToken` | `"primary"` | Color token |
| `startIcon` | `IconName` | — | Left icon (Lucide) |
| `endIcon` | `IconName` | — | Right icon (Lucide) |
| `material` | `string` | — | Material style |
| `opticIconShift` | `boolean` | `true` | Optical icon correction |

### IconButton
| Prop | Type | Default | Description |
|---|---|---|---|
| `icon` | `IconName` | **required** | Icon to render |
| `variant` | `"fill" \| "outline" \| "text"` | — | Visual style |
| `size` | `"xs" \| "sm" \| "md" \| "lg" \| "xl"` | — | Button size |
| `color` | `LkColorWithOnToken` | — | Color token |
| `fontClass` | `LkFontClass` | — | Size via font class |

### Card
| Prop | Type | Default | Description |
|---|---|---|---|
| `variant` | `"fill" \| "outline" \| "transparent"` | `"fill"` | Card style |
| `material` | `"flat" \| "glass" \| "rubber"` | `"flat"` | Material effect |
| `scaleFactor` | `LkFontClass \| "none"` | `"body"` | Padding scale |
| `opticalCorrection` | `"top" \| "left" \| "right" \| "bottom" \| "x" \| "y" \| "all" \| "none"` | `"none"` | Trim padding |
| `bgColor` | `LkColorWithOnToken` | `"transparent"` | Background color |
| `isClickable` | `boolean` | `false` | Enable state layer |

### TextInput
| Prop | Type | Default | Description |
|---|---|---|---|
| `labelPosition` | `"default" \| "on-input"` | — | Label behavior |
| `placeholder` | `string` | — | Placeholder text |
| `helpText` | `string` | — | Helper text below |
| `startIcon` | `IconName` | — | Leading icon |
| `endIcon` | `IconName` | — | Trailing icon |
| `labelBackgroundColor` | `LkColor` | — | Floating label bg |

### Select
Compound component: `<Select>` > `<SelectTrigger>` + `<SelectMenu>` > `<SelectOption>`

| Prop (Select) | Type | Description |
|---|---|---|
| `value` | `string` | Selected value |
| `onChange` | `(val) => void` | Change handler |
| `name` | `string` | Form name |

### Dropdown
Compound component: `<Dropdown>` > `<DropdownTrigger>` + `<DropdownMenu>` > `<MenuItem>`

`<MenuItem>` accepts `startIcon` and `endIcon` config objects.

### Tabs
| Prop | Type | Default | Description |
|---|---|---|---|
| `tabLinks` | `string[]` | **required** | Tab labels |
| `activeTab` | `number` | — | Active tab index |
| `setActiveTab` | `(index) => void` | — | State setter |
| `scrollableContent` | `boolean` | — | Scrollable content |

### Snackbar
| Prop | Type | Default | Description |
|---|---|---|---|
| `message` | `string` | — | Toast text |
| `globalColor` | `LkColorWithOnToken` | — | Background + text |
| `cardProps` | `LkCardProps` | — | Underlying card config |

### Navbar
| Prop | Type | Description |
|---|---|---|
| `navButtons` | `ReactNode` | Navigation buttons |
| `navDropdowns` | `ReactNode` | Navigation dropdowns |
| `iconButtons` | `ReactNode` | Icon buttons (right side) |
| `ctaButtons` | `ReactNode` | CTA buttons (right side) |
| `material` | `LkMaterial` | Material style |

## Display Components

### Badge
| Prop | Type | Default | Description |
|---|---|---|---|
| `icon` | `IconName` | `"roller-coaster"` | Badge icon |
| `color` | `LkColorWithOnToken` | `"surface"` | Badge color |
| `scale` | `LkUnit` | `"md"` | Badge size |
| `iconStrokeWidth` | `number` | `1.5` | Stroke width |
| `scrim` | `boolean` | `false` | Overlay scrim |

### Sticker
| Prop | Type | Description |
|---|---|---|
| `bgColor` | `LkColor` | Background with on-token |
| `fontClass` | `LkFontClass` | Typography class |
| `content` | `string` | Text content (or use children) |

### Icon
| Prop | Type | Description |
|---|---|---|
| `name` | `IconName` | Lucide icon name |
| `color` | `LkColor \| "currentColor"` | Icon color |
| `fontClass` | `LkFontClass` | Size via font class |
| `opticShift` | `boolean` | Slight upward shift |
| `strokeWidth` | `number` | Stroke width |
| `display` | `"block" \| "inline-block" \| "inline"` | Display type |

### Image
| Prop | Type | Description |
|---|---|---|
| `aspect` | `"auto" \| "1/1" \| "16/9" \| "4/3" \| "3/2" \| ...` | Aspect ratio |
| `width` | `LkSizeUnit \| "auto"` | Image width |
| `height` | `LkSizeUnit \| "auto"` | Image height |
| `objectFit` | CSS `object-fit` values | Fit behavior |
| `borderRadius` | `LkSizeUnit \| "none"` | Border radius |

## Common Props (All Components)

Most components accept native HTML attributes. Components note whether `{children}` is supported in their docs.
