# Node SQLite (v24+, Experimental)

**This module is experimental.** The API may change between Node.js releases. Use with awareness that breaking changes are possible.

## Opening a Database

```js
import { DatabaseSync } from 'node:sqlite';

// File-based database
const db = new DatabaseSync('myapp.db');

// In-memory database (great for testing)
const memDb = new DatabaseSync(':memory:');
```

## Running Statements

### db.exec(sql)

- Executes one or more SQL statements.
- No return value; use for DDL (CREATE, ALTER, DROP) and pragmas.

```js
db.exec(`
  CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    done INTEGER DEFAULT 0
  )
`);
db.exec('PRAGMA journal_mode=WAL');
```

### db.prepare(sql)

- Creates a prepared statement for repeated execution.
- Returns a `StatementSync` object with `.run()`, `.get()`, `.all()` methods.

```js
const stmt = db.prepare('SELECT * FROM tasks WHERE done = ?');
```

## Prepared Statement Methods

### stmt.run(...params)

- Executes INSERT, UPDATE, DELETE.
- Returns `{ changes, lastInsertRowid }`.

```js
const insert = db.prepare('INSERT INTO tasks (title) VALUES (?)');
const result = insert.run('Buy groceries');
console.log(result.lastInsertRowid); // 1
console.log(result.changes);         // 1

const update = db.prepare('UPDATE tasks SET done = 1 WHERE id = ?');
update.run(1);

const del = db.prepare('DELETE FROM tasks WHERE id = ?');
del.run(1);
```

### stmt.get(...params)

- Returns one row as an object, or `undefined` if no match.

```js
const find = db.prepare('SELECT * FROM tasks WHERE id = ?');
const task = find.get(1);
// { id: 1, title: 'Buy groceries', done: 0 }
```

### stmt.all(...params)

- Returns all matching rows as an array of objects.

```js
const all = db.prepare('SELECT * FROM tasks WHERE done = ?');
const pending = all.all(0);
// [{ id: 1, title: 'Buy groceries', done: 0 }, ...]
```

## Parameters

### Positional parameters

```js
const stmt = db.prepare('INSERT INTO tasks (title, done) VALUES (?, ?)');
stmt.run('Read book', 0);
```

### Named parameters

```js
const stmt = db.prepare('INSERT INTO tasks (title, done) VALUES (:title, :done)');
stmt.run({ title: 'Read book', done: 0 });
```

## Transactions

Use `db.exec` with BEGIN/COMMIT/ROLLBACK for transaction control.

```js
function transferFunds(db, fromId, toId, amount) {
  db.exec('BEGIN');
  try {
    const withdraw = db.prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?');
    const deposit = db.prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?');
    withdraw.run(amount, fromId);
    deposit.run(amount, toId);
    db.exec('COMMIT');
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}
```

### Batch inserts with transactions

```js
function insertMany(db, items) {
  const insert = db.prepare('INSERT INTO tasks (title) VALUES (?)');
  db.exec('BEGIN');
  try {
    for (const item of items) {
      insert.run(item.title);
    }
    db.exec('COMMIT');
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}
```

## WAL Mode

- Write-Ahead Logging allows concurrent reads during writes.
- Set once after opening the database.

```js
db.exec('PRAGMA journal_mode=WAL');
```

## Closing the Database

```js
db.close();
```

## Quick Reference

| Operation | API | Returns |
|---|---|---|
| Open database | `new DatabaseSync(path)` | Database instance |
| In-memory DB | `new DatabaseSync(':memory:')` | Database instance |
| Run DDL/pragmas | `db.exec(sql)` | undefined |
| Prepare statement | `db.prepare(sql)` | StatementSync |
| Insert/Update/Delete | `stmt.run(...params)` | `{ changes, lastInsertRowid }` |
| Get one row | `stmt.get(...params)` | Object or undefined |
| Get all rows | `stmt.all(...params)` | Array of objects |
| Begin transaction | `db.exec('BEGIN')` | undefined |
| Commit | `db.exec('COMMIT')` | undefined |
| Rollback | `db.exec('ROLLBACK')` | undefined |
| Enable WAL | `db.exec('PRAGMA journal_mode=WAL')` | undefined |
| Close | `db.close()` | undefined |

## Common Mistakes

**Not using prepared statements** — String concatenation in SQL queries leads to SQL injection. Always use `?` or named parameters.

```js
// BAD — SQL injection risk
db.exec(`SELECT * FROM users WHERE name = '${userInput}'`);

// GOOD — parameterized
const stmt = db.prepare('SELECT * FROM users WHERE name = ?');
stmt.all(userInput);
```

**Not closing the database** — Always call `db.close()` when done, especially in CLI tools or scripts that exit.

**Forgetting transactions for batch operations** — Without transactions, each INSERT is a separate disk write. Wrapping in BEGIN/COMMIT is orders of magnitude faster.

**Not enabling WAL mode** — Default journal mode locks the entire database during writes. WAL allows concurrent reads.

## Do / Don't

- Do use prepared statements with parameters for all queries with user data.
- Do use transactions for batch operations.
- Do enable WAL mode for read-heavy workloads.
- Do use `:memory:` databases for testing.
- Don't concatenate user input into SQL strings.
- Don't forget to close the database when done.
- Don't use node:sqlite for high-concurrency production servers.
- Don't assume this API is stable — it is experimental.

## Examples

### Full CRUD example

```js
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec('PRAGMA journal_mode=WAL');
db.exec(`
  CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  )
`);

// Create
const insert = db.prepare('INSERT INTO notes (content) VALUES (?)');
insert.run('First note');
insert.run('Second note');

// Read
const getAll = db.prepare('SELECT * FROM notes ORDER BY created_at DESC');
const notes = getAll.all();

const getOne = db.prepare('SELECT * FROM notes WHERE id = ?');
const note = getOne.get(1);

// Update
const update = db.prepare('UPDATE notes SET content = ? WHERE id = ?');
update.run('Updated first note', 1);

// Delete
const del = db.prepare('DELETE FROM notes WHERE id = ?');
del.run(2);

db.close();
```

### In-memory testing

```js
import { DatabaseSync } from 'node:sqlite';

function createTestDb() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)`);
  return db;
}

// Each test gets a fresh database
const db = createTestDb();
const insert = db.prepare('INSERT INTO users (name) VALUES (?)');
insert.run('Test User');
const user = db.prepare('SELECT * FROM users WHERE id = 1').get();
// { id: 1, name: 'Test User' }
db.close();
```

## Verification

- Check Node.js version: `node -v` (must be v24+).
- Run with `--experimental-sqlite` flag if required by your Node version.
