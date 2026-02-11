---
name: configuring-astro-6-csp
description: Use when configuring Content Security Policy in Astro 6 — enabling CSP headers, automatic script and style hash generation, customizing CSP directives, or protecting against XSS and code injection attacks.
---

# Configuring Content Security Policy in Astro 6

Content Security Policy (CSP) is a security layer that protects against cross-site scripting (XSS) and code injection attacks by controlling which resources the browser is allowed to load. Astro 6 introduces built-in CSP support with automatic hash generation for inline scripts and styles.

## What CSP Does

CSP instructs the browser to only execute scripts and load resources from approved sources. Without CSP, an attacker who injects malicious HTML into your page can execute arbitrary JavaScript. With CSP enabled, the browser blocks any script or style that is not explicitly allowed.

## Enabling CSP in Astro 6

Configure CSP in your `astro.config.mjs`:

```javascript
import { defineConfig } from "astro/config";

export default defineConfig({
  security: {
    csp: true,
  },
});
```

This enables CSP with sensible defaults. Astro automatically generates hashes for all inline scripts and styles it produces, so they continue to work without `'unsafe-inline'`.

## Automatic Script and Style Hash Generation

When CSP is enabled, Astro scans all inline `<script>` and `<style>` tags at build time and generates SHA-256 hashes for each one. These hashes are included in the `Content-Security-Policy` header, allowing the browser to verify that inline code has not been tampered with.

This works automatically — you do not need to manually compute or manage hashes.

## Works in All Render Modes

CSP support works across all Astro rendering modes:

- **Static** — CSP headers are output as `<meta>` tags in the HTML
- **Server (SSR)** — CSP headers are set as HTTP response headers
- **Hybrid** — Prerendered pages use `<meta>` tags; server-rendered pages use HTTP headers

## Customizing CSP Directives

You can customize individual directives by passing an object:

```javascript
import { defineConfig } from "astro/config";

export default defineConfig({
  security: {
    csp: {
      directives: {
        "default-src": ["'self'"],
        "script-src": ["'self'"],
        "style-src": ["'self'"],
        "img-src": ["'self'", "https://images.example.com"],
        "font-src": ["'self'", "https://fonts.gstatic.com"],
        "connect-src": ["'self'", "https://api.example.com"],
        "frame-ancestors": ["'none'"],
      },
    },
  },
});
```

Astro automatically appends script and style hashes to `script-src` and `style-src` directives, so you do not need to include them manually.

## Common Directive Patterns

### Allow Google Fonts

```javascript
directives: {
  "style-src": ["'self'", "https://fonts.googleapis.com"],
  "font-src": ["'self'", "https://fonts.gstatic.com"],
}
```

### Allow Analytics

```javascript
directives: {
  "script-src": ["'self'", "https://www.googletagmanager.com"],
  "connect-src": ["'self'", "https://www.google-analytics.com"],
}
```

### Allow Images from a CDN

```javascript
directives: {
  "img-src": ["'self'", "https://cdn.example.com", "data:"],
}
```

### Strict CSP for Maximum Security

```javascript
directives: {
  "default-src": ["'none'"],
  "script-src": ["'self'"],
  "style-src": ["'self'"],
  "img-src": ["'self'"],
  "font-src": ["'self'"],
  "connect-src": ["'self'"],
  "frame-ancestors": ["'none'"],
  "base-uri": ["'self'"],
  "form-action": ["'self'"],
}
```

## Production Readiness

CSP in Astro 6 is production-ready. It is designed for real-world deployment with automatic hash management, so you get strong protection without manual maintenance. Test your CSP configuration in report-only mode first if you want to verify it does not break third-party integrations:

```javascript
security: {
  csp: {
    reportOnly: true,
    directives: {
      // your directives
    },
  },
}
```

Once you confirm no resources are being blocked, switch to enforcement mode by removing `reportOnly`.
