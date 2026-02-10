/**
 * Module Augmentation Boilerplate
 *
 * Copy the sections you need into your project's type declaration file
 * (e.g., src/types/augmentations.d.ts). Make sure the file is included
 * in your tsconfig.json "include" array.
 *
 * IMPORTANT: Module augmentation files MUST have at least one top-level
 * import or export to be treated as a module. If they don't, the
 * declarations become global and may conflict.
 */

// Required: makes this file a module
export {};

// ============================================================
// 1. Express Request Augmentation
// ============================================================
// Add custom properties to Express Request (e.g., after auth middleware).

declare module "express-serve-static-core" {
  interface Request {
    /** Authenticated user, set by auth middleware */
    user?: {
      id: string;
      email: string;
      roles: string[];
    };
    /** Request ID for tracing, set by request-id middleware */
    requestId?: string;
  }
}

// ============================================================
// 2. Window / Global Augmentation
// ============================================================
// Add properties to the browser's Window object (e.g., analytics, feature flags).

declare global {
  interface Window {
    /** Analytics SDK injected by script tag */
    analytics?: {
      track(event: string, properties?: Record<string, unknown>): void;
      identify(userId: string, traits?: Record<string, unknown>): void;
    };
    /** Feature flags loaded at startup */
    __FEATURE_FLAGS__?: Record<string, boolean>;
  }
}

// ============================================================
// 3. ProcessEnv Augmentation
// ============================================================
// Type your environment variables for process.env access.

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: "development" | "production" | "test";
      PORT?: string;
      DATABASE_URL: string;
      API_KEY: string;
      /** Add your env vars here */
    }
  }
}

// ============================================================
// 4. CSS Modules
// ============================================================
// Enables import styles from "./component.module.css" with type safety.

declare module "*.module.css" {
  const classes: Readonly<Record<string, string>>;
  export default classes;
}

declare module "*.module.scss" {
  const classes: Readonly<Record<string, string>>;
  export default classes;
}

// ============================================================
// 5. Static Asset Imports
// ============================================================
// Common asset types for bundlers (Vite, Webpack, etc.)

declare module "*.svg" {
  const content: string;
  export default content;
}

declare module "*.png" {
  const content: string;
  export default content;
}

declare module "*.jpg" {
  const content: string;
  export default content;
}

declare module "*.json" {
  const content: Record<string, unknown>;
  export default content;
}
