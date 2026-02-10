---
description: Generate .d.ts declaration stubs for untyped packages or module augmentations
argument-hint: <module-name> | augment <module>
---

# ts-declare

Generate a `.d.ts` declaration file for an untyped npm package, or create a module augmentation for an existing typed package. Pass a module name to create a declaration stub, or use `augment <module>` to create a module augmentation.

## Process

1. Parse the argument to determine mode: plain `<module-name>` for declaration stub, `augment <module>` for augmentation
2. For declaration stubs:
   a. Check if `@types/<module-name>` exists on npm — if so, suggest installing it instead
   b. Read the package's entry point to discover its API shape (exported functions, classes, constants)
   c. Generate a `<module-name>.d.ts` file with `declare module "<module-name>"` and typed exports
   d. Suggest where to place the file and how to reference it in `tsconfig.json` `typeRoots` or `types`
3. For module augmentation:
   a. Read the existing type declarations for the module
   b. Generate an augmentation file using `declare module "<module>"` with the additions
   c. Ensure the file contains `export {}` or an import to make it a module
4. Output the generated `.d.ts` content and placement instructions
