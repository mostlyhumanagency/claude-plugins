import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Use Node environment (not jsdom, which is for browser code)
    environment: 'node',

    // Test file patterns — colocate tests next to source or use a tests/ dir
    include: ['src/**/*.test.{js,ts}', 'tests/**/*.test.{js,ts}'],

    // Coverage using the v8 provider (faster than istanbul, built into Node)
    coverage: {
      provider: 'v8',
      include: ['src/**/*.{js,ts}'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.{js,ts}'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },

    // Enable globals (describe, it, expect) without importing them in each file
    globals: true,
  },
});
