---
name: using-node-test-runner
description: Use when writing unit or integration tests in Node.js without external frameworks, setting up test suites with describe/it, mocking dependencies, measuring code coverage, filtering or sharding tests for CI, or configuring test reporters — covers node:test, assert, mock, test planning, snapshots, and built-in coverage. Triggers on ERR_TEST_FAILURE, test discovery issues, coverage configuration problems.
---

# Using Node Test Runner

## Overview

Use `node:test` for unit and integration tests with minimal dependencies.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Writing tests without external frameworks.
- Filtering or sharding tests for CI.
- Configuring reporters and coverage.

## When Not to Use

- You need a feature-heavy framework (snapshot tests, advanced mocking).
- You rely on ecosystem-specific helpers in Jest/Mocha/Vitest.
- You are testing browser-only code.

## Quick Reference

- Run tests with `node --test`.
- Use `--test-only` and `--test-name-pattern` for filtering.
- Use `--test-reporter` for output and `--test-reporter-destination` for files.
- Enable coverage when validating test quality.

## Examples

### Basic test

```js
const test = require('node:test');
const assert = require('node:assert');

test('adds numbers', () => {
  assert.strictEqual(1 + 2, 3);
});
```

### Filter by name

```bash
node --test --test-name-pattern="adds"
```

### Run only focused tests

```bash
node --test --test-only
```

### Enable coverage

```bash
node --test --coverage
```

## Common Errors

| Code / Issue | Message Fragment | Fix |
|---|---|---|
| ERR_TEST_FAILURE | Test failed | Check assertion messages — use `assert.strictEqual` for clear diffs |
| No tests found | Test runner found 0 files | Name test files `*.test.js` or pass explicit paths |
| ERR_INVALID_ARG_TYPE | Invalid argument in assert | Ensure assert arguments match expected types |
| test.only ignored | `test.only()` runs all tests | Add `--test-only` flag to the CLI command |
| Coverage incomplete | Missing branches in report | Ensure test files import all source modules |

## References

- `test-runner.md`
