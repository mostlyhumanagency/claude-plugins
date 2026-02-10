// =============================================================================
// ArkType Scope — Shared Type Definitions
//
// A scope groups related types that can reference each other by name.
// Use scopes when you have interconnected domain types (User -> Post -> Comment).
//
// Requires: npm install arktype
// =============================================================================

import { scope, type } from "arktype";

// ---------------------------------------------------------------------------
// Define the scope
// ---------------------------------------------------------------------------

// scope() creates a namespace of types that can cross-reference each other.
// Types are resolved lazily, so declaration order does not matter.
const $ = scope({
  // -- Shared primitives (reusable building blocks) -------------------------

  Id: "string.uuid.v4",
  Email: "string.email",
  Timestamp: "string.date.iso",

  // -- Private alias (prefixed with #) --------------------------------------
  // Private aliases are available inside the scope but excluded from export.
  // Use them for internal helpers that consumers should not access directly.
  "#Metadata": {
    createdAt: "Timestamp",
    updatedAt: "Timestamp",
  },

  // -- Object types referencing shared aliases ------------------------------

  User: {
    id: "Id",
    email: "Email",
    name: "string > 0",
    "bio?": "string < 500",
    "...": "#Metadata", // spread the private Metadata fields into User
  },

  Post: {
    id: "Id",
    authorId: "Id",
    title: "1 <= string <= 200",
    body: "string > 0",
    tags: "string[] <= 10",
    "...": "#Metadata",
  },

  // -- Cyclic type ----------------------------------------------------------
  // Comments can have nested replies, forming a tree structure.
  // ArkType handles this automatically — just reference the type by name.
  Comment: {
    id: "Id",
    authorId: "Id",
    body: "string > 0",
    "replies?": "Comment[]", // self-referential — creates a recursive type
    "...": "#Metadata",
  },
});

// ---------------------------------------------------------------------------
// Export the module
// ---------------------------------------------------------------------------

// .export() returns a module object where each key is a callable Type.
// Private aliases (#Metadata) are excluded from the export.
const types = $.export();

// The exported module has these types:
//   types.Id        — Type<string>
//   types.Email     — Type<string>
//   types.Timestamp — Type<string>
//   types.User      — Type<{ id: string; email: string; ... }>
//   types.Post      — Type<{ id: string; authorId: string; ... }>
//   types.Comment   — Type<{ id: string; authorId: string; ... }>

// Extract TypeScript types for use in your application code
type User = typeof types.User.infer;
type Post = typeof types.Post.infer;
type Comment = typeof types.Comment.infer;

// ---------------------------------------------------------------------------
// Usage examples
// ---------------------------------------------------------------------------

// Validate a user
const userData = {
  id: "550e8400-e29b-41d4-a716-446655440000",
  email: "ada@example.com",
  name: "Ada Lovelace",
  createdAt: "2024-01-15T10:30:00.000Z",
  updatedAt: "2024-06-20T14:00:00.000Z",
};

const user = types.User(userData);
if (user instanceof type.errors) {
  console.error(user.summary);
} else {
  console.log("Valid user:", user.name);
}

// Validate a comment tree (cyclic type in action)
const commentData = {
  id: "550e8400-e29b-41d4-a716-446655440001",
  authorId: "550e8400-e29b-41d4-a716-446655440000",
  body: "Great post!",
  createdAt: "2024-01-16T08:00:00.000Z",
  updatedAt: "2024-01-16T08:00:00.000Z",
  replies: [
    {
      id: "550e8400-e29b-41d4-a716-446655440002",
      authorId: "550e8400-e29b-41d4-a716-446655440000",
      body: "Thanks!",
      createdAt: "2024-01-16T09:00:00.000Z",
      updatedAt: "2024-01-16T09:00:00.000Z",
      // replies can nest arbitrarily deep
    },
  ],
};

const comment = types.Comment(commentData);
if (comment instanceof type.errors) {
  console.error(comment.summary);
} else {
  console.log(`Comment has ${comment.replies?.length ?? 0} replies`);
}

export { types, $ };
export type { User, Post, Comment };
