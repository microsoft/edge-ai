import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Use happy-dom environment for frontend module compatibility
    environment: 'happy-dom',

    // Only run frontend-backend integration tests
    include: ['tests/integration/frontend-backend-integration.test.js'],

    // Setup files
    setupFiles: ['tests/setup.js'],

    // Timeout settings for integration tests
    testTimeout: 15000,
    hookTimeout: 15000,

    // Reporter configuration
    reporter: ['verbose'],

    // Use forks for server instances
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,
        maxForks: 1,
        minForks: 1
      }
    },

    // Prevent infinite loops
    bail: 1,
    maxConcurrency: 1,

    // Test isolation and cleanup
    isolate: true,
    clearMocks: true,
    restoreMocks: true,

    // Disable watch mode
    watch: false,

    // Globals for easier migration
    globals: true,

    // Performance settings
    slow: 2000
  }
});
