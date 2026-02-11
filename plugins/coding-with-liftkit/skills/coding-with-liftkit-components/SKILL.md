---
name: coding-with-liftkit-components
description: "Use when adding a Button, Card, Dropdown, Select, Tabs, TextInput, Navbar, Snackbar, Badge, IconButton, or any LiftKit component to a page. Also use for LiftKit component prop errors, component API questions, or choosing the right LiftKit component for a UI pattern."
---

# LiftKit Components

## Overview

LiftKit provides 24 pre-built React components integrated with the golden-ratio design system. Components use Material Design 3 tokens, support TypeScript, and include optical correction features for perceptually accurate spacing.

### Import Pattern

All components import from the local registry:

```tsx
import Button from "@/registry/nextjs/components/button";
import Card from "@/registry/nextjs/components/card";
import TextInput from "@/registry/nextjs/components/text-input";
import { Dropdown, DropdownTrigger, DropdownMenu, MenuItem } from "@/registry/nextjs/components/dropdown";
import { Select, SelectTrigger, SelectMenu, SelectOption } from "@/registry/nextjs/components/select";
import { Tabs, TabContent } from "@/registry/nextjs/components/tabs";
import NavBar from "@/registry/nextjs/components/navbar";
import Icon from "@/registry/nextjs/components/icon";
import IconButton from "@/registry/nextjs/components/icon-button";
```

## When to Use

- Building UI with LiftKit's component library
- Looking up component props or variants
- Debugging LiftKit component rendering issues
- Choosing between component variants (fill/outline/text)

## Core Patterns

### Button

```tsx
<Button
  label="Submit"
  variant="fill"       {/* "fill" | "outline" | "text" */}
  size="md"            {/* "sm" | "md" | "lg" */}
  color="primary"
  startIcon="send"
  endIcon="arrow-right"
/>
```

`opticIconShift` (default `true`) pulls icons up slightly for optical balance.

### Card

```tsx
<Card
  variant="fill"          {/* "fill" | "outline" | "transparent" */}
  material="glass"        {/* "flat" | "glass" | "rubber" */}
  scaleFactor="body"      {/* padding scales with font size */}
  opticalCorrection="y"   {/* "top"|"left"|"right"|"bottom"|"x"|"y"|"all"|"none" */}
  bgColor="surfacecontainerhigh"
  isClickable
  onClick={() => {}}
>
  <Heading tag="h3">Title</Heading>
  <Text>Content</Text>
</Card>
```

### Navbar

```tsx
<NavBar
  material="flat"
  navButtons={[
    <Button key="home" label="Home" variant="text" />,
    <Button key="about" label="About" variant="text" />,
  ]}
  iconButtons={[
    <IconButton key="search" icon="search" variant="text" color="surfacecontainer" />,
  ]}
  ctaButtons={[
    <Button key="signup" label="Sign Up" variant="fill" color="surfacecontainer" />,
  ]}
/>
```

### Dropdown & Select

```tsx
{/* Dropdown (action menu) */}
<Dropdown>
  <DropdownTrigger>
    <IconButton icon="ellipsis" />
  </DropdownTrigger>
  <DropdownMenu cardProps={{ material: "glass" }}>
    <MenuItem startIcon={iconConfig}>Action 1</MenuItem>
    <MenuItem>Action 2</MenuItem>
  </DropdownMenu>
</Dropdown>

{/* Select (form input) */}
<Select value={val} onChange={setVal}>
  <SelectTrigger><Button label="Choose" /></SelectTrigger>
  <SelectMenu cardProps={{ material: "glass" }}>
    <SelectOption value="a">Option A</SelectOption>
    <SelectOption value="b">Option B</SelectOption>
  </SelectMenu>
</Select>
```

### Tabs

```tsx
<Tabs tabLinks={["Tab 1", "Tab 2"]} activeTab={active} setActiveTab={setActive}>
  <TabContent>Content for Tab 1</TabContent>
  <TabContent>Content for Tab 2</TabContent>
</Tabs>
```

Children count **must equal** `tabLinks` length.

### TextInput

```tsx
<TextInput
  labelPosition="on-input"   {/* "default" | "on-input" (floating label) */}
  placeholder="email@example.com"
  helpText="Enter your email"
  startIcon="mail"
  endIcon="check"
/>
```

See [components-reference.md](./components-reference.md) for the full props table of all components.

## Common Mistakes

**Missing component install** — Each component must be installed: `npm run add button`. Dependencies auto-install.

**Wrong icon names** — LiftKit uses Lucide React icons. Check [lucide.dev](https://lucide.dev) for valid `IconName` values.

**Tabs children mismatch** — `tabLinks` array length must exactly match the number of children passed to `<Tabs>`.

**Card without scaleFactor** — Cards default `scaleFactor` to `"body"` which sets padding proportional to body font size. Set to `"none"` for manual padding control.
