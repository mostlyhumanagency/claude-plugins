---
name: coding-with-liftkit-recipes
description: "Use when building a complete page or UI pattern with LiftKit — landing pages, dashboards, auth pages, settings screens, hero sections, card grids, sidebar layouts, or any full-page recipe that combines multiple LiftKit components together."
---

# LiftKit UI Recipes

## Overview

Common UI patterns built entirely with LiftKit components. Each recipe is a complete, copy-paste-ready pattern using Section/Container/Grid layout, material effects, and proper token usage.

## When to Use

- Building a complete page from a pattern
- Looking for inspiration on how to compose LiftKit components
- Creating standard UI patterns (auth, dashboard, landing)
- Combining multiple LiftKit features into a cohesive layout

## Recipes

### Hero Section

A full-width hero with headline, subtitle, and call-to-action buttons:

```tsx
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Column from "@/registry/nextjs/components/column";
import Row from "@/registry/nextjs/components/row";
import Card from "@/registry/nextjs/components/card";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import Button from "@/registry/nextjs/components/button";

function HeroSection() {
  return (
    <Section py="3xl">
      <Container maxWidth="md">
        <Column gap="lg" alignItems="center">
          <Card material="glass" opticalCorrection="y">
            <Column gap="lg" alignItems="center">
              <Heading tag="h1" className="display1-bold">
                Build beautiful interfaces
              </Heading>
              <Text className="body">
                A golden-ratio design system for perceptually perfect layouts.
                Ship faster with components that look right by default.
              </Text>
              <Row gap="md">
                <Button label="Get Started" variant="fill" color="primary" />
                <Button label="Learn More" variant="outline" />
              </Row>
            </Column>
          </Card>
        </Column>
      </Container>
    </Section>
  );
}
```

### Auth Page (Login/Signup)

A full-page centered auth layout with a glass card form:

```tsx
"use client";

import { useState } from "react";
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Column from "@/registry/nextjs/components/column";
import Card from "@/registry/nextjs/components/card";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import TextInput from "@/registry/nextjs/components/text-input";
import Button from "@/registry/nextjs/components/button";

function AuthPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <Section py="3xl" style={{ minHeight: "100vh", display: "flex", alignItems: "center" }}>
      <Container maxWidth="sm">
        <Card material="glass" opticalCorrection="y">
          <Column gap="lg">
            <Column gap="xs" alignItems="center">
              <Heading tag="h2">Sign in</Heading>
              <Text>Welcome back. Enter your credentials to continue.</Text>
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
            <Button label="Sign In" variant="fill" color="primary" />
            <Text className="body" style={{ textAlign: "center" }}>
              Don't have an account? <a href="/signup">Sign up</a>
            </Text>
          </Column>
        </Card>
      </Container>
    </Section>
  );
}
```

### Dashboard Layout

A dashboard with navigation bar, stat cards in a grid, and tabbed content:

