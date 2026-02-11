---
name: ts-declare
description: "Use when creating .d.ts declaration files, typing an untyped npm package, augmenting an existing module (e.g. extending Express Request, adding fields to Window), writing ambient declarations for global variables, or fixing TS7016 (could not find declaration file). Also use when @types packages are missing and custom type stubs are needed."
---

# TypeScript Declaration File Generation

## Overview

This skill generates `.d.ts` declaration files for two scenarios: creating type stubs for untyped npm packages, and creating module augmentations to extend existing typed packages. Declaration files are the bridge between untyped JavaScript and TypeScript's type system. They describe the shape of a module's API without containing implementation code, allowing the TypeScript compiler to check usage without having access to the source types.

When a package lacks types and no `@types/*` package exists on DefinitelyTyped, the developer needs a custom declaration file. Similarly, when a typed package needs additional properties (like adding custom fields to Express's `Request` object), module augmentation is the correct TypeScript pattern. This skill handles both cases.

## When to Use

Use this skill when:

- The user encounters TS7016: "Could not find a declaration file for module 'x'"
- The user asks to "create a .d.ts file", "type an untyped package", or "add types for a module"
- The user asks to "augment a module", "extend Express Request", "add properties to Window", or similar
- The user wants to declare global types or ambient modules
- The user has a JavaScript-only internal package that needs type definitions
- The user is importing a `.js` file, CSS module, image, or other non-TS asset and needs a module declaration
- The user encounters TS2305: "Module has no exported member" and the member needs to be added via augmentation

Do not use this skill for general type-writing tasks. It is specifically for `.d.ts` files and module declarations, not for typing the user's own source code.

## Process

Follow these steps to generate declaration files:

### Mode 1: Declaration Stub for Untyped Package

1. **Check for existing types.** Before writing a custom declaration, verify:
   - Does the package ship its own types? Check for a `"types"` or `"typings"` field in the package's `package.json`
   - Does `@types/<package-name>` exist? Check with `npm info @types/<package-name>` or `npm view @types/<package-name> version`
   - If types exist, instruct the user to install them and skip custom declaration generation

2. **Discover the package API.** Read the package's entry point to determine what it exports:
   - Check `node_modules/<package>/package.json` for `"main"`, `"module"`, or `"exports"` to find the entry point
   - Read the entry file and any re-exported modules to catalog exported functions, classes, objects, and constants
   - Check the package's README or documentation for API documentation
   - If the package is large, focus on the exports the user actually imports

3. **Generate the declaration file.** Create a `.d.ts` file with:
   - A `declare module "<package-name>"` block if placing in a global declarations file
   - Or a standalone `.d.ts` file with explicit exports if placing alongside the project's types
   - Function signatures with parameter names and types (use `any` sparingly; prefer `unknown` for truly unknown types and add TODO comments)
   - Class declarations with public methods and properties
   - Exported constants and their types
   - Default export if the package uses one

4. **Advise on placement.** Tell the user where to put the file:
   - For project-wide declarations: a `types/` or `typings/` directory referenced by `typeRoots` in tsconfig
   - For a single declaration file: ensure the file is included in the tsconfig's `include` pattern
   - If using `typeRoots`, remind the user that setting it overrides the default `node_modules/@types` lookup -- they need to include both

### Mode 2: Module Augmentation

1. **Read existing types.** Find and read the existing type declarations for the module being augmented. These are typically in `node_modules/@types/<package>/index.d.ts` or in the package's own shipped types.

2. **Identify the interface or namespace to augment.** Common augmentation targets:
   - Express: `Request`, `Response`, or `Application` interfaces in `express-serve-static-core`
   - Window: the global `Window` interface
   - `process.env`: the `ProcessEnv` interface in `NodeJS` namespace
   - Any library that supports declaration merging via interfaces

3. **Generate the augmentation file.** Create a `.d.ts` file containing:
   - An import or `export {}` statement to make the file a module (required for augmentation to work -- without this, the file is treated as a script and declarations become global overrides)
   - A `declare module "<module-path>"` block with the interface or namespace extension
   - Only the new members being added -- existing members are merged automatically

4. **Verify the augmentation.** Remind the user to:
   - Ensure the file is included in the tsconfig's `include` pattern
   - Restart the TypeScript language server (`Ctrl+Shift+P` -> "TypeScript: Restart TS Server" in VS Code) as augmentations sometimes do not pick up live
   - Check that the augmented types appear in IntelliSense on the target object

## Quick Reference

| Scenario | Action |
|---|---|
| TS7016: no declaration file for 'x' | Check for `@types/x`, if none exists generate a declaration stub |
| "extend Express Request" | Augment `express-serve-static-core` `Request` interface |
| "add field to Window" | Augment global `Window` interface via `declare global` |
| "type process.env" | Augment `NodeJS.ProcessEnv` interface |
| CSS/image module imports | Create `declare module "*.css"` or `declare module "*.png"` |
| Internal JS package | Generate `.d.ts` from the actual JS source code |
| User has `typeRoots` set | Ensure `node_modules/@types` is still included alongside custom roots |

## Common Mistakes

- **Forgetting `export {}` in augmentation files.** Without a top-level import or export, TypeScript treats the file as a script, not a module. In script context, `declare module` creates an ambient module declaration rather than an augmentation, which replaces types entirely instead of merging them. Always include at least `export {}` to force module context.

- **Augmenting the wrong module path.** Express's `Request` interface lives in `express-serve-static-core`, not `express`. Augmenting `declare module "express"` will not extend the `Request` type that middleware receives. Check which module actually declares the interface you want to extend.

- **Setting `typeRoots` without including `node_modules/@types`.** When `typeRoots` is set in tsconfig, it replaces the default lookup in `node_modules/@types`. If the user sets `"typeRoots": ["./types"]`, they lose access to all DefinitelyTyped packages. Always include both: `"typeRoots": ["./types", "./node_modules/@types"]`.

- **Using `any` throughout the declaration.** A declaration file full of `any` provides no type safety. It silences the TS7016 error but gives the developer a false sense of having typed code. Use specific types where the API is known, `unknown` where it is not, and add TODO comments for types that need refinement.

- **Not making the declaration file visible to the compiler.** A `.d.ts` file that is not covered by the tsconfig's `include` pattern or `typeRoots` is invisible to the compiler. After creating the file, always verify it is included by checking that the augmented or declared types resolve correctly.
