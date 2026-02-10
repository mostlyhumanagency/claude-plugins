---
name: coding-with-liftkit-forms
description: This skill should be used when the user asks to "build a form", "create a login form", "use TextInput", "form validation", "form layout with LiftKit", "sign up form", "settings form", or needs guidance on building forms with LiftKit components
---

# LiftKit Forms

## Overview

LiftKit provides TextInput, Select, and Button components for building forms. Combined with Card wrappers, Column/Row layouts, and the golden-ratio spacing system, forms maintain visual consistency with the rest of your LiftKit UI.

## When to Use

- Building any form (login, signup, contact, settings)
- Using TextInput with labels, validation, and helper text
- Creating Select/Dropdown form fields
- Laying out form elements with proper spacing
- Adding client-side validation patterns

**When NOT to use:** For non-form interactive elements — use coding-with-liftkit-components instead.

## Core Patterns

### Basic Form Layout

Wrap forms in a Card for visual containment, use Column for vertical field stacking:

```tsx
import Card from "@/registry/nextjs/components/card";
import Column from "@/registry/nextjs/components/column";
import TextInput from "@/registry/nextjs/components/text-input";
import Button from "@/registry/nextjs/components/button";

function ContactForm() {
  return (
    <Card material="glass" opticalCorrection="y">
      <Column gap="md">
        <TextInput
          labelPosition="default"
          placeholder="Your name"
          helpText="Full name as it appears on your ID"
        />
        <TextInput
          labelPosition="default"
          placeholder="email@example.com"
          startIcon="mail"
        />
        <TextInput
          labelPosition="default"
          placeholder="Your message"
        />
        <Button label="Send Message" variant="fill" color="primary" />
      </Column>
    </Card>
  );
}
```

### TextInput Props

TextInput supports labels, icons, help text, and error states:

```tsx
{/* Default label position (above the field) */}
<TextInput
  labelPosition="default"
  placeholder="Enter your email"
  helpText="We'll never share your email"
  startIcon="mail"
/>

{/* Floating label (on-input) for compact forms */}
<TextInput
  labelPosition="on-input"
  placeholder="Password"
  startIcon="lock"
  endIcon="eye"
/>

{/* Error state with help text */}
<TextInput
  labelPosition="default"
  placeholder="Username"
  helpText="Username is already taken"
  startIcon="user"
/>
```

**Key props:**
- `labelPosition` — `"default"` (label above) or `"on-input"` (floating label)
- `placeholder` — Placeholder text inside the field
- `helpText` — Helper or error message below the field
- `startIcon` / `endIcon` — Lucide icon names for leading/trailing icons
- `value` / `onChange` — Controlled input binding

### Select in Forms

Use Select as a form field for predefined choices:

```tsx
import { Select, SelectTrigger, SelectMenu, SelectOption } from "@/registry/nextjs/components/select";
import Button from "@/registry/nextjs/components/button";

function RoleSelect({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <Select value={value} onChange={onChange}>
      <SelectTrigger>
        <Button label={value || "Select a role"} variant="outline" endIcon="chevron-down" />
      </SelectTrigger>
      <SelectMenu cardProps={{ material: "glass" }}>
        <SelectOption value="admin">Admin</SelectOption>
        <SelectOption value="editor">Editor</SelectOption>
        <SelectOption value="viewer">Viewer</SelectOption>
      </SelectMenu>
    </Select>
  );
}
```

### Form Validation Pattern

Use React state to track errors and display validation feedback:

```tsx
"use client";

import { useState } from "react";
import Card from "@/registry/nextjs/components/card";
import Column from "@/registry/nextjs/components/column";
import Row from "@/registry/nextjs/components/row";
import TextInput from "@/registry/nextjs/components/text-input";
import Button from "@/registry/nextjs/components/button";

function ValidatedForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate() {
    const newErrors: Record<string, string> = {};
    if (!email.includes("@")) newErrors.email = "Please enter a valid email";
    if (password.length < 8) newErrors.password = "Password must be at least 8 characters";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  function handleSubmit() {
    if (validate()) {
      // Submit form data
    }
  }

  return (
    <Card material="glass" opticalCorrection="y">
      <Column gap="md">
        <TextInput
          labelPosition="default"
          placeholder="email@example.com"
          startIcon="mail"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          helpText={errors.email}
        />
        <TextInput
          labelPosition="default"
          placeholder="Password"
          startIcon="lock"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          helpText={errors.password}
        />
        <Button label="Submit" variant="fill" color="primary" onClick={handleSubmit} />
      </Column>
    </Card>
  );
}
```

### Login Form Example

A complete login form with email, password, forgot-password link, and submit:

