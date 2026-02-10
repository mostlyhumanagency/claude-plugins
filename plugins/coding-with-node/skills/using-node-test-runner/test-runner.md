# Node Test Runner (v24)

## Basics

- Run tests with `node --test`.
- Use `test()` for cases and `describe()` for grouping.

## Selection and Filtering

- `--test-only` runs only tests marked `test.only()`.
- `--test-name-pattern` filters by test name.

## Concurrency and Sharding

- `--test-concurrency` controls the number of test files to run in parallel.
- `--test-shard` splits tests into shards for CI.

## Reporters

- `--test-reporter` configures output (for example, `spec`, `dot`, `tap`).
- `--test-reporter-destination` writes reporter output to a file.

## Assertions and Mocking

- Use `node:assert` for assertions.
- Use `node:test` mock utilities to stub timers and functions.

## Coverage

- Enable coverage with `node --test --coverage`.
- Focus on critical paths and error handling.

## Quick Reference

| Feature | Command / API | Notes |
|---|---|---|
| Run tests | `node --test` | Discovers and runs test files |
| Basic test | `test('name', () => { ... })` | Single test case |
| Group tests | `describe('name', () => { ... })` | Organize related tests |
| Filter by name | `--test-name-pattern="pattern"` | Run matching tests only |
| Run only | `--test-only` + `test.only()` | Focus on specific tests |
| Concurrency | `--test-concurrency=N` | Parallel test file execution |
| Sharding | `--test-shard=1/3` | Split tests for CI |
| Reporter | `--test-reporter=spec` | Output format (spec, dot, tap) |
| Coverage | `node --test --coverage` | Built-in code coverage |
| Mock timers | `test.mock.timers.enable()` | Deterministic timer testing |

## Common Mistakes

**Shared state between test files** — Test files run in parallel by default. Shared mutable state causes flaky tests. Use isolated setup per file.

**Missing `--test-only` flag with `test.only()`** — `test.only()` has no effect without the `--test-only` CLI flag. Both are required.

**Not using temp directories for fs tests** — File tests that write to fixed paths collide in parallel. Use `os.tmpdir()` + unique subdirectories.

**Relying on test execution order** — Tests within a file run in order, but files run in parallel. Don't depend on cross-file ordering.

## Constraints and Edges

- Tests in separate files may run in parallel; avoid shared state.
- Use temp directories for filesystem tests to prevent collisions.
- Avoid real network calls in unit tests.

## Do / Don't

- Do keep tests deterministic and isolated.
- Do use temporary directories for filesystem tests.
- Don't rely on execution order across files.
- Don't use real network calls in unit tests.

## Examples

### Basic test

```js
const test = require('node:test');
const assert = require('node:assert');

test('adds numbers', () => {
  assert.strictEqual(1 + 2, 3);
});
```

### Grouped tests

```js
const { describe, test } = require('node:test');

describe('math', () => {
  test('add', () => {});
  test('sub', () => {});
});
```

### Run only focused tests

```bash
node --test --test-only
```

### Run with a reporter

```bash
node --test --test-reporter=spec
```

## Snapshot Testing (v24+)

Assert that output matches a stored snapshot:

```js
import { test } from 'node:test';

test('renders correctly', (t) => {
  const output = render({ name: 'world' });
  t.assert.snapshot(output);
});
```

Run with `--test-update-snapshots` to update stored snapshots.

## Test Plan

Declare the expected number of assertions:

```js
test('completes all checks', (t) => {
  t.plan(3);
  t.assert.ok(check1());
  t.assert.ok(check2());
  t.assert.ok(check3());
});
```

The test fails if fewer or more assertions run than planned.

## Lifecycle Hooks

Run setup and teardown around tests:

```js
import { describe, it, before, after, beforeEach, afterEach } from 'node:test';

describe('database', () => {
  let db;

  before(async () => { db = await connect(); });
  after(async () => { await db.close(); });
  beforeEach(async () => { await db.clear(); });

  it('inserts a record', async () => {
    await db.insert({ name: 'test' });
    const rows = await db.findAll();
    assert.strictEqual(rows.length, 1);
  });
});
```

## Mocking

Mock functions, timers, and modules:

```js
import { test, mock } from 'node:test';

test('calls callback', (t) => {
  const fn = t.mock.fn();
  doSomething(fn);
  assert.strictEqual(fn.mock.calls.length, 1);
});

test('timer behavior', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const fn = t.mock.fn();
  setTimeout(fn, 1000);
  t.mock.timers.tick(1000);
  assert.strictEqual(fn.mock.calls.length, 1);
});
```

## Verification

- Confirm tests pass in CI with `node --test`.
- Review coverage reports for critical modules.
