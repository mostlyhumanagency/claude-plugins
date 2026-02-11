// Vitest Configuration for React Testing
// Copy this to vitest.config.ts at your project root.
//
// What this demonstrates:
// - jsdom test environment for DOM API access in tests
// - globals: true so you don't need to import describe/it/expect in every file
// - CSS modules handling (returns class names as-is for snapshot stability)
// - Path alias matching your tsconfig (@ -> ./src)
// - Coverage configuration with v8 provider
// - Setup file for extending matchers (jest-dom)
//
// Prerequisites:
//   npm install -D vitest @testing-library/react @testing-library/jest-dom
//   npm install -D @testing-library/user-event jsdom @vitejs/plugin-react
//
// Setup file (create as vitest.setup.ts in project root):
//
//   // vitest.setup.ts
//   import "@testing-library/jest-dom/vitest";
//
//   // This extends Vitest's expect() with DOM-specific matchers:
//   //   expect(element).toBeInTheDocument()
//   //   expect(element).toHaveTextContent("hello")
//   //   expect(element).toBeVisible()
//   //   expect(element).toHaveAttribute("href", "/about")
//   //   ... and many more
//   //
//   // The "/vitest" entry point auto-registers with Vitest's expect.
//   // For Jest, you would import "@testing-library/jest-dom" instead.
//
// React Testing Library best practices:
//
//   1. Query by role, not by test ID:
//      GOOD:  screen.getByRole("button", { name: /submit/i })
//      AVOID: screen.getByTestId("submit-button")
//      Why: role queries test accessibility and match how users interact.
//
//   2. Use userEvent over fireEvent:
//      GOOD:  await userEvent.click(button)
//      AVOID: fireEvent.click(button)
//      Why: userEvent simulates real browser events (focus, pointer, keyboard).
//
//   3. Prefer findBy for async operations:
//      GOOD:  const el = await screen.findByText("loaded")
//      AVOID: await waitFor(() => screen.getByText("loaded"))
//      Why: findBy = getBy + waitFor in one, cleaner and less nesting.
//
//   4. Test behavior, not implementation:
//      GOOD:  expect(screen.getByRole("alert")).toHaveTextContent("Error")
//      AVOID: expect(component.state.error).toBe(true)
//      Why: tests stay valid across refactors if they test what the user sees.
//
//   5. Structure with Arrange-Act-Assert:
//      const user = userEvent.setup();         // Arrange
//      await user.click(screen.getByRole("button")); // Act
//      expect(screen.getByRole("alert")).toBeInTheDocument(); // Assert

import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { resolve } from "path";

export default defineConfig({
  plugins: [react()],

  resolve: {
    alias: {
      // Match the path alias in your tsconfig.json:
      //   "paths": { "@/*": ["./src/*"] }
      "@": resolve(__dirname, "./src"),
    },
  },

  test: {
    // jsdom provides a browser-like DOM environment in Node.js.
    // This is required for rendering React components in tests.
    // Alternative: "happy-dom" is faster but less complete.
    environment: "jsdom",

    // When true, describe/it/expect/vi are available globally without imports.
    // Matches the Jest convention and reduces boilerplate in every test file.
    globals: true,

    // Run this file before each test suite. Use it to extend matchers,
    // set up mocks, or configure global test utilities.
    setupFiles: ["./vitest.setup.ts"],

    // CSS modules: return class names as-is so snapshots are stable.
    // Without this, CSS module imports would be undefined in tests.
    css: {
      modules: {
        classNameStrategy: "non-scoped",
      },
    },

    // Include patterns — Vitest looks for these files by default.
    // Customize if your tests live in a different location.
    include: ["src/**/*.{test,spec}.{ts,tsx}"],

    // Coverage configuration using the v8 provider (faster than istanbul).
    coverage: {
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      // Only measure coverage for source files, not tests or config.
      include: ["src/**/*.{ts,tsx}"],
      exclude: [
        "src/**/*.test.{ts,tsx}",
        "src/**/*.spec.{ts,tsx}",
        "src/**/index.ts", // barrel files are just re-exports
      ],
      // Thresholds — CI will fail if coverage drops below these.
      // Adjust these as your project matures.
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
    },
  },
});
