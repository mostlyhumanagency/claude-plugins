---
name: using-node-sqlite
description: Use when storing data locally in a Node.js app without a database server, building embedded databases for CLI tools or Electron apps, running SQL queries with the built-in node:sqlite module, or writing in-memory databases for testing — covers DatabaseSync, prepared statements, transactions, WAL mode, and parameterized queries. Triggers on ERR_SQLITE_ERROR, database-related errors from node:sqlite.
---

# Using Node SQLite

## Overview

Use the built-in `node:sqlite` module for embedded SQL database operations without external dependencies.

## Version Scope

The `node:sqlite` module is experimental and available in Node.js v24+. The API may change in future releases.

## When to Use

- Embedded database for CLI tools, desktop apps, or local storage.
- In-memory databases for testing.
- Simple data persistence without a database server.
- Read-heavy workloads with WAL mode.

## When Not to Use

- Production server with concurrent writes — use PostgreSQL or MySQL.
- You need async/non-blocking queries — node:sqlite is synchronous.
- Targeting Node.js versions below v24.

## Quick Reference

- Open with `new DatabaseSync(path)` or `new DatabaseSync(':memory:')`.
- Use `db.exec(sql)` for DDL and statements without return values.
- Use `db.prepare(sql)` to create prepared statements.
- Use `stmt.run()` for INSERT/UPDATE/DELETE, `stmt.get()` for one row, `stmt.all()` for all rows.
- Always use prepared statements with parameters to prevent SQL injection.
- Enable WAL mode with `db.exec('PRAGMA journal_mode=WAL')` for better read concurrency.

## Examples

### Open and create a table

```js
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync('app.db');
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
  )
`);
```

### Insert with prepared statement

```js
const insert = db.prepare('INSERT INTO users (name, email) VALUES (?, ?)');
const result = insert.run('Alice', 'alice@example.com');
console.log(result.lastInsertRowid); // 1
```

### Query rows

```js
const all = db.prepare('SELECT * FROM users WHERE name = ?');
const rows = all.all('Alice');

const one = db.prepare('SELECT * FROM users WHERE id = ?');
const user = one.get(1);
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_SQLITE_ERROR | SQLITE_ERROR | Check SQL syntax; verify table/column names |
| ERR_SQLITE_ERROR | UNIQUE constraint failed | Value already exists in a UNIQUE column |
| ERR_SQLITE_ERROR | SQLITE_BUSY | Another connection holds a lock; enable WAL mode |
| ERR_UNKNOWN_BUILTIN_MODULE | No such built-in module: sqlite | Requires Node.js v24+; check your version |

## References

- `sqlite.md`
