// =============================================================================
// ArkType Validators — Common Patterns
//
// A starter file showing the most useful ArkType validator patterns.
// Copy what you need, delete the rest.
//
// Requires: npm install arktype
// =============================================================================

import { type } from "arktype";

// ---------------------------------------------------------------------------
// String validators
// ---------------------------------------------------------------------------

// Built-in format keywords — no regex needed
const Email = type("string.email");
const Url = type("string.url");
const Uuid = type("string.uuid.v4");

// Length constraints — use comparison operators directly on the type
const Username = type("3 <= string <= 20"); // between 3 and 20 characters
const NonEmpty = type("string > 0"); // at least 1 character

// Combine a format keyword with a constraint using intersection (&)
const ShortEmail = type("string.email & string < 100");

// Regex intersection — for patterns ArkType doesn't have a keyword for
const Slug = type("string & /^[a-z0-9]+(-[a-z0-9]+)*$/");

// ---------------------------------------------------------------------------
// Number validators
// ---------------------------------------------------------------------------

const Positive = type("number > 0");
const Percentage = type("0 <= number <= 100"); // inclusive range
const Integer = type("number.integer"); // whole numbers only
const Port = type("1 <= (number.integer) <= 65535"); // combined keyword + range
const Even = type("number % 2"); // divisible by 2

// ---------------------------------------------------------------------------
// Object with required, optional, and default properties
// ---------------------------------------------------------------------------

// "key?" makes it optional, "type = value" sets a default.
// Defaults are applied during validation — the output always has the field.
const UserProfile = type({
  name: "string > 0",
  email: "string.email",
  "bio?": "string < 500", // optional, at most 500 chars
  role: "'admin' | 'member' | 'guest' = 'member'", // default value
  "avatarUrl?": "string.url",
});

// TypeScript type is inferred automatically:
//   type UserProfile = { name: string; email: string; bio?: string; role: "admin" | "member" | "guest"; avatarUrl?: string }
type UserProfile = typeof UserProfile.infer;

// ---------------------------------------------------------------------------
// Arrays with length constraints
// ---------------------------------------------------------------------------

const Tags = type("string[] >= 1"); // non-empty array of strings
const TopFive = type("number[] <= 5"); // at most 5 numbers
const Matrix = type("number[][]"); // nested arrays

// ---------------------------------------------------------------------------
// Union types
// ---------------------------------------------------------------------------

// String syntax with pipe (|) — reads like TypeScript
const StringOrNumber = type("string | number");

// Union of objects — works as a discriminated union when objects share a key
const Shape = type(
  { kind: "'circle'", radius: "number > 0" },
  "|",
  { kind: "'rect'", width: "number > 0", height: "number > 0" }
);

// ---------------------------------------------------------------------------
// Morph — transform input during validation
// ---------------------------------------------------------------------------

// string.numeric.parse validates the string is numeric, then converts to number.
// Input: "42" (string)  ->  Output: 42 (number)
const NumericString = type("string.numeric.parse");

// Chain morphs: trim whitespace, then validate as email
const CleanEmail = type("string.trim").to("string.email");

// ---------------------------------------------------------------------------
// Branded type — compile-time nominal typing
// ---------------------------------------------------------------------------

// .brand() adds a compile-time tag so UserId and PostId are not interchangeable,
// even though both are strings at runtime.
const UserId = type("string.uuid.v4").brand("UserId");
const PostId = type("string.uuid.v4").brand("PostId");

type UserId = typeof UserId.infer; // string & { readonly __brand: "UserId" }
type PostId = typeof PostId.infer; // string & { readonly __brand: "PostId" }

// This prevents accidentally passing a PostId where a UserId is expected:
//   function getUser(id: UserId) { ... }
//   getUser(postId)  // TypeScript error

// ---------------------------------------------------------------------------
// Error handling pattern
// ---------------------------------------------------------------------------

function validateUser(data: unknown): UserProfile {
  const result = UserProfile(data);

  // ArkType returns the validated data on success, or an ArkErrors instance
  // on failure. Check with instanceof type.errors.
  if (result instanceof type.errors) {
    // result.summary gives a human-readable multi-line error description
    console.error("Validation failed:\n" + result.summary);

    // Iterate individual errors for structured handling
    for (const error of result) {
      console.error(`  Path: ${error.path.join(".")}`);
      console.error(`  Expected: ${error.expected}`);
      console.error(`  Actual: ${error.actual}`);
    }

    throw new Error("Invalid user data");
  }

  // result is now typed as UserProfile — safe to use
  return result;
}

export {
  Email,
  Url,
  Uuid,
  Username,
  NonEmpty,
  ShortEmail,
  Slug,
  Positive,
  Percentage,
  Integer,
  Port,
  Even,
  UserProfile,
  Tags,
  TopFive,
  Matrix,
  StringOrNumber,
  Shape,
  NumericString,
  CleanEmail,
  UserId,
  PostId,
  validateUser,
};
