/** @type {import('jest').Config} */
export default {
  // Use Node as the test environment (not jsdom, which is for browser code)
  testEnvironment: 'node',

  // ESM support — disable transforms so Jest doesn't try to transpile ESM to CJS.
  // If you use TypeScript, swap this for ts-jest or @swc/jest.
  transform: {},

  // Treat .ts files as ESM (only needed if you write tests in TypeScript)
  // extensionsToTreatAsEsm: ['.ts'],

  // Where to find test files
  testMatch: [
    '**/__tests__/**/*.js',
    '**/*.test.js',
  ],

  // Coverage collection — what to measure
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.d.ts',
  ],

  // Minimum coverage thresholds — CI will fail if these are not met
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },

  // Reset mock state between tests to avoid leaking across test cases
  clearMocks: true,
};
