---
description: "Scaffold a new React component from templates"
argument-hint: "ComponentName"
---

# react-component

Scaffold a new React component using a predefined template, replacing placeholder names with the provided component name.

## Process

1. Accept component name as argument (or ask for it)
2. Ask which template to use: form, context-provider, error-boundary, page-layout, or blank component
3. Copy the selected template from `${CLAUDE_PLUGIN_ROOT}/templates/`
4. Replace placeholder names with the provided component name
5. Create the component file in the appropriate directory
6. Add any necessary imports to parent components if applicable
