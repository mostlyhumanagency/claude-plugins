---
name: coding-typescript-classes
description: Use when designing or reviewing TypeScript classes, inheritance, access modifiers, abstract classes, mixins, class-based APIs, or when you see TS2415 (class incorrectly implements interface), TS4114 (override modifier missing), or TS2341 (property is private).
---

# Coding TypeScript Classes

## Overview

Use classes when identity, lifecycle, or encapsulated mutable state is required. Prefer readonly public APIs and interfaces for capability contracts.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2415 | Class incorrectly implements interface | Add missing members or fix their types |
| TS4114 | This member must have an 'override' modifier | Add `override` keyword to methods overriding a parent |
| TS2341 | Property 'x' is private | Access through a public method or getter instead |
| TS2515 | Non-abstract class does not implement abstract member | Implement all abstract methods from the base class |
| TS2564 | Property has no initializer and is not assigned in constructor | Initialize in constructor or declare with `!` (justified) |

## References

- `object-oriented.md`
