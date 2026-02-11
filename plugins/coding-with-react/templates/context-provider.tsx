// React 19 Context Provider Template
// Copy this to context/theme-context.tsx (or adapt for auth, locale, etc.).
//
// What this demonstrates:
// - createContext with a typed value
// - useReducer for complex state transitions (more predictable than useState)
// - Custom consumer hook (useTheme) with a helpful error if used outside provider
// - React 19 context syntax: <ThemeContext value={...}> replaces <ThemeContext.Provider value={...}>
// - Children composition pattern
// - Memoized context value to prevent unnecessary re-renders
//
// React 19 context change:
// In React 19, you render <Context value={...}> directly instead of
// <Context.Provider value={...}>. The .Provider API still works but is
// deprecated and will be removed in a future version. This template uses
// the new syntax.
//
// Usage:
//
//   // In your root layout:
//   import { ThemeProvider } from "@/context/theme-context";
//
//   export default function RootLayout({ children }: { children: React.ReactNode }) {
//     return (
//       <ThemeProvider defaultTheme="system">
//         {children}
//       </ThemeProvider>
//     );
//   }
//
//   // In any child component:
//   import { useTheme } from "@/context/theme-context";
//
//   function ThemeToggle() {
//     const { theme, setTheme } = useTheme();
//     return <button onClick={() => setTheme(theme === "dark" ? "light" : "dark")}>Toggle</button>;
//   }

"use client";

import {
  createContext,
  useContext,
  useReducer,
  useMemo,
  type ReactNode,
} from "react";

// -- Types ------------------------------------------------------------------

type Theme = "light" | "dark" | "system";

/** The value exposed to consumers via useTheme(). */
interface ThemeContextValue {
  theme: Theme;
  resolvedTheme: "light" | "dark";
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
}

/** Props for the ThemeProvider component. */
interface ThemeProviderProps {
  children: ReactNode;
  /** The initial theme. Defaults to "system". */
  defaultTheme?: Theme;
}

// -- Reducer ----------------------------------------------------------------

// A reducer is preferable to multiple useState calls when state transitions
// have clear rules. It also makes it easier to add new actions (e.g., "reset")
// without scattering logic across event handlers.

type ThemeAction =
  | { type: "SET_THEME"; payload: Theme }
  | { type: "TOGGLE_THEME" };

interface ThemeState {
  theme: Theme;
}

function themeReducer(state: ThemeState, action: ThemeAction): ThemeState {
  switch (action.type) {
    case "SET_THEME":
      return { theme: action.payload };
    case "TOGGLE_THEME":
      // Toggle between light and dark. If currently "system", resolve first.
      return {
        theme: resolveTheme(state.theme) === "dark" ? "light" : "dark",
      };
    default:
      return state;
  }
}

// -- Helpers ----------------------------------------------------------------

/** Resolve "system" to a concrete theme based on the user's OS preference. */
function resolveTheme(theme: Theme): "light" | "dark" {
  if (theme !== "system") return theme;
  // typeof window check for SSR safety — default to "light" on the server.
  if (typeof window === "undefined") return "light";
  return window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

// -- Context ----------------------------------------------------------------

// The default value is `null` rather than a mock object. This lets the custom
// hook detect when a consumer is outside the provider and throw a clear error,
// instead of silently returning stale/fake data.
const ThemeContext = createContext<ThemeContextValue | null>(null);

// -- Provider ---------------------------------------------------------------

export function ThemeProvider({
  children,
  defaultTheme = "system",
}: ThemeProviderProps) {
  const [state, dispatch] = useReducer(themeReducer, {
    theme: defaultTheme,
  });

  // useMemo prevents creating a new context value object on every render.
  // Without this, every child that calls useTheme() would re-render even if
  // the theme hasn't changed, because the value reference would be different.
  const value = useMemo<ThemeContextValue>(
    () => ({
      theme: state.theme,
      resolvedTheme: resolveTheme(state.theme),
      setTheme: (theme: Theme) =>
        dispatch({ type: "SET_THEME", payload: theme }),
      toggleTheme: () => dispatch({ type: "TOGGLE_THEME" }),
    }),
    [state.theme],
  );

  // React 19 syntax: <ThemeContext value={...}> instead of <ThemeContext.Provider value={...}>
  // The old .Provider syntax is deprecated in React 19.
  return <ThemeContext value={value}>{children}</ThemeContext>;
}

// -- Consumer hook ----------------------------------------------------------

/**
 * Access the current theme and controls.
 *
 * Throws if called outside a <ThemeProvider>. This is intentional — a silent
 * fallback would hide bugs where a component is rendered without the provider,
 * leading to confusing behavior at runtime.
 */
export function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext);
  if (context === null) {
    throw new Error(
      "useTheme() must be used within a <ThemeProvider>. " +
        "Wrap your component tree with <ThemeProvider> in your root layout.",
    );
  }
  return context;
}
