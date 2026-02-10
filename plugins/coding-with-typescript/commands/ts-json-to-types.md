---
description: Convert JSON data to TypeScript interfaces and types
argument-hint: <json-or-file-path>
---

# ts-json-to-types

Convert a JSON value into well-typed TypeScript interfaces. Accepts inline JSON or a file path containing JSON. Handles nested objects, arrays, optional fields, union types, and null values.

## Process

1. Parse the input: if it looks like a file path, read the file; otherwise parse the argument as inline JSON
2. If the JSON is an array with multiple objects, merge their shapes to detect optional fields and union types
3. Generate a root interface (default name `Root`, or infer from context)
4. For each nested object, extract a named sub-interface
5. Map JSON types: `string` -> `string`, `number` -> `number`, `boolean` -> `boolean`, `null` -> `null`, arrays -> `T[]`
6. Mark fields as optional (`?`) when they appear in some but not all array elements
7. Use union types when a field has multiple observed types across elements
8. Output the generated TypeScript code
9. If the JSON appears to be an API response, suggest adding a top-level response wrapper type
