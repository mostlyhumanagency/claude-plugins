// LiftKit Dashboard Page Template
// Copy this to app/dashboard/page.tsx for a complete dashboard layout.
//
// Structure:
// 1. NavBar — top navigation with links and icon buttons
// 2. Stats row — 4-column grid of metric cards
// 3. Tabs — tabbed content area (Overview, Analytics, Settings)
//
// Why this layout?
// Dashboards follow a predictable pattern: nav at top for wayfinding,
// key metrics visible immediately, and tabbed sections to organize
// dense content without overwhelming the user.

import { Button } from "@/registry/nextjs/components/button";
import { Card } from "@/registry/nextjs/components/card";
import { Column } from "@/registry/nextjs/components/column";
import { Container } from "@/registry/nextjs/components/container";
import { Grid } from "@/registry/nextjs/components/grid";
import { Heading } from "@/registry/nextjs/components/heading";
import { IconButton } from "@/registry/nextjs/components/icon-button";
import { NavBar } from "@/registry/nextjs/components/nav-bar";
import { Row } from "@/registry/nextjs/components/row";
import { Section } from "@/registry/nextjs/components/section";
import { Tabs } from "@/registry/nextjs/components/tabs";
import { Text } from "@/registry/nextjs/components/text";

// Sample stats — replace with real data from your API or database
const stats = [
  { label: "Total Users", value: "12,847", change: "+12%" },
  { label: "Revenue", value: "$48,290", change: "+8%" },
  { label: "Active Sessions", value: "1,024", change: "+23%" },
  { label: "Conversion Rate", value: "3.2%", change: "-2%" },
];

// Tab definitions for the Tabs component
const tabs = [
  { id: "overview", label: "Overview" },
  { id: "analytics", label: "Analytics" },
  { id: "settings", label: "Settings" },
];

export default function DashboardPage() {
  return (
    <Column>
      {/* --- NavBar ---
          NavBar is a top-level navigation component.
          material="glass" gives it the frosted-glass look that layers well
          over content when the page scrolls (if you add sticky positioning). */}
      <NavBar material="glass">
        <Row gap="sm" align="center">
          <Heading variant="title-lg-bold">Dashboard</Heading>

          {/* Navigation buttons — use "text" variant for nav links.
              Text buttons have no background, keeping the navbar clean. */}
          <Button variant="text">Overview</Button>
          <Button variant="text">Reports</Button>
          <Button variant="text">Team</Button>
        </Row>

        <Row gap="xs" align="center">
          {/* IconButtons for toolbar-style actions.
              Keep icon-only actions on the right side of the navbar. */}
          <IconButton icon="search" variant="text" aria-label="Search" />
          <IconButton
            icon="notifications"
            variant="text"
            aria-label="Notifications"
          />

          {/* Tonal variant: more emphasis than text, less than filled.
              Good for the primary navbar action. */}
          <Button variant="tonal" size="sm">
            New Report
          </Button>
        </Row>
      </NavBar>

      {/* --- Main Content ---
          Section + Container pattern: Section adds vertical padding,
          Container constrains the width for readability. */}
      <Section>
        <Container>
          <Column gap="lg">
            {/* --- Stats Row ---
                4-column grid for key metrics. autoResponsive collapses
                to 2 columns on tablet and 1 on mobile automatically. */}
            <Grid columns={4} gap="md" autoResponsive>
              {stats.map((stat) => (
                <Card key={stat.label} padding="lg">
                  <Column gap="xs">
                    {/* label-lg for the metric category — small, uppercase-style text */}
                    <Text variant="label-lg">{stat.label}</Text>

                    {/* headline2-bold for the number — large and prominent */}
                    <Heading variant="headline2-bold">{stat.value}</Heading>

                    {/* body-sm for secondary info like change percentage */}
                    <Text variant="body-sm">{stat.change} from last month</Text>
                  </Column>
                </Card>
              ))}
            </Grid>

            {/* --- Tabbed Content ---
                Tabs organize related content into switchable panels.
                Each tab renders its own content below the tab bar. */}
            <Card padding="lg">
              <Tabs tabs={tabs} defaultTab="overview">
                {/* Overview Tab Content */}
                <Tabs.Panel id="overview">
                  <Column gap="md">
                    <Heading variant="title-lg-bold">
                      Overview
                    </Heading>
                    <Text variant="body-md">
                      Welcome to your dashboard. Here you can see a summary of
                      your key metrics and recent activity.
                    </Text>
                    <Grid columns={2} gap="md" autoResponsive>
                      <Card padding="md">
                        <Column gap="sm">
                          <Heading variant="title-md-bold">
                            Recent Activity
                          </Heading>
                          <Text variant="body-md">
                            5 new users signed up today. 3 reports were
                            generated.
                          </Text>
                        </Column>
                      </Card>
                      <Card padding="md">
                        <Column gap="sm">
                          <Heading variant="title-md-bold">Quick Actions</Heading>
                          <Row gap="sm">
                            <Button variant="filled" size="sm">
                              Create Report
                            </Button>
                            <Button variant="outlined" size="sm">
                              Invite User
                            </Button>
                          </Row>
                        </Column>
                      </Card>
                    </Grid>
                  </Column>
                </Tabs.Panel>

                {/* Analytics Tab Content */}
                <Tabs.Panel id="analytics">
                  <Column gap="md">
                    <Heading variant="title-lg-bold">Analytics</Heading>
                    <Text variant="body-md">
                      Detailed analytics and charts would go here. Integrate
                      with your preferred charting library (e.g., Recharts,
                      Chart.js) inside LiftKit Cards for consistent styling.
                    </Text>
                    <Card padding="md">
                      <Text variant="body-md">
                        Chart placeholder — replace with your charting component.
                      </Text>
                    </Card>
                  </Column>
                </Tabs.Panel>

                {/* Settings Tab Content */}
                <Tabs.Panel id="settings">
                  <Column gap="md">
                    <Heading variant="title-lg-bold">Settings</Heading>
                    <Text variant="body-md">
                      Configure your dashboard preferences and notification
                      settings here.
                    </Text>
                  </Column>
                </Tabs.Panel>
              </Tabs>
            </Card>
          </Column>
        </Container>
      </Section>
    </Column>
  );
}
