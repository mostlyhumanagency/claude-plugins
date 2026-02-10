# Modern React Patterns Reference

Complete guide to React 19+ patterns with detailed examples.

## Ref as Prop

### Basic Usage

Refs are now regular props — no `forwardRef` wrapper needed.

```tsx
// Before — forwardRef wrapper required
const MyInput = forwardRef<HTMLInputElement, Props>(({ placeholder }, ref) => (
  <input placeholder={placeholder} ref={ref} />
));

// After — ref is just a prop
function MyInput({ placeholder, ref }: { placeholder: string; ref?: React.Ref<HTMLInputElement> }) {
  return <input placeholder={placeholder} ref={ref} />;
}

// Usage (same as before)
function Form() {
  const inputRef = useRef<HTMLInputElement>(null);
  return <MyInput placeholder="Name" ref={inputRef} />;
}
```

### Ref Cleanup Function

Ref callbacks now support returning a cleanup function that runs on unmount.

```tsx
function ResizableInput() {
  return (
    <input
      ref={(node) => {
        // Setup
        const observer = new ResizeObserver(() => {
          console.log('Size changed');
        });

        if (node) {
          observer.observe(node);
        }

        // Cleanup — runs when component unmounts or ref changes
        return () => observer.disconnect();
      }}
    />
  );
}
```

### TypeScript Caveat

Avoid implicit returns in ref callbacks — TypeScript may infer incorrect types.

```tsx
// Bad — implicit return
<input ref={(n) => instance = n} />  // Type error

// Good — explicit block
<input ref={(n) => { instance = n; }} />
```

## Context as Provider

Context components can now act as their own providers.

```tsx
const ThemeContext = createContext<string>("light");

// Before
function App() {
  return (
    <ThemeContext.Provider value="dark">
      {children}
    </ThemeContext.Provider>
  );
}

// After — Context IS the provider
function App() {
  return (
    <ThemeContext value="dark">
      {children}
    </ThemeContext>
  );
}

// Consuming context (unchanged)
function Button() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click</button>;
}
```

## Document Metadata

Render `<title>`, `<meta>`, and `<link>` tags anywhere in your component tree. React automatically hoists them to the document `<head>`.

```tsx
function BlogPost({ post }: { post: Post }) {
  return (
    <article>
      <title>{post.title}</title>
      <meta name="author" content={post.author} />
      <meta name="description" content={post.summary} />
      <link rel="canonical" href={post.url} />

      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  );
}

// Multiple components can render metadata — React deduplicates
function ProductPage({ product }: { product: Product }) {
  return (
    <div>
      <title>{product.name} - Store</title>
      <meta property="og:title" content={product.name} />
      <meta property="og:image" content={product.image} />

      <ProductDetails product={product} />
    </div>
  );
}
```

## Resource Preloading

Use React's resource preloading APIs to optimize loading performance.

```tsx
import { prefetchDNS, preconnect, preload, preinit } from "react-dom";

function App() {
  // Load and execute script eagerly (highest priority)
  preinit("/critical.js", { as: "script" });

  // Preload font (download but don't execute)
  preload("/font.woff2", { as: "font", type: "font/woff2" });

  // Open connection to API early
  preconnect("https://api.example.com");

  // DNS lookup only (lowest priority)
  prefetchDNS("https://cdn.example.com");

  return <div>...</div>;
}
```

### API Details

| API | When to Use | What It Does |
|-----|-------------|--------------|
| `preinit(url, { as })` | Critical scripts/styles | Downloads AND executes/applies immediately |
| `preload(url, { as, type? })` | Fonts, images needed soon | Downloads but doesn't execute (browser cache) |
| `preconnect(url)` | External APIs, CDNs | Opens TCP/TLS connection early |
| `prefetchDNS(url)` | Lower-priority external domains | DNS lookup only |

### Resource Options

```tsx
// Script with integrity check
preinit("/app.js", {
  as: "script",
  integrity: "sha384-...",
  crossOrigin: "anonymous"
});

// Font with type hint
preload("/heading.woff2", {
  as: "font",
  type: "font/woff2",
  crossOrigin: "anonymous" // Required for fonts
});

// Stylesheet with fetchPriority
preload("/theme.css", {
  as: "style",
  fetchPriority: "high"
});
```

## useDeferredValue with Initial Value

Defer updates to a value while providing an initial placeholder.

```tsx
import { useDeferredValue, useState } from "react";

function Search() {
  const [query, setQuery] = useState("");

  // Returns "" on first render, then defers updates to query
  const deferredQuery = useDeferredValue(query, "");

  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <SearchResults query={deferredQuery} />
    </>
  );
}

function SearchResults({ query }: { query: string }) {
  // Expensive computation
  const results = useMemo(() => searchDatabase(query), [query]);

  return (
    <ul>
      {results.map(r => <li key={r.id}>{r.name}</li>)}
    </ul>
  );
}
```

## Activity Component (React 19.2+)

Control component visibility and priority while preserving state.

```tsx
import { Activity } from "react";

function TabContainer({ activeTab }: { activeTab: string }) {
  return (
    <>
      <Activity mode={activeTab === "home" ? "visible" : "hidden"}>
        <HomePage />
      </Activity>

      <Activity mode={activeTab === "settings" ? "visible" : "hidden"}>
        <SettingsPage />
      </Activity>

      <Activity mode={activeTab === "profile" ? "visible" : "hidden"}>
        <ProfilePage />
      </Activity>
    </>
  );
}
```

### Activity Modes

| Mode | Behavior |
|------|----------|
| `"visible"` | Component renders normally |
| `"hidden"` | Preserves state, unmounts effects, defers updates (low priority) |
| `"unstable-defer"` | Visible but low priority (experimental) |

