---
name: coding-with-liftkit
description: This skill should be used when the user asks to "use LiftKit", "build with LiftKit", "Chainlift UI", or mentions LiftKit without specifying a subskill. Routes to the most specific LiftKit skill.
---

# LiftKit

## Overview

LiftKit is an open-source UI framework by Chainlift that derives all proportions from the golden ratio — margins, font sizes, border radius, and spacing all scale from a single global factor with subpixel accuracy. It builds on Material Design 3 tokens, runs on Next.js, and emphasizes optical correction for perceptually accurate layouts.

## Subskills

| Skill | Use When |
|---|---|
| installing-liftkit | Setting up LiftKit in new or existing Next.js projects, running `npx liftkit init`, adding components |
| coding-with-liftkit-theming | Working with Theme/ThemeController, color tokens, dark mode, CSS custom properties (`--light__*_clv`) |
| coding-with-liftkit-layout | Building page structure with Section, Container, Grid, Row, Column |
| coding-with-liftkit-components | Using interactive components — Button, Card, Dropdown, Select, Tabs, TextInput, Navbar, Snackbar, Badge, Sticker |
| coding-with-liftkit-typography | Working with Text, Heading, font classes, golden-ratio type scaling |
| coding-with-liftkit-materials | Applying material effects (glass, flat, rubber), MaterialLayer, StateLayer, optical corrections |
| coding-with-liftkit-utility-classes | Using LiftKit utility classes for spacing, colors, borders, shadows, responsive breakpoints |
| coding-with-liftkit-forms | Building forms with TextInput, Select, validation patterns, login/signup/settings forms |
| coding-with-liftkit-recipes | Complete UI patterns — hero sections, auth pages, dashboards, settings pages, card grids, sidebar layouts |

If unsure, start with **installing-liftkit** for setup or **coding-with-liftkit-components** for building UI.
