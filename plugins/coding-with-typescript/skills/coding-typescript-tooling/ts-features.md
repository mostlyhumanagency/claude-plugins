# TypeScript 5.x Language Features

Modern TypeScript features introduced in versions 5.5 through 5.9, plus earlier 5.x features referenced by this skill. Load this file when using version-specific features or migrating to newer TypeScript versions.

## Table of Contents

- [TypeScript 5.0](#typescript-50)
  - [`const` Type Parameters](#const-type-parameters-50)
- [TypeScript 5.2](#typescript-52)
  - [Resource Management: `using`](#resource-management-using-52)
- [TypeScript 5.5](#typescript-55)
  - [Inferred Type Predicates](#inferred-type-predicates-55)
  - [Control Flow Narrowing for Indexed Access](#control-flow-narrowing-for-indexed-access-55)
  - [Regular Expression Syntax Checking](#regular-expression-syntax-checking-55)
  - [ECMAScript Set Methods](#ecmascript-set-methods-55)
- [TypeScript 5.6](#typescript-56)
  - [Iterator Helpers](#iterator-helpers-56)
  - [Nullish and Truthy Checks](#nullish-and-truthy-checks-56)
- [TypeScript 5.7](#typescript-57)
  - [Never-Initialized Variables](#never-initialized-variables-57)
  - [Validated JSON Imports](#validated-json-imports-57)
- [TypeScript 5.8](#typescript-58)
  - [Granular Return Expression Checks](#granular-return-expression-checks-58)
- [TypeScript 5.9](#typescript-59)
  - [Import Defer](#import-defer-59)

---

## TypeScript 5.0

### `const` Type Parameters (5.0+)

Infer literal types from generic arguments without requiring `as const` at call site:

```typescript
// Without const: T inferred as string[]
function createRoute<T extends readonly string[]>(parts: T) {
  return parts.join("/");
}
createRoute(["api", "users"]); // T = string[]

// With const: T inferred as readonly ["api", "users"]
function createRoute<const T extends readonly string[]>(parts: T): string {
  return `/${parts.join("/")}`;
}
createRoute(["api", "users"]); // T = readonly ["api", "users"]
```

---

## TypeScript 5.2

### Resource Management: `using` (5.2+)

Deterministic cleanup with `Symbol.dispose`:

```typescript
class TempFile implements Disposable {
  readonly path: string;

  constructor(prefix: string) {
    this.path = `/tmp/${prefix}_${Date.now()}`;
  }

  [Symbol.dispose](): void {
    fs.unlinkSync(this.path);
  }
}

function processData() {
  using tempFile = new TempFile("data");
  fs.writeFileSync(tempFile.path, "content");
  // tempFile automatically cleaned up when scope exits
}

// Async version
class DbConnection implements AsyncDisposable {
  async [Symbol.asyncDispose](): Promise<void> {
    await this.close();
  }
}

async function query() {
  await using conn = new DbConnection();
  return conn.execute("SELECT 1");
  // conn.close() called automatically
}
```

---

## TypeScript 5.5

### Inferred Type Predicates (5.5+)

Compiler automatically infers type guards without explicit type predicate annotations.

```typescript
// Before 5.5: Manual type predicate
const isNumber = (x: unknown): x is number => typeof x === 'number';

// 5.5+: Inferred automatically
const isNumber = (x: unknown) => typeof x === 'number';
// Type inferred: (x: unknown) => x is number

// Works with filter
const mixed = [1, "two", 3, "four"];
const numbers = mixed.filter(isNumber);  // Type: number[]
```

**Use when:**
- Writing type guard functions
- Filtering arrays by type
- Simplifying validation code

**Benefits:**
- Less boilerplate
- Type predicates inferred from implementation
- Still provides full type narrowing

### Control Flow Narrowing for Indexed Access (5.5+)

TypeScript narrows types for constant indexed accesses.

```typescript
function process(obj: Record<string, unknown>, key: string) {
  if (typeof obj[key] === "string") {
    return obj[key].toUpperCase();  // ✅ TypeScript knows it's string
  }

  if (typeof obj[key] === "number") {
    return obj[key].toFixed(2);  // ✅ TypeScript knows it's number
  }
}

// Works with nested access
function hasKey<K extends string>(
  obj: unknown,
  key: K
): obj is Record<K, unknown> {
  return typeof obj === 'object' && obj !== null && key in obj;
}

function getNestedValue(data: Record<string, unknown>, path: string[]) {
  let current: unknown = data;

  for (const key of path) {
    if (hasKey(current, key)) {
      current = current[key];
    } else {
      return undefined;
    }
  }

  return current;
}
```

**Use when:**
- Working with dynamic object keys
- Processing records with unknown structure
- Implementing property access utilities

### Regular Expression Syntax Checking (5.5+)

TypeScript validates regex syntax at compile time.

```typescript
// ❌ Compile-time error
let regex = /@robot(\s+(please|immediately)))? do task/;
// Error: Unexpected ')'. Did you mean to escape it with backslash?

// ✅ Fixed
let regex = /@robot(\s+(please|immediately))? do task/;

// Catches common mistakes
let bad1 = /[z-a]/;  // Error: Range out of order in character class
let bad2 = /(?<name>test) \k<nam>/;  // Error: No group named 'nam'

// Even in template strings
const pattern = new RegExp(`\\d{${count}}`);  // Validated!
```

**Use when:**
- Writing regex patterns
- Building regex from strings
- Want early error detection

**Benefits:**
- Catch typos before runtime
- Better error messages than "invalid regex"
- Works with RegExp constructor

### ECMAScript Set Methods (5.5+)

New Set methods for union, intersection, difference, and subset operations.

```typescript
const fruits = new Set(["apple", "banana", "orange"]);
const citrus = new Set(["orange", "lemon", "lime"]);

// Union: All items from both sets
const allFruits = fruits.union(citrus);
// Set(5) { "apple", "banana", "orange", "lemon", "lime" }

// Intersection: Items in both sets
const commonFruits = fruits.intersection(citrus);
// Set(1) { "orange" }

// Difference: Items in first set but not second
const nonCitrus = fruits.difference(citrus);
// Set(2) { "apple", "banana" }

// Symmetric Difference: Items in either set but not both
const uniqueFruits = fruits.symmetricDifference(citrus);
// Set(4) { "apple", "banana", "lemon", "lime" }

// Subset checks
citrus.isSubsetOf(allFruits);  // true
fruits.isSubsetOf(citrus);  // false

// Disjoint check
fruits.isDisjointFrom(new Set(["grape", "melon"]));  // true
```

**Use when:**
- Comparing collections
- Set algebra operations
- Deduplicating while combining data

**Benefits:**
- Native, optimized implementations
- Chainable operations
- More readable than manual Set operations

**Runtime support:**
These are JavaScript runtime features. Ensure your runtime supports them or use a polyfill.

---

## TypeScript 5.6

### Iterator Helpers (5.6+)

Chainable iterator methods for lazy evaluation.

```typescript
function* numbers() {
  let i = 1;
  while (true) yield i++;
}

// Lazy evaluation - only computes what's needed
const evens = numbers()
  .map(x => x * 2)
  .filter(x => x % 4 === 0)
  .take(5);

for (const n of evens) {
  console.log(n);  // 4, 8, 12, 16, 20
}

// Create iterator from any iterable
const doubled = Iterator.from([1, 2, 3]).map(x => x * 2);

// Available methods:
Iterator.from(iterable)
  .map(fn)           // Transform each value
  .filter(fn)        // Keep values matching predicate
  .take(n)           // Take first n values
  .drop(n)           // Skip first n values
  .flatMap(fn)       // Map and flatten
  .reduce(fn, init)  // Reduce to single value
  .toArray()         // Collect to array
  .forEach(fn)       // Execute side effect
  .some(fn)          // Check if any match
  .every(fn)         // Check if all match
  .find(fn);         // Find first matching value
```

**Use when:**
- Processing large/infinite sequences
- Want lazy evaluation
- Chaining transformations

**Benefits:**
- Only computes values as needed
- Memory efficient
- Familiar array-like API

**Runtime support:**
Iterator helpers are JavaScript runtime features. Ensure your runtime supports them or use a polyfill.

### Nullish and Truthy Checks (5.6+)

TypeScript detects unnecessary truthy/nullish checks.

```typescript
// ❌ Error: Regular expressions are always truthy
if (/regex/) {
  // This always executes
}

// ❌ Error: Functions are always truthy
if (x => 0) {
  // This always executes
}

// ❌ Error: Value is never nullish
const value: string = "hello";
return value ?? "default";  // Error: ?? unnecessary

// ✅ Correct patterns
if (someBoolean) { }  // Boolean check
if (optionalValue !== undefined) { }  // Explicit check
return nullableValue ?? "default";  // Value can be null/undefined
```

**Use when:**
- Checking conditions
- Using nullish coalescing

**Benefits:**
- Catches logic errors
- Prevents dead code
- Enforces meaningful conditions

---

## TypeScript 5.7

### Never-Initialized Variables (5.7+)

Cross-scope variable initialization checks.

```typescript
function process() {
  let result: number;  // Declared but not initialized

  function display() {
    console.log(result);  // ❌ Error: Variable 'result' is used before being assigned
  }

  function compute() {
    result = 42;  // Initializes in different scope
  }

  display();  // Could run before compute()
}

// ✅ Fixed: Initialize before use
function process() {
  let result: number = 0;  // Initialized

  function display() {
    console.log(result);  // ✅ OK
  }
}

// ✅ Or ensure initialization order
function process() {
  let result: number;

  function compute() {
    result = 42;
  }

  compute();  // Initialize first
  console.log(result);  // ✅ OK
}
```

**Use when:**
- Using closures
- Delayed initialization
- Multiple initialization paths

**Benefits:**
- Catches subtle bugs
- Cross-function analysis
- Prevents undefined runtime errors

### Validated JSON Imports (5.7+)

Import assertions required for JSON modules.

```typescript
// ❌ Error: Missing import assertion
import config from "./config.json";

// ✅ Correct: Specify JSON type
import config from "./config.json" with { type: "json" };

// Type is inferred from JSON structure
config.apiUrl;  // TypeScript knows the shape

// Also works with dynamic imports
const data = await import("./data.json", {
  with: { type: "json" }
});
```

**Use when:**
- Importing JSON configuration
- Loading static data
- Using JSON modules

**Benefits:**
- Explicit about module type
- Security: prevents accidental code execution
- Standards-compliant (TC39 proposal)

**Note:**
JSON module contents are accessible via the default export. Namespace imports require `.default`.

---

## TypeScript 5.8

### Granular Return Expression Checks (5.8+)

TypeScript checks each branch of conditional returns separately.

```typescript
function getUrl(url: string): URL {
  return cache.has(url)
    ? cache.get(url)  // ✅ Checks this returns URL
    : url;            // ❌ Error: string is not assignable to URL
}

// ✅ Fixed: Both branches return correct type
function getUrl(url: string): URL {
  if (cache.has(url)) {
    const cached = cache.get(url);
    if (cached !== undefined) return cached;
  }
  return new URL(url);
}

// Works with complex conditionals
function process(x: number): string {
  return x > 0
    ? x.toString()  // ✅ Returns string
    : x < 0
      ? String(x)  // ✅ Returns string
      : false;  // ❌ Error: boolean not assignable to string
}
```

**Use when:**
- Writing conditional returns
- Ternary expressions
- Complex control flow

**Benefits:**
- More precise error locations
- Catches type errors per branch
- Better error messages

---

## TypeScript 5.9

### Import Defer (5.9+)

Lazy module evaluation - modules load only when first accessed.

```typescript
// Traditional import: Loads immediately
import * as HeavyParser from "./heavy-parser";  // Runs on import

// Deferred import: Loads only when used
import defer * as HeavyParser from "./heavy-parser";  // Defers execution

export function parseIfNeeded(data: Data) {
  if (needsParsing(data)) {
    // Module loads HERE - only when needed
    return HeavyParser.parse(data);
  }
  return data;
}

// Use cases
import defer * as Analytics from "./analytics";  // Analytics code only loads if used
import defer * as DevTools from "./dev-tools";  // Dev tools only in development
import defer * as Polyfills from "./polyfills";  // Polyfills only if needed
```

**Use when:**
- Importing heavy modules
- Conditional dependencies
- Optional features
- Lazy-loading utilities

**Benefits:**
- Faster initial load
- Only pay for what you use
- Reduces bundle execution time
- Maintains type safety

**Constraints:**
`import defer` is not downleveled and only works with `--module` set to `preserve` or `esnext`, and requires runtime or bundler support.

**Performance impact:**
```typescript
// Before: Heavy module always loads
import * as Chart from "./chart-library";  // 500kb loaded always

// After: Loads only when charting
import defer * as Chart from "./chart-library";  // 500kb loaded on demand
```

---

## Migration Guide

### From 5.4 to 5.5+

1. **Remove manual type predicates** - Let compiler infer
2. **Add regex validation** - Fix any invalid patterns
3. **Use Set methods** - Replace manual set operations

### From 5.5 to 5.6+

1. **Replace array chains with iterators** - For large datasets
2. **Review truthy checks** - Fix unnecessary conditions

### From 5.6 to 5.7+

1. **Add JSON import assertions** - Update all JSON imports
2. **Review uninitialized variables** - Fix cross-scope issues

### From 5.7 to 5.8+

1. **Fix conditional returns** - Each branch must match return type

### From 5.8 to 5.9+

1. **Use import defer** - For heavy/conditional modules
2. **Profile and optimize** - Measure load time improvements

---

## Compatibility

**Minimum version:** TypeScript 5.5
**Recommended version:** TypeScript 5.9+

**Checking your version:**
```bash
npx tsc --version
```

**Upgrading:**
```bash
npm install -D typescript@latest
```

**tsconfig.json:**
```json
{
  "compilerOptions": {
    "target": "es2023",
    "module": "node20",
    // ... other options
  }
}
```
