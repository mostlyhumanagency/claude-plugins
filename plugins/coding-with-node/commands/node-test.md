---
description: "Run tests with Node.js built-in test runner and analyze coverage results"
---

# node-test

Run the project test suite, analyze failures, and report coverage results to identify gaps in test coverage.

## Process

1. Detect test runner in use: check for node:test imports, jest.config, vitest.config, mocha config
2. If using node:test: run `node --test --coverage` and capture output
3. If using another runner: run the configured test script (npm test or pnpm test)
4. Parse test output for failures; group by file
5. For each failure, explain the assertion error and suggest a fix
6. Parse coverage results and identify files below 80% coverage threshold
7. Identify untested exported functions by comparing exports with test coverage
8. Summarize: total tests, passed, failed, skipped, coverage percentage