```tsx
"use client";

import { useState } from "react";
import NavBar from "@/registry/nextjs/components/navbar";
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Column from "@/registry/nextjs/components/column";
import Grid from "@/registry/nextjs/components/grid";
import Card from "@/registry/nextjs/components/card";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import Button from "@/registry/nextjs/components/button";
import IconButton from "@/registry/nextjs/components/icon-button";
import { Tabs, TabContent } from "@/registry/nextjs/components/tabs";

function Dashboard() {
  const [activeTab, setActiveTab] = useState(0);

  const stats = [
    { label: "Total Users", value: "12,340", color: "primarycontainer" },
    { label: "Revenue", value: "$45.2K", color: "secondarycontainer" },
    { label: "Active Sessions", value: "1,892", color: "tertiarycontainer" },
    { label: "Conversion", value: "3.2%", color: "surfacecontainerhigh" },
  ];

  return (
    <>
      <NavBar
        material="flat"
        navButtons={[
          <Button key="dashboard" label="Dashboard" variant="text" />,
          <Button key="analytics" label="Analytics" variant="text" />,
          <Button key="settings" label="Settings" variant="text" />,
        ]}
        iconButtons={[
          <IconButton key="notifications" icon="bell" variant="text" />,
        ]}
        ctaButtons={[
          <Button key="new" label="New Report" variant="fill" startIcon="plus" />,
        ]}
      />

      <Section py="lg">
        <Container maxWidth="lg">
          <Column gap="lg">
            <Grid columns={4} gap="md" autoResponsive>
              {stats.map((stat) => (
                <Card key={stat.label} material="flat" bgColor={stat.color} opticalCorrection="y">
                  <Column gap="xs">
                    <Heading tag="h2">{stat.value}</Heading>
                    <Text>{stat.label}</Text>
                  </Column>
                </Card>
              ))}
            </Grid>

            <Tabs
              tabLinks={["Overview", "Analytics", "Settings"]}
              activeTab={activeTab}
              setActiveTab={setActiveTab}
            >
              <TabContent>
                <Text>Overview content goes here.</Text>
              </TabContent>
              <TabContent>
                <Text>Analytics charts and data go here.</Text>
              </TabContent>
              <TabContent>
                <Text>Dashboard settings and configuration go here.</Text>
              </TabContent>
            </Tabs>
          </Column>
        </Container>
      </Section>
    </>
  );
}
```

### Settings Page

A settings page with grouped form sections inside a card:

```tsx
"use client";

import { useState } from "react";
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Column from "@/registry/nextjs/components/column";
import Card from "@/registry/nextjs/components/card";
import Heading from "@/registry/nextjs/components/heading";
import TextInput from "@/registry/nextjs/components/text-input";
import { Select, SelectTrigger, SelectMenu, SelectOption } from "@/registry/nextjs/components/select";
import Button from "@/registry/nextjs/components/button";

function SettingsPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [language, setLanguage] = useState("en");

  return (
    <Section py="lg">
      <Container maxWidth="md">
        <Column gap="lg">
          <Heading tag="h1">Settings</Heading>

          <Card material="glass" opticalCorrection="y">
            <Column gap="xl">
              {/* Account Section */}
              <Column gap="md">
                <Heading tag="h3">Account</Heading>
                <TextInput
                  labelPosition="default"
                  placeholder="Display name"
                  startIcon="user"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
                <TextInput
                  labelPosition="default"
                  placeholder="Email address"
                  startIcon="mail"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </Column>

              {/* Preferences Section */}
              <Column gap="md">
                <Heading tag="h3">Preferences</Heading>
                <Select value={language} onChange={setLanguage}>
                  <SelectTrigger>
                    <Button label={language === "en" ? "English" : language} variant="outline" endIcon="chevron-down" />
                  </SelectTrigger>
                  <SelectMenu cardProps={{ material: "glass" }}>
                    <SelectOption value="en">English</SelectOption>
                    <SelectOption value="es">Spanish</SelectOption>
                    <SelectOption value="fr">French</SelectOption>
                  </SelectMenu>
                </Select>
              </Column>

              {/* Notifications Section */}
              <Column gap="md">
                <Heading tag="h3">Notifications</Heading>
                <TextInput
                  labelPosition="default"
                  placeholder="Notification email"
                  startIcon="bell"
                  helpText="Where to send alert emails"
                />
              </Column>

              <Button label="Save Changes" variant="fill" color="primary" />
            </Column>
          </Card>
        </Column>
      </Container>
    </Section>
  );
}
```

### Card Grid (Feature Showcase)

A responsive grid of feature cards with icons:

