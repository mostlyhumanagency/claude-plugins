# Rules, Red Flags, and Exceptions

Detailed TypeScript guidance referenced by `SKILL.md`.

## Core Rules

- Prefer inference; ban `any`. Use `unknown` at boundaries and validate.
- Immutability by default: `readonly`, `as const`, non-mutating updates.
- Contracts over classes: small interfaces + composition; classes only when necessary.
- Use `satisfies` to validate shapes without erasing inference.

## Red Flags

Review and justify if you see:

- `any` type (except during validation of `unknown`)
- Mutation (`.push`, in-place `.sort()`, `obj.prop =`) without a clear boundary or performance justification
- Type assertions (`as Type`, `!`) outside explicit boundary points
- Missing `readonly` on data where immutability is intended
- Truthy checks for nullish (`||` instead of `??`) when `0`/`""` are valid values

## Exceptions

`as` and `!` are allowed only at explicit boundaries or well-justified interoperability points. `as const` and `satisfies` are encouraged for inference and validation. Use a named boundary function and state the invariant.

Allow `any` only in tightly-scoped interop patterns where the standard library forces it (e.g., `Parameters<T>` or validator maps) and immediately wrap it with `unknown` or concrete types at the boundary.

### Mutability Exceptions (Explicit Criteria)

Mutability is allowed only when at least one of these criteria is true, and the boundary is documented:

- **Performance-critical hot path**: profiling shows immutable copies are a bottleneck. Keep mutation local and return immutable outputs.
- **Interop boundary**: a library API requires mutation (DOM, third-party SDKs). Convert to immutable domain types immediately after.
- **Temporary builder**: use local mutable builders inside a function to construct an immutable result.
- **Stateful identity/lifecycle**: class instances with encapsulated internal mutation (e.g., caches, connection pools), exposing immutable public interfaces.

If none apply, default to immutable updates.

### `any` Exceptions (Explicit Criteria)

`any` is allowed only when the API surface cannot be expressed otherwise and is immediately contained:

- **Type-level constraints**: e.g., `Parameters<T>`, variadic tuple helpers, or complex mapped types.
- **Interop shims**: boundary adapters for untyped libraries.

In all cases: wrap `any` into `unknown` or a concrete type at the boundary and keep the `any` scope minimal.

## Quick Reference

- **Boundary rule:** `unknown` in, validate, `Result<T>` out.
- **Immutability:** `readonly` on properties + `readonly T[]` for collections.
- **Assertions:** prefer `satisfies` / type predicates; avoid `as` and `!`.
- **Errors:** use `Result<T, E>` and discriminated unions.
- **Classes:** only for identity/lifecycle/encapsulation; prefer interfaces.

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```

## Common Mistakes

**Using `any` instead of `unknown` at boundaries (TS7006, TS2345)** — `any` disables type checking entirely. Use `unknown` and validate before use.

**Mutating readonly data (TS2540)** — `Cannot assign to 'x' because it is a read-only property`. Use spread/copy to create new values instead of mutating.

**Missing null check after indexed access (TS18048)** — With `noUncheckedIndexedAccess`, `array[i]` is `T | undefined`. Check for undefined before using.

**Using `||` instead of `??` for defaults** — `value || fallback` fails when `value` is `0` or `""`. Use `??` which only triggers on `null`/`undefined`.

**Forgetting `satisfies` for shape validation (TS2741)** — Assigning to a type annotation erases literal inference. Use `satisfies` to validate shape while preserving narrow types.
