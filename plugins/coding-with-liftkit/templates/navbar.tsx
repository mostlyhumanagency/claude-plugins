// LiftKit Navbar Component Template
// Copy this to components/navbar.tsx for a responsive navigation bar.
//
// What this demonstrates:
// - NavBar with glass material for frosted-glass look
// - Navigation buttons using text variant (clean, no background)
// - Icon buttons for utility actions (search, notifications)
// - CTA button with filled variant for the primary action
// - Theme toggle using IconButton with sun/moon icons
//
// Why "use client"?
// The theme toggle uses useState to track light/dark mode, which requires
// a Client Component. If you remove the toggle, this can be a Server Component.

"use client";

import { useState } from "react";
import { Button } from "@/registry/nextjs/components/button";
import { Heading } from "@/registry/nextjs/components/heading";
import { IconButton } from "@/registry/nextjs/components/icon-button";
import { NavBar } from "@/registry/nextjs/components/nav-bar";
import { Row } from "@/registry/nextjs/components/row";

// Navigation links — extract to a config file if used across multiple navbars
const navLinks = [
  { label: "Home", href: "/" },
  { label: "Features", href: "/features" },
  { label: "Pricing", href: "/pricing" },
  { label: "About", href: "/about" },
];

export function AppNavbar() {
  // Theme toggle state. In production, sync this with ThemeProvider
  // by using the theme context or a shared state management solution.
  const [isDark, setIsDark] = useState(false);

  const toggleTheme = () => {
    setIsDark((prev) => !prev);
    // To actually switch the theme, toggle the data attribute on <html>:
    // document.documentElement.setAttribute("data-theme", isDark ? "light" : "dark");
    // Or better: use LiftKit's ThemeProvider context if available.
  };

  return (
    // material="glass": frosted-glass navbar that looks great over content.
    // Combine with CSS `position: sticky; top: 0; z-index: 50;` for a
    // fixed navbar that blurs the content scrolling beneath it.
    <NavBar material="glass">
      {/* Left side: brand + navigation links */}
      <Row gap="md" align="center">
        {/* Brand mark — use title-lg-bold for the app name in the navbar.
            Replace with your logo component if you have one. */}
        <Heading variant="title-lg-bold">MyApp</Heading>

        {/* Navigation links as text buttons.
            Text variant: no background, minimal visual weight — perfect for nav.
            For the active page, switch to variant="tonal" to highlight it. */}
        {navLinks.map((link) => (
          <Button key={link.href} variant="text" href={link.href}>
            {link.label}
          </Button>
        ))}
      </Row>

      {/* Right side: utility icons + CTA */}
      <Row gap="xs" align="center">
        {/* Icon buttons for common utility actions.
            Use aria-label for accessibility — icon-only buttons have no visible text. */}
        <IconButton
          icon="search"
          variant="text"
          aria-label="Search"
        />
        <IconButton
          icon="notifications"
          variant="text"
          aria-label="Notifications"
        />

        {/* Theme toggle: swap between sun (light) and moon (dark) icons.
            This gives users manual control over the color scheme. */}
        <IconButton
          icon={isDark ? "light_mode" : "dark_mode"}
          variant="text"
          aria-label={isDark ? "Switch to light mode" : "Switch to dark mode"}
          onClick={toggleTheme}
        />

        {/* Primary CTA button — the most prominent action in the navbar.
            filled variant ensures it stands out against text buttons. */}
        <Button variant="filled" size="sm">
          Get Started
        </Button>
      </Row>
    </NavBar>
  );
}
