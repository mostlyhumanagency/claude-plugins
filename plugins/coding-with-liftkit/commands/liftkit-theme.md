---
description: "Generate or customize a LiftKit theme with custom colors, dark mode, and live preview"
---

# liftkit-theme

Generate or customize a LiftKit theme by setting custom color tokens, configuring dark mode, and optionally adding a live ThemeController preview.

## Process

1. Ask the user what they want: new theme colors, dark mode setup, or ThemeController preview
2. If custom colors: ask for primary, secondary, and tertiary color hex values
3. Generate CSS custom property overrides for both light and dark mode tokens
4. Create or update the theme override CSS file with the generated tokens
5. Verify ThemeProvider is set up in `layout.tsx`
6. Optionally add `ThemeController` component for live preview
7. Show the user the generated theme and how to apply it
