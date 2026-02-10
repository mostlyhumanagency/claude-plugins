---
name: testing-react
description: Use when testing React components with Vitest and React Testing Library
---

# Testing React Components

Test React components by simulating user behavior with Vitest and React Testing Library (RTL). Focus on what users see and do, not implementation details.

## Overview

This skill helps you write component tests using:
- **Vitest** — Fast, Vite-native test runner with Jest-compatible API
- **React Testing Library** — Query and interact with components like a user would
- **userEvent** — Simulate realistic user interactions
- **jsdom** — Browser environment for Node.js tests

Tests render components, query elements by role/label/text, simulate user interactions, and assert on visible changes.

## When to Use

- Testing component rendering and display logic
- Testing user interactions (clicks, typing, form submissions)
- Testing async behavior (data fetching, Suspense)
- Testing form actions and state updates
- Setting up a new React project's test infrastructure

## Setup

Install dependencies:

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

Create `vitest.config.ts`:

```typescript
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: "./src/test-setup.ts",
  },
});
```

Create `src/test-setup.ts`:

```typescript
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(() => {
  cleanup();
});
```

## Core Patterns

### Basic Component Test

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, test } from "vitest";

test("shows greeting after clicking button", async () => {
  const user = userEvent.setup();
  render(<Greeting name="Alice" />);

  await user.click(screen.getByRole("button", { name: "Say hello" }));

  expect(screen.getByText("Hello, Alice!")).toBeInTheDocument();
});
```

### Form Submission Test

```tsx
test("submits form and shows result", async () => {
  const user = userEvent.setup();
  render(<AddToCartForm itemId="123" title="Widget" />);

  await user.type(screen.getByLabelText("Quantity"), "2");
  await user.click(screen.getByRole("button", { name: "Add to Cart" }));

  expect(await screen.findByText("Added to cart!")).toBeInTheDocument();
});
```

## Quick Reference

### Query Priority

| Priority | Query | Use When |
|----------|-------|----------|
| 1st | `getByRole` | Any element with ARIA role (buttons, inputs, headings) |
| 2nd | `getByLabelText` | Form fields with labels |
| 3rd | `getByPlaceholderText` | Inputs with placeholder |
| 4th | `getByText` | Non-interactive text content |
| 5th | `getByTestId` | Last resort — no semantic query works |

### Query Variants

| Variant | Behavior |
|---------|----------|
| `getBy*` | Throws if not found; synchronous |
| `queryBy*` | Returns `null` if not found; for asserting absence |
| `findBy*` | Async; waits for element to appear |
| `*AllBy*` | Returns array of matches |

## Common Mistakes

- **Using `act` from wrong import** — Import from `react`, not `react-dom/test-utils`
- **Using `getBy*` for async content** — Use `findBy*` or `waitFor` instead
- **Testing implementation details** — Test user-visible behavior, not state/props
- **Not calling `userEvent.setup()`** — Always setup before interactions
- **Using `fireEvent`** — Prefer `userEvent` for realistic event sequences

See [patterns.md](./patterns.md) for comprehensive examples and advanced patterns.
