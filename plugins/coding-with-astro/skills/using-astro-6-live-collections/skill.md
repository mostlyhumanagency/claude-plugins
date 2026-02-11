---
name: using-astro-6-live-collections
description: "Use when fetching live or frequently-changing data in Astro 6 without rebuilding the site. Use for tasks like 'show real-time data without rebuilding', 'fetch live stock prices', 'display current inventory', or 'migrate static collections to live'. Covers live content collections that fetch data at request time, result objects with explicit error handling, configuring live loaders, and migrating from static to live collections."
---

# Using Astro 6 Live Content Collections

Live content collections are a content layer feature stabilized in Astro 6 (previously experimental). They fetch data at request time rather than build time, providing real-time data without requiring a rebuild.

## What Are Live Collections

Standard content collections fetch and cache data at build time. The data is static until you rebuild the site. Live collections fetch fresh data on every request, making them suitable for content that changes frequently.

Live collections were introduced as an experimental feature and are now stable in Astro 6.

## Use Cases

- **Stock prices** — Display current market data
- **Inventory levels** — Show real-time product availability
- **Live feeds** — Social media feeds, news tickers, activity streams
- **Leaderboards** — Gaming or competition rankings
- **Weather data** — Current conditions and forecasts
- **API-driven content** — Any external data source that updates frequently

## Defining a Live Collection

In `src/content.config.ts`, define a collection with a loader that has a `load` function:

```typescript
import { defineCollection, z } from "astro:content";

const stockPrices = defineCollection({
  loader: {
    name: "stock-prices",
    load: async () => {
      const response = await fetch("https://api.example.com/stocks");
      const data = await response.json();
      return data.map((stock: any) => ({
        id: stock.symbol,
        symbol: stock.symbol,
        price: stock.price,
        change: stock.change,
        updatedAt: stock.updatedAt,
      }));
    },
  },
  schema: z.object({
    symbol: z.string(),
    price: z.number(),
    change: z.number(),
    updatedAt: z.string(),
  }),
});

export const collections = { stockPrices };
```

## Explicit Error Handling with Result Objects

Live collections use result objects for error handling instead of throwing exceptions. This gives you explicit control over how failures are displayed to users.

```astro
---
import { getCollection } from "astro:content";

const result = await getCollection("stockPrices");

if (result.error) {
  // Handle the error explicitly
  console.error("Failed to fetch stock prices:", result.error.message);
}
---

{result.error ? (
  <p>Unable to load stock prices. Please try again later.</p>
) : (
  <ul>
    {result.data.map((stock) => (
      <li>{stock.symbol}: ${stock.price} ({stock.change > 0 ? "+" : ""}{stock.change}%)</li>
    ))}
  </ul>
)}
```

The result object has this shape:

- `result.data` — The collection entries when the fetch succeeds
- `result.error` — An error object when the fetch fails, with a `message` property

## Comparison with Standard Content Collections

| Feature | Standard Collections | Live Collections |
|---------|---------------------|-----------------|
| Data freshness | Build time | Request time |
| Performance | Fastest (static) | Depends on data source |
| Requires rebuild for updates | Yes | No |
| Error handling | Build fails on error | Result objects |
| Caching | Built into output | You control caching |
| Rendering mode | Static or SSR | SSR required |

## When to Use Live vs Standard Collections

### Use Standard Collections When

- Content changes infrequently (blog posts, docs, marketing pages)
- Build-time data is acceptable
- You want maximum performance
- You are deploying as a static site

### Use Live Collections When

- Data changes frequently (minutes or seconds)
- Stale data is unacceptable for the use case
- You are already using SSR
- The data source is an external API you do not control
- You need to show user-specific or session-specific content

## Caching Strategies

Since live collections fetch on every request, consider adding caching to avoid hitting rate limits or slowing down responses:

```typescript
let cache: { data: any; timestamp: number } | null = null;
const CACHE_TTL = 60_000; // 1 minute

const stockPrices = defineCollection({
  loader: {
    name: "stock-prices",
    load: async () => {
      const now = Date.now();
      if (cache && now - cache.timestamp < CACHE_TTL) {
        return cache.data;
      }

      const response = await fetch("https://api.example.com/stocks");
      const data = await response.json();
      const entries = data.map((stock: any) => ({
        id: stock.symbol,
        symbol: stock.symbol,
        price: stock.price,
        change: stock.change,
      }));

      cache = { data: entries, timestamp: now };
      return entries;
    },
  },
  schema: z.object({
    symbol: z.string(),
    price: z.number(),
    change: z.number(),
  }),
});
```

## Requirements

- **SSR mode required** — Live collections need server-side rendering since they fetch data at request time. They do not work with fully static builds.
- **Astro 6** — Live collections are stable in Astro 6. In Astro 5, they were behind an experimental flag.
