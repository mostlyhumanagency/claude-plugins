# React Testing Patterns

Comprehensive guide to testing React components with Vitest and React Testing Library.

## Table of Contents

- [Setup](#setup)
- [Basic Component Testing](#basic-component-testing)
- [Form Testing](#form-testing)
- [Async Testing](#async-testing)
- [Mocking](#mocking)
- [Query Reference](#query-reference)
- [User Interactions](#user-interactions)

## Setup

### Complete Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: "./src/test-setup.ts",
    globals: true, // Optional: enables global test, expect, vi
  },
});
```

### Test Setup File

```typescript
// src/test-setup.ts
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(() => {
  cleanup();
});
```

### Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```

## Basic Component Testing

### Simple Render and Query

```tsx
import { render, screen } from "@testing-library/react";
import { expect, test } from "vitest";

test("renders welcome message", () => {
  render(<Welcome name="Alice" />);

  expect(screen.getByText("Welcome, Alice!")).toBeInTheDocument();
});
```

### Testing with User Interactions

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

### Testing Conditional Rendering

```tsx
test("shows error message when invalid", () => {
  render(<Form isValid={false} />);

  expect(screen.getByText("Invalid input")).toBeInTheDocument();
});

test("hides error message when valid", () => {
  render(<Form isValid={true} />);

  expect(screen.queryByText("Invalid input")).not.toBeInTheDocument();
});
```

## Form Testing

### Basic Form Submission

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, test, vi } from "vitest";

test("submits form with user input", async () => {
  const handleSubmit = vi.fn();
  const user = userEvent.setup();

  render(<LoginForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText("Username"), "alice");
  await user.type(screen.getByLabelText("Password"), "secret");
  await user.click(screen.getByRole("button", { name: "Login" }));

  expect(handleSubmit).toHaveBeenCalledWith({
    username: "alice",
    password: "secret",
  });
});
```

### Testing Form Actions

```tsx
test("submits form and shows result", async () => {
  const user = userEvent.setup();
  render(<AddToCartForm itemId="123" title="Widget" />);

  await user.type(screen.getByLabelText("Quantity"), "2");
  await user.click(screen.getByRole("button", { name: "Add to Cart" }));

  // Wait for async action to complete
  expect(await screen.findByText("Added to cart!")).toBeInTheDocument();
});
```

### Testing Form Validation

```tsx
test("shows validation error on submit", async () => {
  const user = userEvent.setup();
  render(<SignupForm />);

  await user.click(screen.getByRole("button", { name: "Sign up" }));

  expect(await screen.findByText("Email is required")).toBeInTheDocument();
});
```

## Async Testing

### Testing with act (from react)

```tsx
import { act } from "react"; // NOT from react-dom/test-utils
import { render, screen } from "@testing-library/react";

test("updates state", async () => {
  render(<Counter />);

  await act(async () => {
    screen.getByRole("button", { name: "Increment" }).click();
  });

  expect(screen.getByText("Count: 1")).toBeInTheDocument();
});
```

### Testing Suspense Components

```tsx
import { render, screen } from "@testing-library/react";
import { Suspense } from "react";
import { expect, test } from "vitest";

test("renders data after loading", async () => {
  const dataPromise = Promise.resolve({ name: "Alice" });

  render(
    <Suspense fallback={<p>Loading...</p>}>
      <UserProfile dataPromise={dataPromise} />
    </Suspense>
  );

  // Initially shows fallback
  expect(screen.getByText("Loading...")).toBeInTheDocument();

  // Wait for content
  expect(await screen.findByText("Alice")).toBeInTheDocument();
});
```

### Using waitFor for Complex Async Logic

```tsx
import { render, screen, waitFor } from "@testing-library/react";

test("fetches and displays data", async () => {
  render(<DataFetcher url="/api/data" />);

  await waitFor(() => {
    expect(screen.getByText("Data loaded")).toBeInTheDocument();
  });
});
```

## Mocking

### Mocking Server Actions

```tsx
import { vi, test, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// Mock the server action module
vi.mock("./actions", () => ({
  createNote: vi.fn().mockResolvedValue({ id: "1", title: "Test" }),
}));

test("calls server action on submit", async () => {
  const user = userEvent.setup();
  const { createNote } = await import("./actions");

  render(<NewNoteForm />);

  await user.type(screen.getByRole("textbox"), "My note");
  await user.click(screen.getByRole("button", { name: "Create" }));

  expect(createNote).toHaveBeenCalledWith({
    title: "My note",
  });
});
```

### Mocking Fetch Requests

```tsx
import { vi, beforeEach, test } from "vitest";

beforeEach(() => {
  global.fetch = vi.fn();
});

test("fetches user data", async () => {
  global.fetch.mockResolvedValueOnce({
    ok: true,
    json: async () => ({ name: "Alice", id: "123" }),
  });

  render(<UserProfile userId="123" />);

  expect(await screen.findByText("Alice")).toBeInTheDocument();
  expect(fetch).toHaveBeenCalledWith("/api/users/123");
});
```

### Mocking Modules

```tsx
vi.mock("./api", () => ({
  fetchUser: vi.fn().mockResolvedValue({ name: "Alice" }),
  updateUser: vi.fn(),
}));

test("displays user data", async () => {
  const { fetchUser } = await import("./api");

  render(<UserCard userId="123" />);

  expect(await screen.findByText("Alice")).toBeInTheDocument();
  expect(fetchUser).toHaveBeenCalledWith("123");
});
```

## Query Reference

### Query Priority (Best to Worst)

```tsx
// 1. getByRole — Best for accessibility
screen.getByRole("button", { name: "Submit" });
screen.getByRole("textbox", { name: "Email" });
screen.getByRole("heading", { name: "Welcome" });

// 2. getByLabelText — For form fields
screen.getByLabelText("Username");
screen.getByLabelText(/password/i);

// 3. getByPlaceholderText — When no label exists
screen.getByPlaceholderText("Enter email...");

// 4. getByText — For non-interactive content
screen.getByText("Welcome back!");
screen.getByText(/hello/i);

// 5. getByTestId — Last resort
screen.getByTestId("custom-element");
```

### Query Variants

| Query Type | Returns | Throws | Async | Use Case |
|------------|---------|--------|-------|----------|
| `getBy*` | Element | Yes | No | Element should be present |
| `queryBy*` | Element \| null | No | No | Asserting element absence |
| `findBy*` | Promise<Element> | Yes | Yes | Element appears async |
| `getAllBy*` | Element[] | Yes | No | Multiple elements present |
| `queryAllBy*` | Element[] | No | No | Multiple elements (may be empty) |
| `findAllBy*` | Promise<Element[]> | Yes | Yes | Multiple elements appear async |

### Examples

```tsx
// Get single element (throws if not found)
const button = screen.getByRole("button");

// Query element (returns null if not found)
const error = screen.queryByText("Error");
expect(error).not.toBeInTheDocument();

// Find element (async, waits for appearance)
const message = await screen.findByText("Success!");

// Get all elements
const items = screen.getAllByRole("listitem");
expect(items).toHaveLength(3);

// Query all (won't throw if empty)
const errors = screen.queryAllByRole("alert");
expect(errors).toHaveLength(0);

// Find all (async)
const items = await screen.findAllByRole("listitem");
```

## User Interactions

### userEvent vs fireEvent

**Always prefer `userEvent`** — it simulates realistic user interactions with proper event sequences.

```tsx
// GOOD: userEvent (realistic)
const user = userEvent.setup();
await user.click(button);
await user.type(input, "hello");

// AVOID: fireEvent (low-level, unrealistic)
fireEvent.click(button);
fireEvent.change(input, { target: { value: "hello" } });
```

### Common userEvent Actions

```tsx
import userEvent from "@testing-library/user-event";

test("user interactions", async () => {
  const user = userEvent.setup();

  // Click
  await user.click(screen.getByRole("button"));

  // Type
  await user.type(screen.getByRole("textbox"), "Hello");

  // Clear and type
  await user.clear(screen.getByRole("textbox"));
  await user.type(screen.getByRole("textbox"), "New text");

  // Select option
  await user.selectOptions(
    screen.getByRole("combobox"),
    "option-value"
  );

  // Upload file
  const file = new File(["content"], "test.png", { type: "image/png" });
  const input = screen.getByLabelText("Upload");
  await user.upload(input, file);

  // Keyboard interactions
  await user.keyboard("{Enter}");
  await user.keyboard("{Tab}");
  await user.keyboard("{Escape}");

  // Hover
  await user.hover(screen.getByRole("button"));
  await user.unhover(screen.getByRole("button"));
});
```

### Testing Keyboard Navigation

```tsx
test("navigates with keyboard", async () => {
  const user = userEvent.setup();
  render(<Menu />);

  await user.keyboard("{Tab}");
  expect(screen.getByRole("menuitem", { name: "Home" })).toHaveFocus();

  await user.keyboard("{ArrowDown}");
  expect(screen.getByRole("menuitem", { name: "About" })).toHaveFocus();

  await user.keyboard("{Enter}");
  expect(screen.getByText("About Page")).toBeInTheDocument();
});
```

## Common Mistakes and Solutions

### Mistake: Wrong act Import

```tsx
// WRONG
import { act } from "react-dom/test-utils"; // Removed in React 19

// CORRECT
import { act } from "react";
```

### Mistake: Using getBy for Async Content

```tsx
// WRONG: Will fail if element appears after initial render
const message = screen.getByText("Success");

// CORRECT: Waits for element to appear
const message = await screen.findByText("Success");
```

### Mistake: Testing Implementation Details

```tsx
// WRONG: Testing internal state
expect(component.state.count).toBe(1);

// CORRECT: Testing user-visible behavior
expect(screen.getByText("Count: 1")).toBeInTheDocument();
```

### Mistake: Forgetting userEvent.setup()

```tsx
// WRONG
await userEvent.click(button); // May not work correctly

// CORRECT
const user = userEvent.setup();
await user.click(button);
```

### Mistake: Not Awaiting Async Interactions

```tsx
// WRONG
user.click(button); // Missing await
expect(screen.getByText("Clicked")).toBeInTheDocument();

// CORRECT
await user.click(button);
expect(screen.getByText("Clicked")).toBeInTheDocument();
```

## Best Practices

1. **Test user behavior, not implementation** — Query by role, label, and text that users see
2. **Prefer accessibility queries** — Use `getByRole` to ensure components are accessible
3. **Always setup userEvent** — Call `userEvent.setup()` before interactions
4. **Use async queries for async content** — Use `findBy*` or `waitFor` for elements that appear later
5. **Avoid test IDs when possible** — Only use `data-testid` when semantic queries don't work
6. **Clean up after tests** — Use `afterEach(cleanup)` in setup file
7. **Mock at the boundary** — Mock API calls, not component internals
8. **Write integration tests** — Test multiple components together when they interact
