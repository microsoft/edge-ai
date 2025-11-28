import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Environment configuration - Node.js for backend testing
    environment: 'node',

    // Test file patterns (equivalent to .mocharc.json spec)
    include: ['tests/**/*.test.js'],

    // Setup files (equivalent to .mocharc.json require)
    setupFiles: ['tests/setup.js'],

    // Timeout settings (equivalent to .mocharc.json timeout)
    testTimeout: 10000,
    hookTimeout: 10000,

    // Reporter configuration (equivalent to .mocharc.json reporter)
    reporter: ['verbose'],

    // Backend-specific settings - Use forks for server instances
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true, // Use single fork to avoid worker exit issues
        maxForks: 1, // Single worker for integration tests
        minForks: 1
      }
    },

    // Prevent infinite loops and re-runs
    bail: 1, // Stop on first failure to prevent loops
    maxConcurrency: 1, // Run tests sequentially,

    // Coverage configuration (replaces c8)
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'tests/**',
        'node_modules/**',
        '**/*.config.js',
        '**/coverage/**'
      ],
      // Backend-specific coverage thresholds
      thresholds: {
        global: {
          branches: 80,
          functions: 80,
          lines: 80,
          statements: 80
        }
      }
    },

    // Performance settings
    slow: 1000,

    // Test isolation and cleanup
    isolate: true,
    clearMocks: true,
    restoreMocks: true,

    // Watch mode configuration
    watch: false,

    // Prevent test re-runs and infinite loops
    forceRerunTriggers: [],

    // Disable file watching completely for integration tests
    watchExclude: ['**/node_modules/**', '**/coverage/**'],

    // Globals (maintain Mocha-style globals for easier migration)
    globals: true,

    // Output configuration
    outputFile: {
      json: './test-results.json'
    }
  }
});
