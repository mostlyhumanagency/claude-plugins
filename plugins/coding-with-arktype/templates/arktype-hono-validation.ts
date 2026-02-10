// =============================================================================
// ArkType + Hono — Request Validation
//
// Hono has first-party ArkType support via @hono/arktype-validator.
// The validator middleware validates the request and passes typed data
// to the handler via c.req.valid().
//
// Requires: npm install arktype hono @hono/arktype-validator
// =============================================================================

import { Hono } from "hono";
import { arktypeValidator } from "@hono/arktype-validator";
import { type } from "arktype";

// ---------------------------------------------------------------------------
// Schema definitions
// ---------------------------------------------------------------------------

const CreateUser = type({
  name: "string > 0",
  email: "string.email",
  "age?": "number.integer > 0",
  role: "'admin' | 'member' = 'member'",
});

const SearchQuery = type({
  q: "string > 0",
  "page?": "string.integer.parse", // parsed from string to number
  "limit?": "string.integer.parse",
});

const IdParam = type({
  id: "string.uuid.v4",
});

// ---------------------------------------------------------------------------
// App setup
// ---------------------------------------------------------------------------

const app = new Hono();

// ---------------------------------------------------------------------------
// POST /users — validate JSON body
// ---------------------------------------------------------------------------
// "json" tells the validator to read from the request body (c.req.json()).
// On success, the validated data is available via c.req.valid("json").

app.post(
  "/users",
  arktypeValidator("json", CreateUser, (result, c) => {
    // Optional error hook — customizes the error response.
    // If omitted, @hono/arktype-validator returns a default 400 response.
    if (result.success === false) {
      return c.json(
        {
          status: 422,
          message: "Validation failed",
          errors: result.errors.map((e) => ({
            path: e.path.join("."),
            expected: e.expected,
            actual: e.actual,
          })),
        },
        422
      );
    }
  }),
  (c) => {
    // result.data is fully typed as CreateUser's output
    const user = c.req.valid("json");
    return c.json({ id: crypto.randomUUID(), ...user }, 201);
  }
);

// ---------------------------------------------------------------------------
// GET /search?q=...&page=1&limit=20 — validate query params
// ---------------------------------------------------------------------------
// "query" reads from the URL search params.

app.get(
  "/search",
  arktypeValidator("query", SearchQuery, (result, c) => {
    if (result.success === false) {
      return c.json(
        { status: 400, message: "Invalid query parameters" },
        400
      );
    }
  }),
  (c) => {
    const { q, page, limit } = c.req.valid("query");
    return c.json({ query: q, page: page ?? 1, limit: limit ?? 20, results: [] });
  }
);

// ---------------------------------------------------------------------------
// GET /users/:id — validate route params
// ---------------------------------------------------------------------------
// "param" reads from the route parameters.

app.get(
  "/users/:id",
  arktypeValidator("param", IdParam, (result, c) => {
    if (result.success === false) {
      return c.json({ status: 400, message: "Invalid user ID" }, 400);
    }
  }),
  (c) => {
    const { id } = c.req.valid("param");
    return c.json({ id, name: "Ada Lovelace" });
  }
);

// ---------------------------------------------------------------------------
// Start the server
// ---------------------------------------------------------------------------

export default app;

// For Node.js (not needed for Cloudflare Workers / Bun / Deno):
// import { serve } from "@hono/node-server";
// serve({ fetch: app.fetch, port: 3000 });
