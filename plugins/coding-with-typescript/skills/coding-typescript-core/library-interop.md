# Library Interop: Readonly Boundaries

**Core Principle:** Your domain types are readonly. Libraries often expect mutable types. Handle the mismatch explicitly at boundaries -- never let mutable types leak inward.

## Table of Contents

- [The Problem](#the-problem)
- [Mutable-to-Readonly: Receiving from Libraries](#mutable-to-readonly-receiving-from-libraries)
- [Readonly-to-Mutable: Passing to Libraries](#readonly-to-mutable-passing-to-libraries)
- [Common Library Patterns](#common-library-patterns)
- [The Boundary Rule](#the-boundary-rule)

---

## The Problem

Your domain enforces immutability:

```typescript
interface User {
  readonly id: string;
  readonly name: string;
  readonly tags: readonly string[];
}
```

But library-generated types are almost always mutable:

```typescript
type PrismaUser = { id: string; name: string; tags: string[] };
```

Two risks: mutable library types leak into your domain bypassing `readonly`, or passing readonly data to libraries expecting mutable causes compiler errors.

---

## Mutable-to-Readonly: Receiving from Libraries

```typescript
function fromPrismaUser(data: PrismaUser): User {
  return { id: data.id, name: data.name, tags: data.tags };
  // readonly string[] accepts string[] -- no runtime cost
}
```

**Key insight:** `readonly T[]` is a supertype of `T[]`. Assignment from mutable to readonly is always safe and free.

---

## Readonly-to-Mutable: Passing to Libraries

```typescript
type Mutable<T> = { -readonly [P in keyof T]: T[P] };

function toPrismaUser(user: User): Mutable<User> {
  return { ...user, tags: [...user.tags] }; // spread + copy nested arrays
}

await prisma.user.update({ data: toPrismaUser(user) });
// Spread creates a shallow copy. For nested readonly, copy each level explicitly.
```

---

## Common Library Patterns

### ORMs (Prisma / Drizzle)

```typescript
// Wrap at the repository boundary. Everything above sees only readonly User.
class UserRepository {
  async findById(id: string): Promise<User | undefined> {
    const row = await prisma.user.findUnique({ where: { id } });
    return row ? fromPrismaUser(row) : undefined;
  }

  async save(user: User): Promise<void> {
    await prisma.user.update({ where: { id: user.id }, data: toPrismaUser(user) });
  }
}
```

### Express / Hono Handlers

```typescript
// Validate and freeze at the handler boundary.
app.post("/users", (req, res) => {
  const parsed = validateCreateUser(req.body); // unknown -> Result<User>
  if (!parsed.ok) return res.status(400).json({ error: parsed.error.message });
  // parsed.value is readonly User from here onward
  res.status(201).json(userService.create(parsed.value));
});
```

### React: Props and State

```typescript
interface UserCardProps {
  readonly user: User;
  readonly onUpdate: (user: User) => void;
}

const [users, setUsers] = useState<readonly User[]>([]);
setUsers(prev => [...prev, newUser]);
setUsers(prev => prev.map(u => u.id === id ? { ...u, name } : u));
```

---

## The Boundary Rule

```
  Library (mutable)              Your domain (readonly)
  ========================       ========================
  PrismaUser { name: string }   --> fromPrisma() --> User { readonly name }
  req.body: unknown              --> validate()   --> User { readonly name }
  User { readonly name }         --> toPrisma()   --> PrismaUser { name: string }
```

1. **Readonly inside your domain.** Every interface, every parameter, every return type.
2. **Mutable only at the edges.** Boundary functions are the only place mutable types appear.
3. **Never let mutable types leak inward.** If a library type appears in domain code, wrap it.
4. **Conversion is explicit.** Named functions (`fromPrisma`, `toPrisma`) make boundaries visible.
5. **No runtime cost for mutable-to-readonly.** Assigning `string[]` to `readonly string[]` is free.
6. **Shallow copy for readonly-to-mutable.** Spread at the boundary, copy nested arrays as needed.

**Red flag:** If a Prisma/Drizzle/Express type appears directly inside a service or domain function, the boundary is leaking. Wrap it.
