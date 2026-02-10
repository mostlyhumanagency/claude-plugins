// =============================================================================
// ArkType + Fastify — Request Validation Plugin
//
// A Fastify plugin that validates body, querystring, and params using ArkType
// types. Errors are formatted to match Fastify's standard error response shape.
//
// Requires: npm install arktype fastify
// =============================================================================

import Fastify, {
  type FastifyInstance,
  type FastifyRequest,
  type FastifyReply,
  type FastifyPluginCallback,
} from "fastify";
import { type, type Type } from "arktype";

// ---------------------------------------------------------------------------
// Validation schema interface
// ---------------------------------------------------------------------------

// Define which parts of the request to validate.
// Each field is optional — only the ones you provide will be checked.
interface ArkTypeSchema {
  body?: Type;
  querystring?: Type;
  params?: Type;
}

// ---------------------------------------------------------------------------
// Plugin: arktype-validation
// ---------------------------------------------------------------------------

// This plugin adds a preValidation hook that reads the `arktypeSchema`
// property from the route config and validates accordingly.

const arktypeValidation: FastifyPluginCallback = (fastify, _opts, done) => {
  fastify.addHook(
    "preValidation",
    async (request: FastifyRequest, reply: FastifyReply) => {
      // Route-level schema is stored in routeOptions.config
      const schema = (request.routeOptions?.config as { arktypeSchema?: ArkTypeSchema })
        ?.arktypeSchema;

      if (!schema) return; // no schema attached — skip validation

      // Validate each target that has a schema defined
      const targets = [
        { name: "body", data: request.body, type: schema.body },
        { name: "querystring", data: request.query, type: schema.querystring },
        { name: "params", data: request.params, type: schema.params },
      ] as const;

      for (const target of targets) {
        if (!target.type) continue;

        const result = target.type(target.data);

        if (result instanceof type.errors) {
          // Format errors to match Fastify's standard error response shape:
          //   { statusCode, error, message, validation? }
          const validation = result.map((e) => ({
            path: e.path.join("."),
            expected: e.expected,
            actual: e.actual,
            message: e.message,
          }));

          reply.status(422).send({
            statusCode: 422,
            error: "Unprocessable Entity",
            message: result.summary,
            validation,
          });
          return;
        }

        // Replace raw input with validated (and morphed) data.
        // This ensures downstream handlers receive transformed values
        // (e.g., "string.numeric.parse" fields become actual numbers).
        if (target.name === "body") {
          request.body = result;
        } else if (target.name === "querystring") {
          (request as Record<string, unknown>).query = result;
        } else if (target.name === "params") {
          (request as Record<string, unknown>).params = result;
        }
      }
    }
  );

  done();
};

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
  page: "string.integer.parse = '1'",
  limit: "string.integer.parse = '20'",
});

const IdParams = type({
  id: "string.uuid.v4",
});

// ---------------------------------------------------------------------------
// App setup
// ---------------------------------------------------------------------------

const app = Fastify({ logger: true });

// Register the plugin — this enables ArkType validation for all routes
app.register(arktypeValidation);

// ---------------------------------------------------------------------------
// POST /users — validate body
// ---------------------------------------------------------------------------

app.post(
  "/users",
  {
    config: {
      arktypeSchema: { body: CreateUserBody },
    },
  },
  async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.body as typeof CreateUserBody.infer;
    return reply.status(201).send({ id: crypto.randomUUID(), ...user });
  }
);

// ---------------------------------------------------------------------------
// GET /users — validate querystring
// ---------------------------------------------------------------------------

app.get(
  "/users",
  {
    config: {
      arktypeSchema: { querystring: PaginationQuery },
    },
  },
  async (request: FastifyRequest) => {
    const { page, limit } = request.query as typeof PaginationQuery.infer;
    return { page, limit, data: [] };
  }
);

// ---------------------------------------------------------------------------
// GET /users/:id — validate params
// ---------------------------------------------------------------------------

app.get(
  "/users/:id",
  {
    config: {
      arktypeSchema: { params: IdParams },
    },
  },
  async (request: FastifyRequest) => {
    const { id } = request.params as typeof IdParams.infer;
    return { id, name: "Ada Lovelace" };
  }
);

// ---------------------------------------------------------------------------
// Example error response (422)
// ---------------------------------------------------------------------------
//
// POST /users with body: { "name": "", "email": "bad" }
//
// {
//   "statusCode": 422,
//   "error": "Unprocessable Entity",
//   "message": "name must be more than 0 characters (was 0)\nemail must be an email address (was \"bad\")",
//   "validation": [
//     { "path": "name", "expected": "more than 0 characters", "actual": "0", "message": "..." },
//     { "path": "email", "expected": "an email address", "actual": "\"bad\"", "message": "..." }
//   ]
// }

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

app.listen({ port: 3000 }, (err) => {
  if (err) {
    app.log.error(err);
    process.exit(1);
  }
});

// ---------------------------------------------------------------------------
// Helper for inline route schemas (alternative to config object)
// ---------------------------------------------------------------------------

function withSchema(schema: ArkTypeSchema) {
  return { config: { arktypeSchema: schema } };
}

// Usage with the helper — less nesting than the config object:
//   app.post("/users", withSchema({ body: CreateUserBody }), handler)

export { arktypeValidation, withSchema };
export type { ArkTypeSchema };