```tsx
"use client";

import { useState } from "react";
import Card from "@/registry/nextjs/components/card";
import Column from "@/registry/nextjs/components/column";
import Row from "@/registry/nextjs/components/row";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import TextInput from "@/registry/nextjs/components/text-input";
import Button from "@/registry/nextjs/components/button";

function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <Card material="glass" opticalCorrection="y">
      <Column gap="lg">
        <Column gap="xs">
          <Heading tag="h2">Welcome back</Heading>
          <Text>Sign in to your account</Text>
        </Column>
        <Column gap="md">
          <TextInput
            labelPosition="on-input"
            placeholder="Email"
            startIcon="mail"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextInput
            labelPosition="on-input"
            placeholder="Password"
            startIcon="lock"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </Column>
        <Row justifyContent="space-between" alignItems="center">
          <Button label="Forgot password?" variant="text" />
          <Button label="Sign In" variant="fill" color="primary" />
        </Row>
      </Column>
    </Card>
  );
}
```

### Signup Form Example

A complete registration form with name, email, password, and confirmation:

```tsx
"use client";

import { useState } from "react";
import Card from "@/registry/nextjs/components/card";
import Column from "@/registry/nextjs/components/column";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import TextInput from "@/registry/nextjs/components/text-input";
import Button from "@/registry/nextjs/components/button";

function SignupForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");

  return (
    <Card material="glass" opticalCorrection="y">
      <Column gap="lg">
        <Column gap="xs">
          <Heading tag="h2">Create an account</Heading>
          <Text>Get started with your free account</Text>
        </Column>
        <Column gap="md">
          <TextInput
            labelPosition="on-input"
            placeholder="Full name"
            startIcon="user"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <TextInput
            labelPosition="on-input"
            placeholder="Email"
            startIcon="mail"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextInput
            labelPosition="on-input"
            placeholder="Password"
            startIcon="lock"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <TextInput
            labelPosition="on-input"
            placeholder="Confirm password"
            startIcon="lock"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
          />
        </Column>
        <Button label="Create Account" variant="fill" color="primary" />
      </Column>
    </Card>
  );
}
```

### Settings Form Example

A settings form with grouped sections, each with its own heading:

```tsx
"use client";

import { useState } from "react";
import Card from "@/registry/nextjs/components/card";
import Column from "@/registry/nextjs/components/column";
import Heading from "@/registry/nextjs/components/heading";
import TextInput from "@/registry/nextjs/components/text-input";
import { Select, SelectTrigger, SelectMenu, SelectOption } from "@/registry/nextjs/components/select";
import Button from "@/registry/nextjs/components/button";

function SettingsForm() {
  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [timezone, setTimezone] = useState("utc");

  return (
    <Card material="glass" opticalCorrection="y">
      <Column gap="xl">
        {/* Profile Section */}
        <Column gap="md">
          <Heading tag="h3">Profile</Heading>
          <TextInput
            labelPosition="default"
            placeholder="Display name"
            startIcon="user"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
          />
          <TextInput
            labelPosition="default"
            placeholder="Bio"
            value={bio}
            onChange={(e) => setBio(e.target.value)}
          />
        </Column>

        {/* Preferences Section */}
        <Column gap="md">
          <Heading tag="h3">Preferences</Heading>
          <Select value={timezone} onChange={setTimezone}>
            <SelectTrigger>
              <Button label={timezone} variant="outline" endIcon="chevron-down" />
            </SelectTrigger>
            <SelectMenu cardProps={{ material: "glass" }}>
              <SelectOption value="utc">UTC</SelectOption>
              <SelectOption value="est">Eastern Time</SelectOption>
              <SelectOption value="pst">Pacific Time</SelectOption>
            </SelectMenu>
          </Select>
        </Column>

        <Button label="Save Changes" variant="fill" color="primary" />
      </Column>
    </Card>
  );
}
```

## Quick Reference

| Component | Role | Key Props |
|---|---|---|
| TextInput | Text input field | labelPosition, placeholder, helpText, startIcon, endIcon |
| Select | Dropdown selection | value, onChange, children (SelectOption) |
| Button | Submit/action | label, variant="fill", type="submit" |
| Card | Form container | material="glass", opticalCorrection="y" |
| Column | Vertical layout | gap="md" or gap="lg" |

## Common Mistakes

**Missing form wrapper** — Wrap forms in a Card for visual consistency and proper spacing.

**No error states** — Use TextInput's helpText prop with error styling for validation feedback.

**Inconsistent spacing** — Use Column with gap="md" for consistent field spacing instead of manual margins.

**Missing labels** — Always provide labels via labelPosition. Use "on-input" for compact forms, "default" for spacious layouts.
