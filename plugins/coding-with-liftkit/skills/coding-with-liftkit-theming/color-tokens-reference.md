# LiftKit Color Tokens Reference

## CSS Variable Naming

Pattern: `--light__[token]_clv` / `--dark__[token]_clv`

## Primary Color Families

| Token | On-Token | Container | On-Container |
|---|---|---|---|
| `primary` | `onprimary` | `primarycontainer` | `onprimarycontainer` |
| `secondary` | `onsecondary` | `secondarycontainer` | `onsecondarycontainer` |
| `tertiary` | `ontertiary` | `tertiarycontainer` | `ontertiarycontainer` |

## Surface Tokens

| Token | Purpose |
|---|---|
| `surface` | Default background |
| `surfacecontainerlowest` | Deepest background layer |
| `surfacecontainerlow` | Below-default background |
| `surfacecontainer` | Standard container background |
| `surfacecontainerhigh` | Elevated container |
| `surfacecontainerhighest` | Most elevated container |
| `surfacebright` | Bright surface variant |
| `surfacedim` | Dimmed surface variant |
| `onsurface` | Text/icons on surface |
| `onsurfacevariant` | Secondary text on surface |

## Semantic Colors

| Token | On-Token | Container | On-Container |
|---|---|---|---|
| `error` | `onerror` | `errorcontainer` | `onerrorcontainer` |
| `warning` | `onwarning` | `warningcontainer` | `onwarningcontainer` |
| `success` | `onsuccess` | `successcontainer` | `onsuccesscontainer` |
| `info` | `oninfo` | `infocontainer` | `oninfocontainer` |

## Inverse Tokens

| Token | Purpose |
|---|---|
| `inverseprimary` | Primary for inverse surfaces |
| `inversesurface` | Inverted background |
| `inversesurfacevariant` | Inverted surface variant |

## Utility Tokens

| Token | Purpose |
|---|---|
| `background` | Page background |
| `onbackground` | Text on page background |
| `outline` | Default borders |
| `outlinevariant` | Subtle borders |
| `scrim` | Semi-transparent overlay |
| `shadow` | Drop shadow color |

## Usage in Components

```tsx
// As a prop (most common)
<Button color="primary" />
<Card bgColor="surfacecontainerhigh" />
<Icon color="onprimary" />

// As CSS variable
.custom-element {
  background-color: var(--light__primary_clv);
  color: var(--light__onprimary_clv);
}
```

## Dark Mode Mapping

All `--light__*_clv` variables automatically remap to `--dark__*_clv` equivalents when:
- System prefers dark: `@media (prefers-color-scheme: dark)`
- Manual override: `data-color-mode="dark"` on `<html>`
- Force dark: `data-force-dark-mode="true"` on any element
