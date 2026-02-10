# Functional Programming in TypeScript

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Pure Functions](#pure-functions)
- [Immutability](#immutability)
- [Function Types and Overloads](#function-types-and-overloads)
- [Function Composition](#function-composition)
- [Higher-Order Functions](#higher-order-functions)
- [Currying](#currying)
- [Algebraic Data Types](#algebraic-data-types)
- [Type Classes (Protocol Witnesses)](#type-classes-protocol-witnesses)
- [Functional Core, Imperative Shell](#functional-core-imperative-shell)
- [Point-Free Style](#point-free-style)
- [Anti-Patterns](#anti-patterns)
- [When to Use](#when-to-use)
- [Summary](#summary)

## Overview

Pure functions, immutable data, function composition. Functional core, imperative shell.

## Core Principles

1. **Pure functions** - Same input → same output, no side effects
2. **Immutability** - Data never changes, create new values
3. **Composition** - Build complex from simple functions
4. **Explicit function types** - Make inputs and outputs clear

## Pure Functions

### Definition

```typescript
// ✅ Pure - deterministic, no side effects
const add = (a: number, b: number): number => a + b;

const multiply = (a: number, b: number): number => a * b;

// ❌ Impure - depends on external state
let total = 0;
const addToTotal = (n: number): number => {
  total += n; // SIDE EFFECT
  return total;
};

// ❌ Impure - non-deterministic
const now = (): Date => new Date(); // different each call
```

### Benefits

- **Testable** - No mocks, just input/output
- **Cacheable** - Same input = same output (memoization)
- **Parallelizable** - No shared state
- **Predictable** - Easy to reason about

## Immutability

> **Core patterns:** `readonly` properties, `readonly T[]` arrays, spread for updates. For full immutability guidance, use the `coding-typescript-core` skill.

### Deep Immutability

> For `DeepReadonly<T>` and deep immutability patterns, use the `coding-typescript-core` skill.

## Function Types and Overloads

Prefer concise function type expressions and let inference do the work. Use overloads only when unions can’t model the relationship between inputs and outputs.

```typescript
type Comparator<T> = (a: T, b: T) => number;

const byNumber: Comparator<number> = (a, b) => a - b;
```

When the return type depends on the input shape, overloads can be appropriate:

```typescript
function toArray(value: string): string[];
function toArray(value: number): number[];
function toArray(value: string | number): Array<string | number> {
  return [value];
}
```

Use a `this` parameter to model context-dependent functions:

```typescript
function once(this: { called: boolean }, fn: () => void): void {
  if (this.called) return;
  this.called = true;
  fn();
}
```

Prefer explicit optional and rest parameters over ambiguous positional arguments:

```typescript
function sumAll(...values: readonly number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
```

## Function Composition

### Pipe and Flow

```typescript
// Left-to-right composition (pipe)
const pipe = <A, B, C>(
  f: (a: A) => B,
  g: (b: B) => C
) => (a: A): C => g(f(a));

// Multi-function pipe
const pipe3 = <A, B, C, D>(
  f: (a: A) => B,
  g: (b: B) => C,
  h: (c: C) => D
) => (a: A): D => h(g(f(a)));

// Usage
const trim = (s: string): string => s.trim();
const uppercase = (s: string): string => s.toUpperCase();
const exclaim = (s: string): string => `${s}!`;

const shout = pipe3(trim, uppercase, exclaim);
shout("  hello  "); // "HELLO!"
```

### Function Composition Operator

```typescript
// Right-to-left (mathematical composition)
const compose = <A, B, C>(
  g: (b: B) => C,
  f: (a: A) => B
) => (a: A): C => g(f(a));

const len = (s: string): number => s.length;
const isEven = (n: number): boolean => n % 2 === 0;

const hasEvenLength = compose(isEven, len);
hasEvenLength("ab"); // true
```

## Higher-Order Functions

Functions that take/return functions:

```typescript
// Function that returns a function
const multiplyBy = (n: number) => (x: number): number => x * n;

const double = multiplyBy(2);
const triple = multiplyBy(3);

double(5); // 10
triple(5); // 15

// Function that takes a function
const twice = <A>(f: (a: A) => A) => (a: A): A => f(f(a));

const add1 = (n: number): number => n + 1;
const add2 = twice(add1);

add2(5); // 7
```

## Currying

```typescript
// Uncurried
const add = (a: number, b: number, c: number): number => a + b + c;

// Curried
const addCurried = (a: number) => (b: number) => (c: number): number =>
  a + b + c;

const add5 = addCurried(5);
const add5And10 = add5(10);
add5And10(3); // 18

// Partial application
const add5And = (b: number, c: number): number => add(5, b, c);
```

## Algebraic Data Types

### Option/Maybe

```typescript
type Option<T> =
  | { kind: "some"; value: T }
  | { kind: "none" };

const some = <T>(value: T): Option<T> => ({ kind: "some", value });
const none = <T>(): Option<T> => ({ kind: "none" });

const map = <A, B>(opt: Option<A>, f: (a: A) => B): Option<B> =>
  opt.kind === "some" ? some(f(opt.value)) : none();

const flatMap = <A, B>(opt: Option<A>, f: (a: A) => Option<B>): Option<B> =>
  opt.kind === "some" ? f(opt.value) : none();

const getOrElse = <A>(opt: Option<A>, defaultValue: A): A =>
  opt.kind === "some" ? opt.value : defaultValue;

// Usage
const divide = (a: number, b: number): Option<number> =>
  b === 0 ? none() : some(a / b);

const result = divide(10, 2); // { kind: "some", value: 5 }
const safe = divide(10, 0);   // { kind: "none" }

map(result, x => x * 2); // { kind: "some", value: 10 }
getOrElse(safe, 0); // 0
```

### Result/Either

```typescript
// Result<T, E> — see SKILL.md

const ok = <T, E = Error>(value: T): Result<T, E> => ({ ok: true, value });
const err = <T, E = Error>(error: E): Result<T, E> => ({ ok: false, error });

const mapResult = <T, U, E>(
  result: Result<T, E>,
  f: (t: T) => U
): Result<U, E> =>
  result.ok ? ok(f(result.value)) : result;

const flatMapResult = <T, U, E>(
  result: Result<T, E>,
  f: (t: T) => Result<U, E>
): Result<U, E> =>
  result.ok ? f(result.value) : result;

// Usage
const parseJSON = (s: string): Result<unknown> => {
  try {
    return ok(JSON.parse(s));
  } catch (e) {
    return err(e instanceof Error ? e : new Error(String(e)));
  }
};

const validateUser = (data: unknown): Result<User> =>
  isValidUser(data)
    ? ok(data) // type predicate narrows data to User
    : err(new Error("Invalid user"));

const result = flatMapResult(parseJSON('{"name":"Alice"}'), validateUser);
```

## Type Classes (Protocol Witnesses)

### Higher-Kinded Types

> **Note:** TypeScript lacks higher-kinded types, so a truly generic `Functor<F>` interface is not expressible. Use concrete implementations (like `mapResult`, `mapOption`) instead. Libraries like `fp-ts` use encoding tricks, but this adds complexity without compiler support.

### Monoid

```typescript
interface Monoid<A> {
  empty: A;
  concat(x: A, y: A): A;
}

const numberAddition: Monoid<number> = {
  empty: 0,
  concat: (x, y) => x + y
};

const stringConcatenation: Monoid<string> = {
  empty: "",
  concat: (x, y) => x + y
};

const arrayConcat = <T>(): Monoid<readonly T[]> => ({
  empty: [],
  concat: (x, y) => [...x, ...y]
});

// Generic fold using monoid
const fold = <A>(monoid: Monoid<A>, xs: readonly A[]): A =>
  xs.reduce(monoid.concat, monoid.empty);

fold(numberAddition, [1, 2, 3, 4]); // 10
fold(stringConcatenation, ["a", "b", "c"]); // "abc"
```

## Functional Core, Imperative Shell

Separate pure logic from side effects:

```typescript
// === CORE (Pure) ===
interface Order {
  readonly items: readonly Item[];
  readonly total: number;
}

const validateOrder = (order: Order): Result<Order> =>
  order.items.length > 0 && order.total > 0
    ? ok(order)
    : err(new Error("Invalid order"));

const calculateTotal = (items: readonly Item[]): number =>
  items.reduce((sum, item) => sum + item.price * item.quantity, 0);

const confirmOrder = (order: Order): Order => ({
  ...order,
  status: "confirmed"
});

// === SHELL (Side Effects) ===
class OrderService {
  constructor(
    private repo: OrderRepository,
    private email: EmailService
  ) {}

  async processOrder(orderId: string): Promise<Result<Order>> {
    // I/O: fetch
    const order = await this.repo.findById(orderId);
    if (!order) return err(new Error("Not found"));

    // Pure: validate
    const validated = validateOrder(order);
    if (!validated.ok) return validated;

    // Pure: transform
    const confirmed = confirmOrder(validated.value);

    // I/O: save and notify
    await this.repo.save(confirmed);
    await this.email.send(order.customerId, "Order confirmed");

    return ok(confirmed);
  }
}
```

## Point-Free Style

Functions defined without mentioning arguments:

```typescript
// Point-ful
const double = (x: number): number => x * 2;
const increment = (x: number): number => x + 1;

// Point-free (using composition)
const doubleAndIncrement = pipe(double, increment);

// Array operations
const sumOfSquares = pipe(
  (xs: number[]) => xs.map(x => x * x),
  xs => xs.reduce((a, b) => a + b, 0)
);
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Pure function | `(input: A) => B` (no side effects) | Business logic, transformations |
| Pipe/compose | `pipe(f, g)(x)` | Left-to-right function composition |
| Higher-order fn | `(fn: (a: A) => B) => ...` | Abstracting over behavior |
| Currying | `(a: A) => (b: B) => C` | Partial application, config injection |
| Option/Maybe | `{ kind: "some"; value: T } \| { kind: "none" }` | Representing absence without null |
| Result/Either | `{ ok: true; value: T } \| { ok: false; error: E }` | Type-safe error handling |
| Monoid | `{ empty: A; concat(x, y): A }` | Combining values with identity element |
| FP core / IO shell | Pure logic + class shell for I/O | Separating computation from effects |

## Anti-Patterns

### ❌ Mutation in "Functional" Code

```typescript
// BAD
const addItem = (cart: Cart, item: Item): Cart => {
  cart.items.push(item); // MUTATES
  return cart;
};

// GOOD
const addItem = (cart: Cart, item: Item): Cart => ({
  ...cart,
  items: [...cart.items, item]
});
```

### ❌ Side Effects in Business Logic

```typescript
// BAD
const validateUser = (user: User): boolean => {
  console.log("Validating user"); // SIDE EFFECT
  logToDatabase(user); // SIDE EFFECT
  return user.age >= 18;
};

// GOOD - pure function
const validateUser = (user: User): boolean =>
  user.age >= 18;

// Side effects in shell
const processUser = async (user: User): Promise<void> => {
  console.log("Processing user");
  if (validateUser(user)) {
    await logToDatabase(user);
  }
};
```

### ❌ Impure Higher-Order Functions

```typescript
// BAD
let counter = 0;
const withCounter = <A>(f: () => A) => (): A => {
  counter++; // SIDE EFFECT
  return f();
};

// GOOD
const withCounter = <A>(f: () => A) => (count: number): [A, number] => {
  return [f(), count + 1];
};
```

## When to Use

**Use FP when:**
- Business logic needs predictability
- Testing without mocks
- Concurrency/parallelism
- Complex transformations
- Undo/redo functionality

**Don't force FP for:**
- Simple imperative scripts
- I/O-heavy code (use shell pattern)
- Performance-critical mutations (use immutability at boundaries)

## Summary

- Pure functions for business logic
- Immutable data structures
- Compose small functions into larger ones
- Separate pure core from imperative shell
- Use ADTs (Option, Result) for error handling
- Type classes for polymorphic behavior
