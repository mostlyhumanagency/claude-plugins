// LiftKit Landing Page Template
// Copy this to app/page.tsx for a complete landing page.
//
// Structure:
// 1. Hero section — glass Card with display heading, body text, CTA button
// 2. Features section — responsive 3-column grid of feature cards
// 3. CTA section — centered call-to-action with button
//
// Why Section/Container/Grid?
// LiftKit uses a composition pattern: Section provides vertical rhythm and
// background, Container constrains max-width, and Grid handles column layout.
// This mirrors how professional design systems separate concerns.

import { Button } from "@/registry/nextjs/components/button";
import { Card } from "@/registry/nextjs/components/card";
import { Column } from "@/registry/nextjs/components/column";
import { Container } from "@/registry/nextjs/components/container";
import { Grid } from "@/registry/nextjs/components/grid";
import { Heading } from "@/registry/nextjs/components/heading";
import { Row } from "@/registry/nextjs/components/row";
import { Section } from "@/registry/nextjs/components/section";
import { Text } from "@/registry/nextjs/components/text";

// Feature data — extract to a separate file if this grows
const features = [
  {
    title: "Golden Ratio Design",
    description:
      "Every spacing, sizing, and proportion value derived from the golden ratio for natural visual harmony.",
  },
  {
    title: "MD3 Color System",
    description:
      "Full Material Design 3 color token system with automatic light/dark mode support.",
  },
  {
    title: "Responsive by Default",
    description:
      "Components adapt to any screen size using autoResponsive grids and fluid containers.",
  },
];

export default function LandingPage() {
  return (
    <main>
      {/* --- Hero Section ---
          Section adds consistent vertical padding.
          Container constrains content width (default max-width from LiftKit). */}
      <Section>
        <Container>
          <Column gap="lg" align="center">
            {/* Glass material creates a frosted-glass backdrop blur effect.
                Great for hero cards that sit over background images/gradients. */}
            <Card material="glass" padding="xl">
              <Column gap="md" align="center">
                {/* display1-bold: the largest LiftKit heading variant.
                    Use sparingly — one per page, typically in the hero. */}
                <Heading variant="display1-bold" align="center">
                  Build Beautiful UIs with LiftKit
                </Heading>

                {/* body-lg for hero subtext — large enough to read at a glance
                    but clearly subordinate to the display heading. */}
                <Text variant="body-lg" align="center">
                  A golden-ratio design system with Material Design 3 color
                  tokens, responsive grids, and composable components for
                  Next.js.
                </Text>

                <Row gap="md" justify="center">
                  {/* Primary button: filled style, draws the most attention.
                      Use for the single most important action on screen. */}
                  <Button variant="filled" size="lg">
                    Get Started
                  </Button>

                  {/* Outlined button: secondary action, visually lighter.
                      Pairs well next to a filled button for a two-CTA pattern. */}
                  <Button variant="outlined" size="lg">
                    View Docs
                  </Button>
                </Row>
              </Column>
            </Card>
          </Column>
        </Container>
      </Section>

      {/* --- Features Section ---
          A second Section creates visual separation via vertical spacing. */}
      <Section>
        <Container>
          <Column gap="lg">
            <Heading variant="headline1-bold" align="center">
              Why LiftKit?
            </Heading>

            {/* autoResponsive: Grid automatically stacks columns on small screens.
                columns={3}: three equal columns on wide screens.
                This is the standard LiftKit responsive grid pattern. */}
            <Grid columns={3} gap="md" autoResponsive>
              {features.map((feature) => (
                <Card key={feature.title} padding="lg">
                  <Column gap="sm">
                    <Heading variant="title-lg-bold">{feature.title}</Heading>
                    <Text variant="body-md">{feature.description}</Text>
                  </Column>
                </Card>
              ))}
            </Grid>
          </Column>
        </Container>
      </Section>

      {/* --- CTA Section ---
          Final push to convert. Keep it simple: heading + single button. */}
      <Section>
        <Container>
          <Column gap="md" align="center">
            <Heading variant="headline2-bold" align="center">
              Ready to Start Building?
            </Heading>
            <Text variant="body-lg" align="center">
              Get up and running in minutes with LiftKit components.
            </Text>
            <Button variant="filled" size="lg">
              Start Your Project
            </Button>
          </Column>
        </Container>
      </Section>
    </main>
  );
}