### When Hidden

- Component state is preserved (useState, useRef, etc.)
- Effects are unmounted (cleanup functions run)
- Updates are deferred until visible again
- DOM is still rendered (use CSS to hide visually)

```tsx
function TabContent() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    console.log("Effect mounted");
    return () => console.log("Effect cleaned up");
  }, []);

  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}

// When tab switches:
// - count state is preserved
// - Effect cleanup runs
// - Button clicks are queued but don't update UI until visible
```

## useEffectEvent (React 19.2+)

Separate event logic from Effect dependencies. Effect Events read the latest props/state without being dependencies.

```tsx
import { useEffect, useEffectEvent } from "react";

function ChatRoom({ roomId, theme }: { roomId: string; theme: string }) {
  // Event logic — reads latest theme without being a dependency
  const onConnected = useEffectEvent(() => {
    showNotification("Connected!", theme);
  });

  const onMessage = useEffectEvent((msg: string) => {
    logMessage(msg, theme); // Always uses current theme
  });

  useEffect(() => {
    const conn = createConnection(roomId);

    conn.on("connected", onConnected);
    conn.on("message", onMessage);
    conn.connect();

    return () => conn.disconnect();
  }, [roomId]); // Only reconnect when roomId changes, NOT theme
}
```

### Rules

- Never add Effect Events to dependency arrays
- Only call from Effects (or other Effect Events)
- Can't be passed to other components

### Before vs After

```tsx
// Before — theme in deps causes reconnection on theme change
useEffect(() => {
  const conn = createConnection(roomId);
  conn.on("connected", () => showNotification("Connected!", theme));
  conn.connect();
  return () => conn.disconnect();
}, [roomId, theme]); // Reconnects unnecessarily

// After — theme changes don't trigger reconnection
const onConnected = useEffectEvent(() => {
  showNotification("Connected!", theme);
});

useEffect(() => {
  const conn = createConnection(roomId);
  conn.on("connected", onConnected);
  conn.connect();
  return () => conn.disconnect();
}, [roomId]); // Only roomId matters
```

## Stylesheet Precedence

Control CSS insertion order with the `precedence` attribute.

```tsx
function Component() {
  return (
    <>
      <link rel="stylesheet" href="/reset.css" precedence="low" />
      <link rel="stylesheet" href="/base.css" precedence="default" />
      <link rel="stylesheet" href="/theme.css" precedence="high" />

      <div className="styled">Content</div>
    </>
  );
}

// Insertion order: low → default → high
// Automatically deduplicated across renders
```

### Precedence Levels

- `"reset"` — CSS resets (lowest)
- `"low"` — Base styles
- `"default"` — Component styles
- `"high"` — Theme/override styles (highest)

### Deduplication

React deduplicates stylesheets with the same `href` across the entire app.

```tsx
// Both components render the same stylesheet
function ComponentA() {
  return <link rel="stylesheet" href="/shared.css" precedence="default" />;
}

function ComponentB() {
  return <link rel="stylesheet" href="/shared.css" precedence="default" />;
}

// Result: /shared.css loads only once
```

## ViewTransition (Experimental)

Animate UI changes with the View Transitions API.

```tsx
import { useTransition } from "react";
import { flushSync } from "react-dom";

function Gallery() {
  const [index, setIndex] = useState(0);
  const [isPending, startTransition] = useTransition();

  const nextImage = () => {
    startTransition(() => {
      if (document.startViewTransition) {
        document.startViewTransition(() => {
          flushSync(() => {
            setIndex((i) => (i + 1) % images.length);
          });
        });
      } else {
        setIndex((i) => (i + 1) % images.length);
      }
    });
  };

  return (
    <>
      <img src={images[index]} alt="Gallery" />
      <button onClick={nextImage}>Next</button>
    </>
  );
}
```

CSS for transition:

```css
::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: 0.5s;
}
```

Note: View Transitions API is experimental and requires browser support. Check `document.startViewTransition` before using.

## Complete Example

Putting it all together:

```tsx
import { useState, useEffect, useEffectEvent, Activity } from "react";
import { preload } from "react-dom";

const ThemeContext = createContext<string>("light");

function App() {
  const [theme, setTheme] = useState("light");
  const [activeTab, setActiveTab] = useState("home");

  // Preload resources
  preload("/font.woff2", { as: "font", type: "font/woff2" });

  return (
    <ThemeContext value={theme}>
      <title>My App - {activeTab}</title>
      <meta name="theme-color" content={theme === "dark" ? "#000" : "#fff"} />

      <nav>
        <button onClick={() => setActiveTab("home")}>Home</button>
        <button onClick={() => setActiveTab("settings")}>Settings</button>
      </nav>

      <Activity mode={activeTab === "home" ? "visible" : "hidden"}>
        <HomePage />
      </Activity>

      <Activity mode={activeTab === "settings" ? "visible" : "hidden"}>
        <SettingsPage theme={theme} onThemeChange={setTheme} />
      </Activity>
    </ThemeContext>
  );
}

function HomePage() {
  const theme = useContext(ThemeContext);

  const logView = useEffectEvent(() => {
    analytics.track("page_view", { theme });
  });

  useEffect(() => {
    logView(); // Uses current theme, doesn't re-run on theme change
  }, []); // Empty deps

  return <h1>Home</h1>;
}

function SettingsPage({
  theme,
  onThemeChange,
  ref
}: {
  theme: string;
  onThemeChange: (t: string) => void;
  ref?: React.Ref<HTMLDivElement>;
}) {
  return (
    <div ref={ref}>
      <h1>Settings</h1>
      <button onClick={() => onThemeChange(theme === "light" ? "dark" : "light")}>
        Toggle Theme
      </button>
    </div>
  );
}
```
