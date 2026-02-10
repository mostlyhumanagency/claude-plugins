// LiftKit Root Layout Template
// Copy this to app/layout.tsx in your Next.js project.
//
// What this sets up:
// - ThemeProvider wrapping the entire app (required for LiftKit color tokens)
// - CSS import for LiftKit styles (without this, components render unstyled)
// - Inter and Roboto Mono fonts via next/font/google
// - Metadata template
//
// Why ThemeProvider at the root?
// LiftKit uses Material Design 3 color tokens injected as CSS custom properties
// on :root. Without ThemeProvider, no color tokens exist and all components
// fall back to transparent/black. It also handles light/dark mode switching.

import type { Metadata } from "next";
import { Inter, Roboto_Mono } from "next/font/google";
import ThemeProvider from "@/registry/nextjs/components/theme";
import "./globals.css"; // Must contain: @import url("@/lib/css/index.css");

// Inter: LiftKit's default body font
// Weights 300-700 cover all LiftKit typography variants (light, regular, medium, bold)
const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

// Roboto Mono: LiftKit's code/monospace font
// Used in code blocks, technical labels, and anywhere mono text appears
const robotoMono = Roboto_Mono({
  subsets: ["latin"],
  variable: "--font-roboto-mono",
});

export const metadata: Metadata = {
  title: "My LiftKit App",
  description: "Built with LiftKit golden-ratio design system",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    // ThemeProvider injects MD3 color tokens as CSS custom properties on :root.
    // The font CSS variables are set on <html> so all descendants can reference them.
    <html lang="en" className={`${inter.variable} ${robotoMono.variable}`}>
      <body>
        {/* ThemeProvider must wrap all LiftKit components.
            It reads the user's system preference and applies light/dark tokens.
            To default to dark mode, add defaultTheme="dark" prop. */}
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
