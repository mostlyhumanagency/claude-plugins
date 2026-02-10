---
name: ts-json-to-types
description: "This skill should be used when the user asks to 'convert JSON to TypeScript', 'generate types from JSON', 'create interfaces from API response', or pastes JSON wanting types. Applies when the user has JSON data and needs corresponding TypeScript type definitions."
---

# JSON to TypeScript Type Generation

## Overview

This skill converts JSON data into well-structured TypeScript interfaces and type aliases. It analyzes the shape of JSON values -- including nested objects, arrays, optional fields, null values, and mixed-type fields -- and produces clean, idiomatic TypeScript type definitions. When given an array of objects, it merges their shapes to detect fields that are optional or have union types, producing more accurate types than analyzing a single object would.

Converting JSON to types is one of the most common tasks when integrating with APIs, working with configuration files, or prototyping data models. This skill automates the tedious parts while applying TypeScript naming conventions and structural best practices.

## When to Use

Use this skill when:

- The user pastes JSON and asks for TypeScript types or interfaces
- The user asks to "convert JSON to TypeScript", "generate types from this JSON", or "create interfaces from this response"
- The user has an API response and wants types for it
- The user is pasting sample data from a database, config file, or external service
- The user wants to create a type-safe wrapper around untyped JSON data
- The user provides a file path to a JSON file and wants types generated from it

Do not use this skill when the user wants to validate JSON at runtime (suggest zod or a validation library instead) or when they want to parse JSON from a string (that is a code task, not a type generation task).

## Process

Follow these steps to convert JSON to TypeScript types:

1. **Obtain the JSON.** Determine the input source:
   - If the user pasted JSON inline, parse it directly
   - If the user provided a file path, read the file and parse the JSON
   - If the JSON is invalid, report the parse error with the location and ask for corrected input

2. **Determine the root structure.** Identify whether the root value is:
   - A single object -> generate one root interface
   - An array of objects -> merge shapes across all elements for more accurate types
   - An array of primitives -> generate a type alias (e.g., `type Root = string[]`)
   - A primitive value -> generate a type alias

3. **Analyze object shapes.** For each object in the data:
   - Record every key and the type of its value
   - For nested objects, recursively analyze and create separate named interfaces
   - For arrays, analyze the element types; if elements are objects, create an interface for them
   - Track which keys appear in all objects vs. only some (for optional field detection)
   - Track keys that have different types across objects (for union type detection)

4. **Handle special cases:**
   - **null values**: Type as `null` in a union (e.g., `string | null`). If a field is always null, type it as `unknown | null` and add a comment suggesting the user specify the actual type
   - **Empty arrays**: Type as `unknown[]` with a comment noting the actual element type could not be inferred
   - **Mixed-type arrays**: Use a union type for elements (e.g., `(string | number)[]`)
   - **Date-like strings**: Keep as `string` but add a comment noting it looks like a date (do not assume `Date` type since JSON does not have dates)
   - **Numeric strings**: Keep as `string` (do not convert to `number`)
   - **Nested arrays of objects**: Create separate named interfaces for each level

5. **Name the interfaces.** Apply these naming conventions:
   - Root interface: use a name inferred from context (e.g., `User` if the JSON looks like user data) or `Root` as a default
   - Nested interfaces: derive names from the parent key in PascalCase (e.g., a key `"address"` becomes `interface Address`)
   - Array element interfaces: use the singular form of the parent key (e.g., items array elements become `Item`)
   - If a name collision occurs, append a numeric suffix

6. **Generate the output.** Produce TypeScript code with:
   - One interface per object shape, using `interface` (not `type`) for objects
   - `type` aliases for unions and primitives
   - Optional fields marked with `?`
   - Fields sorted alphabetically within each interface
   - `readonly` only if the user requests immutability
   - Exported interfaces (using `export`) if the user's context suggests module usage

7. **Suggest enhancements.** After the generated types, suggest:
   - If the JSON looks like an API response, propose a generic wrapper (e.g., `ApiResponse<T>`)
   - If there are fields that look like IDs, suggest branded types
   - If the user might need runtime validation, mention zod schema generation as a next step

## Quick Reference

| JSON Shape | TypeScript Output |
|---|---|
| `{"name": "Ana", "age": 30}` | `interface Root { age: number; name: string; }` |
| `[{"id": 1}, {"id": 2}]` | `interface Root { id: number; }` with `type RootList = Root[]` |
| `{"tags": ["a", "b"]}` | `interface Root { tags: string[]; }` |
| `{"value": null}` | `interface Root { value: unknown \| null; }` |
| `[{"a": 1}, {"a": 1, "b": 2}]` | `interface Root { a: number; b?: number; }` |
| `{"nested": {"x": 1}}` | `interface Nested { x: number; }` + `interface Root { nested: Nested; }` |
| `[{"v": "str"}, {"v": 42}]` | `interface Root { v: string \| number; }` |

## Common Mistakes

- **Using `type` instead of `interface` for object shapes.** While both work, `interface` is preferred for object shapes in TypeScript because it supports declaration merging and provides clearer error messages. Reserve `type` for unions, intersections, and primitive aliases.

- **Not merging array elements.** When given an array of objects, analyzing only the first element misses optional fields and union types that appear in later elements. Always analyze all elements and merge their shapes.

- **Converting null-only fields to `null`.** A field that is `null` in the sample data almost certainly has a real type when populated. Type it as `unknown | null` and flag it for the user to specify, rather than typing it as just `null`.

- **Generating overly deep nesting.** If the same object shape appears at multiple levels (e.g., recursive tree structures), detect the repetition and use a self-referencing interface rather than generating infinite levels of distinct interfaces.

- **Assuming JSON field names are valid TypeScript identifiers.** JSON keys can contain spaces, hyphens, and other characters that are not valid in TypeScript identifiers. Wrap these in quotes in the interface definition (e.g., `"content-type": string`).
