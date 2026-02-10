# Runtime Type Validation in TypeScript

## Table of Contents

- [The Problem](#the-problem)
- [Type Guards](#type-guards)
- [Validation with Result Types](#validation-with-result-types)
- [Zod (Recommended Library)](#zod-recommended-library)
- [Manual Validation Builder](#manual-validation-builder)
- [API Response Validation](#api-response-validation)
- [Form Validation](#form-validation)
- [Assertion Functions](#assertion-functions)
- [Error Subclasses](#error-subclasses)
- [Summary](#summary)

Type-safe validation bridging compile-time and runtime.

## The Problem

TypeScript types are compile-time only:

```typescript
interface User {
  name: string;
  age: number;
}

const data: unknown = JSON.parse(input);
const user = data as User; // ❌ UNSAFE - no runtime check!
```

## Type Guards

### Basic Type Guards

```typescript
function isString(value: unknown): value is string {
  return typeof value === 'string';
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number';
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
```

### Discriminated Union Guards

```typescript
// Result<T, E> — see SKILL.md

function isOk<T, E>(result: Result<T, E>): result is { ok: true; value: T } {
  return result.ok === true;
}

function isErr<T, E>(result: Result<T, E>): result is { ok: false; error: E } {
  return result.ok === false;
}

// Usage
if (isOk(result)) {
  console.log(result.value); // ✅ narrowed
} else {
  console.error(result.error); // ✅ narrowed
}
```

### Object Shape Validation

```typescript
interface User {
  name: string;
  age: number;
  email: string;
}

function isUser(value: unknown): value is User {
  if (!isObject(value)) return false;

  return (
    'name' in value && isString(value.name) &&
    'age' in value && isNumber(value.age) &&
    'email' in value && isString(value.email)
  );
}

// Usage
const data: unknown = JSON.parse(input);
if (isUser(data)) {
  console.log(data.name); // ✅ type-safe
}
```

## Validation with Result Types

```typescript
type ValidationError = {
  field: string;
  message: string;
};

type ValidationResult<T> = Result<T, ValidationError[]>;

function validateUser(data: unknown): ValidationResult<User> {
  const errors: ValidationError[] = [];

  if (!isObject(data)) {
    return { ok: false, error: [{ field: 'root', message: 'Must be an object' }] };
  }

  if (!('name' in data) || !isString(data.name)) {
    errors.push({ field: 'name', message: 'Name must be a string' });
  }

  if (!('age' in data) || !isNumber(data.age)) {
    errors.push({ field: 'age', message: 'Age must be a number' });
  } else if (data.age < 0) {
    errors.push({ field: 'age', message: 'Age must be positive' });
  }

  if (!('email' in data) || !isString(data.email)) {
    errors.push({ field: 'email', message: 'Email must be a string' });
  } else if (!data.email.includes('@')) {
    errors.push({ field: 'email', message: 'Email must be valid' });
  }

  if (errors.length > 0) {
    return { ok: false, error: errors };
  }

  // Use type guard — fields already validated individually above
  if (isUser(data)) {
    return { ok: true, value: data };
  }
  return { ok: false, error: [{ field: 'root', message: 'Validation failed' }] };
}
```

## Zod (Recommended Library)

```typescript
import { z } from 'zod';

// Define schema (acts as both type and validator)
const UserSchema = z.object({
  name: z.string(),
  age: z.number().int().positive(),
  email: z.string().email(),
  tags: z.array(z.string()).optional()
});

// Infer TypeScript type from schema
type User = z.infer<typeof UserSchema>;

// Validate
const result = UserSchema.safeParse(data);

if (result.success) {
  const user: User = result.data; // ✅ type-safe
} else {
  console.error(result.error.format());
}

// Or throw on invalid
const user = UserSchema.parse(data); // throws ZodError if invalid
```

### Complex Schemas

```typescript
const AddressSchema = z.object({
  street: z.string(),
  city: z.string(),
  zipCode: z.string().regex(/^\d{5}$/),
});

const ProfileSchema = z.object({
  user: UserSchema,
  address: AddressSchema,
  preferences: z.record(z.string(), z.boolean()),
  metadata: z.record(z.unknown()).optional()
});

// Refinements
const PasswordSchema = z.string()
  .min(8, "Must be at least 8 characters")
  .refine(
    (val) => /[A-Z]/.test(val),
    "Must contain uppercase letter"
  )
  .refine(
    (val) => /[0-9]/.test(val),
    "Must contain number"
  );

// Transforms
const DateSchema = z.string().transform((str) => new Date(str));

// Discriminated unions
const EventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('keypress'), key: z.string() })
]);
```

## Manual Validation Builder

```typescript
type Validator<T> = (value: unknown) => ValidationResult<T>;

function string(): Validator<string> {
  return (value) =>
    typeof value === 'string'
      ? { ok: true, value }
      : { ok: false, error: [{ field: 'value', message: 'Must be string' }] };
}

function number(): Validator<number> {
  return (value) =>
    typeof value === 'number'
      ? { ok: true, value }
      : { ok: false, error: [{ field: 'value', message: 'Must be number' }] };
}

// The `any` in Validator<any> mirrors TS stdlib constraints (e.g., Parameters<T>)
function object<T extends Record<string, Validator<any>>>(
  schema: T
): Validator<{ [K in keyof T]: T[K] extends Validator<infer U> ? U : never }> {
  return (value) => {
    if (!isObject(value)) {
      return { ok: false, error: [{ field: 'root', message: 'Must be object' }] };
    }

    const result: Record<string, unknown> = {};
    const errors: ValidationError[] = [];

    for (const [key, validator] of Object.entries(schema)) {
      if (!(key in value)) {
        errors.push({ field: key, message: 'Required field missing' });
        continue;
      }

      const fieldResult = validator(value[key]);
      if (fieldResult.ok) {
        result[key] = fieldResult.value;
      } else {
        errors.push(...fieldResult.error);
      }
    }

    return errors.length > 0
      ? { ok: false, error: errors }
      : { ok: true, value: result };
  };
}

// Usage
const userValidator = object({
  name: string(),
  age: number()
});

const result = userValidator({ name: "Alice", age: 30 });
```

## API Response Validation

```typescript
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);

    if (!response.ok) {
      return { ok: false, error: new Error(`HTTP ${response.status}`) };
    }

    const data: unknown = await response.json();

    // Validate response shape
    const validated = validateUser(data);
    if (!validated.ok) {
      return { ok: false, error: new Error('Invalid response') };
    }

    return { ok: true, value: validated.value };
  } catch (error) {
    if (error instanceof Error) {
      return { ok: false, error };
    }
    return { ok: false, error: new Error('Unknown error') };
  }
}
```

## Form Validation

```typescript
interface LoginForm {
  email: string;
  password: string;
}

const LoginSchema = z.object({
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "Password too short")
});

type FormErrors = Record<string, string>;

function validateForm<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { valid: true; data: T } | { valid: false; errors: FormErrors } {
  const result = schema.safeParse(data);

  if (result.success) {
    return { valid: true, data: result.data };
  }

  const errors: FormErrors = {};
  for (const err of result.error.errors) {
    const field = String(err.path[0]);
    errors[field] = err.message;
  }

  return { valid: false, errors };
}

// Usage
const formData = { email: "invalid", password: "short" };
const result = validateForm(LoginSchema, formData);

if (result.valid) {
  console.log(result.data);
} else {
  console.error(result.errors); // { email: "Invalid email", password: "Password too short" }
}
```

## Assertion Functions

Narrow types imperatively — throw on failure, narrow on success:

```typescript
function assertUser(value: unknown): asserts value is User {
  if (!isObject(value)) throw new ValidationError("root", "Must be an object");
  if (!('name' in value) || typeof value.name !== 'string')
    throw new ValidationError("name", "Must be a string");
  if (!('age' in value) || typeof value.age !== 'number')
    throw new ValidationError("age", "Must be a number");
  if (!('email' in value) || typeof value.email !== 'string')
    throw new ValidationError("email", "Must be a string");
}

// Usage — value is narrowed after the call
const data: unknown = JSON.parse(input);
assertUser(data);
data.name; // ✅ string — narrowed by assertion
```

Use assertion functions when you want to throw on invalid data (e.g., startup config). Use type guards returning `boolean` or Result when callers should handle the failure.

## Error Subclasses

Typed error hierarchies for catch discrimination:

```typescript
class AppError extends Error {
  constructor(message: string, readonly code: string) {
    super(message);
    this.name = "AppError";
  }
}

class ValidationError extends AppError {
  constructor(readonly field: string, message: string) {
    super(message, "VALIDATION_ERROR");
    this.name = "ValidationError";
  }
}

class NotFoundError extends AppError {
  constructor(readonly resource: string, readonly id: string) {
    super(`${resource} ${id} not found`, "NOT_FOUND");
    this.name = "NotFoundError";
  }
}

// Catch discrimination
try { /* ... */ } catch (error) {
  if (error instanceof ValidationError) {
    console.error(`Field ${error.field}: ${error.message}`);
  } else if (error instanceof NotFoundError) {
    console.error(`Missing: ${error.resource} ${error.id}`);
  } else if (error instanceof Error) {
    console.error(error.message);
  }
}
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Type guard | `(x: unknown): x is T` | Narrowing unknown to a known type |
| Assertion function | `asserts value is T` | Fail-fast validation that narrows on success |
| Zod schema | `z.object({ ... })` | Declarative schema validation with inferred types |
| safeParse | `schema.safeParse(data)` | Validation that returns Result instead of throwing |
| z.infer | `type T = z.infer<typeof Schema>` | Deriving TS type from Zod schema |
| Result pattern | `{ ok: true; value: T } \| { ok: false; error: E }` | Type-safe error handling without exceptions |
| Discriminated union guard | `result.ok === true` | Narrowing Result or similar tagged unions |

## Common Mistakes

**Casting unknown with `as` (TS2352)** — `data as User` is unsafe; it skips runtime validation. Use a type guard or Zod schema instead.

**Type guard returning wrong predicate** — A `value is User` guard that doesn't check all fields causes unsound narrowing. Validate every required field.

**Forgetting `.safeParse()` error handling** — `.parse()` throws on invalid data. Use `.safeParse()` and check `result.success` when you want to handle errors gracefully.

**Not validating at system boundaries** — Trusting `JSON.parse()` output or API responses without validation leads to runtime crashes. Always validate `unknown` data from external sources.

## Summary

- TypeScript types don't exist at runtime
- Use type guards for runtime validation
- Return Result types for validation errors
- Use assertion functions (`asserts value is T`) for fail-fast validation
- Use error subclasses with `instanceof` for typed catch blocks
- Use Zod for declarative schema validation
- Validate all external data (API responses, user input, JSON.parse)
- Never use `as` to cast unvalidated data