```tsx
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Column from "@/registry/nextjs/components/column";
import Grid from "@/registry/nextjs/components/grid";
import Card from "@/registry/nextjs/components/card";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";
import Icon from "@/registry/nextjs/components/icon";

const features = [
  { icon: "zap", title: "Fast", description: "Optimized for performance with minimal bundle size." },
  { icon: "shield", title: "Secure", description: "Built-in security best practices and XSS protection." },
  { icon: "palette", title: "Themeable", description: "Full dark mode support with customizable color tokens." },
  { icon: "smartphone", title: "Responsive", description: "Mobile-first design with autoResponsive grid layouts." },
  { icon: "code", title: "TypeScript", description: "Full type safety with exported prop interfaces." },
  { icon: "ratio", title: "Golden Ratio", description: "All proportions derived from a single harmonic scale." },
];

function FeatureGrid() {
  return (
    <Section py="xl">
      <Container maxWidth="lg">
        <Grid columns={3} gap="lg" autoResponsive>
          {features.map((feature) => (
            <Card key={feature.title} material="flat" opticalCorrection="y">
              <Column gap="md">
                <Icon name={feature.icon} size={32} />
                <Heading tag="h3">{feature.title}</Heading>
                <Text>{feature.description}</Text>
              </Column>
            </Card>
          ))}
        </Grid>
      </Container>
    </Section>
  );
}
```

### Sidebar + Content Layout

A two-column layout with a fixed sidebar navigation and main content area:

```tsx
"use client";

import { useState } from "react";
import Row from "@/registry/nextjs/components/row";
import Column from "@/registry/nextjs/components/column";
import Section from "@/registry/nextjs/components/section";
import Container from "@/registry/nextjs/components/container";
import Button from "@/registry/nextjs/components/button";
import Heading from "@/registry/nextjs/components/heading";
import Text from "@/registry/nextjs/components/text";

const navItems = [
  { label: "Dashboard", icon: "layout-dashboard" },
  { label: "Projects", icon: "folder" },
  { label: "Team", icon: "users" },
  { label: "Settings", icon: "settings" },
];

function SidebarLayout() {
  const [activePage, setActivePage] = useState("Dashboard");

  return (
    <Row style={{ minHeight: "100vh" }}>
      {/* Sidebar */}
      <Column
        gap="xs"
        style={{ width: 240, borderRight: "1px solid var(--light__outline_clv)", padding: "var(--spacing-lg)" }}
      >
        <Heading tag="h3" style={{ marginBottom: "var(--spacing-md)" }}>App Name</Heading>
        {navItems.map((item) => (
          <Button
            key={item.label}
            label={item.label}
            variant="text"
            startIcon={item.icon}
            onClick={() => setActivePage(item.label)}
            color={activePage === item.label ? "primary" : undefined}
          />
        ))}
      </Column>

      {/* Main Content */}
      <Column style={{ flex: 1 }}>
        <Section py="lg">
          <Container maxWidth="md">
            <Column gap="md">
              <Heading tag="h1">{activePage}</Heading>
              <Text>Content for the {activePage} page goes here.</Text>
            </Column>
          </Container>
        </Section>
      </Column>
    </Row>
  );
}
```

For responsive behavior, hide the sidebar on mobile and replace it with a NavBar at the top using a media query or responsive utility class.

## Quick Reference

| Recipe | Key Components | Layout Pattern |
|---|---|---|
| Hero | Heading, Text, Button, Card | Section > Container > Column (centered) |
| Auth | Card, TextInput, Button | Section (full height) > Container sm > Card |
| Dashboard | NavBar, Grid, Card, Tabs | NavBar + Section > Container > Grid + Tabs |
| Settings | Card, TextInput, Heading, Button | Section > Container > Card > Column |
| Card Grid | Grid, Card, Icon, Heading, Text | Section > Container > Grid autoResponsive |
| Sidebar | Row, Column, Button, Section | Row > Column (fixed) + Column (grow) |

## Common Mistakes

**Not using Section/Container** — Always wrap page content in Section > Container for consistent padding and max-width.

**Skipping autoResponsive** — Grid layouts without autoResponsive break on mobile. Always add it for responsive card grids.

**Mixing raw HTML with LiftKit** — Use LiftKit's Button, Text, Heading instead of raw button, p, h1 for consistent styling.
