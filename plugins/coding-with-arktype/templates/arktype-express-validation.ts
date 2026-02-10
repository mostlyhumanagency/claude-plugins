// =============================================================================
// ArkType + Express — Request Validation Middleware
//
// A validate() factory that wraps any ArkType Type into Express middleware.
// Validates body, query, or params and returns structured JSON errors (422).
//
// Requires: npm install arktype express
//           npm install -D @types/express
// =============================================================================

import express, { type Request, type Response, type NextFunction } from "express";
import { type, type Type } from "arktype";

// ---------------------------------------------------------------------------
// Middleware factory
// ---------------------------------------------------------------------------

// Which part of the request to validate
type Target = "body" | "query" | "params";

/**
 * Creates Express middleware that validates a request target against an ArkType Type.
 *
 * On success: replaces req[target] with the validated (and possibly morphed) data,
 *             then calls next().
 * On failure: responds with 422 and a structured JSON error body.
 */
function validate<T>(schema: Type<T>, target: Target = "body") {
  return (req: Request, res: Response, next: NextFunction): void => {
    const data = req[target];
    const result = schema(data);

    if (result instanceof type.errors) {
      // Format errors as a structured JSON response.
      // Each error includes the path, expected type, and actual value.
      const errors = result.map((e) => ({
        path: e.path.join("."),
        message: e.message,
        expected: e.expected,
        actual: e.actual,
      }));

      res.status(422).json({
        status: 422,
        message: "Validation failed",
        errors,
      });
      return;
    }

    // Replace the raw input with validated (and morphed) data.
    // For example, "string.numeric.parse" fields are now actual numbers.
    (req as Record<string, unknown>)[target] = result;
    next();
  };
}

// ---------------------------------------------------------------------------
// Schema definitions
// ---------------------------------------------------------------------------

const CreateUserBody = type({
  name: "string > 0",
  email: "string.email",
  "age?": "number.integer > 0",
  role: "'admin' | 'member' = 'member'",
});

const PaginationQuery = type({
  page: "string.integer.parse = '1'", // query params are always strings
  limit: "string.integer.parse = '20'",
});

const IdParams = type({
  id: "string.uuid.v4",
});

// ---------------------------------------------------------------------------
// App setup
// ---------------------------------------------------------------------------

const app = express();
app.use(express.json());

// POST /users — validate JSON body
app.post("/users", validate(CreateUserBody, "body"), (req: Request, res: Response) => {
  // req.body is now typed and validated
  const user = req.body as typeof CreateUserBody.infer;
  res.status(201).json({ id: crypto.randomUUID(), ...user });
});

// GET /users — validate query params (page, limit parsed to numbers)
app.get("/users", validate(PaginationQuery, "query"), (req: Request, res: Response) => {
  const { page, limit } = req.query as unknown as typeof PaginationQuery.infer;
  res.json({ page, limit, data: [] });
});

// GET /users/:id — validate route params
app.get("/users/:id", validate(IdParams, "params"), (req: Request, res: Response) => {
  const { id } = req.params as typeof IdParams.infer;
  res.json({ id, name: "Ada Lovelace" });
});

// ---------------------------------------------------------------------------
// Example error response (422)
// ---------------------------------------------------------------------------
//
// POST /users with body: { "name": "", "email": "not-an-email" }
//
// {
//   "status": 422,
//   "message": "Validation failed",
//   "errors": [
//     {
//       "path": "name",
//       "message": "must be more than 0 characters (was 0)",
//       "expected": "more than 0 characters",
//       "actual": "0"
//     },
//     {
//       "path": "email",
//       "message": "must be an email address (was \"not-an-email\")",
//       "expected": "an email address",
//       "actual": "\"not-an-email\""
//     }
//   ]
// }

app.listen(3000, () => console.log("Listening on :3000"));

export { validate, CreateUserBody, PaginationQuery, IdParams };
