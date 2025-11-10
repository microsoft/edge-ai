import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Environment configuration - optimized for Happy DOM performance
    environment: 'happy-dom',
    environmentOptions: {
      happyDOM: {
        settings: {
          disableErrorCapturing: false,
          disableCSSFileLoading: false,
          disableJavaScriptFileLoading: false, // Enable JS for better test coverage
          disableJavaScriptEvaluation: false, // Enable JS evaluation for better test realism
          enableFileSystemHttpRequests: false,
          disableIframePageLoading: true, // Disable unnecessary iframe loading
          disableComputedStyleRendering: false, // Keep computed styles for CSS tests
          navigation: {
            disableMainFrameNavigation: true, // Optimize navigation for test performance
            disableChildFrameNavigation: true,
            disableChildPageNavigation: true
          },
          device: {
            mediaType: 'screen',
            prefersColorScheme: 'light'
          }
        }
      }
    },

    // Test file patterns (equivalent to .mocharc.json spec)
    include: ['tests/**/*.test.js'],

    // Setup files (minimal for performance)
    setupFiles: [
      'tests/helpers/vitest-setup.js',
      'tests/helpers/plugin-loader.js'
    ],

    // Optimized timeout settings for multi-core performance (dev container adjusted)
    testTimeout: 5000, // Reduced for faster failure detection with parallel execution
    hookTimeout: 10000, // Increased for dev container environment (DOM setup can be slow)

    // Reporter configuration (minimal for performance)
    reporter: ['basic'], // Switch to basic reporter for performance

    // Parallel execution optimized for 20-core system with 32GB RAM
    pool: 'threads', // Switch to threads for better CPU utilization on multi-core systems
    poolOptions: {
      threads: {
        singleThread: false, // Enable multiple threads
        maxThreads: 16, // Aggressive threading for 20-core system (leave 4 cores for OS)
        minThreads: 4, // Minimum thread count for consistent performance
        isolate: true, // Maintain test isolation
        useAtomics: true // Enable atomic operations for better performance
      }
    },

    // Aggressive concurrency settings optimized for available hardware
    maxConcurrency: 16, // Match thread count for optimal resource utilization
    bail: 0, // Don't bail on first failure (vitest default)
    maxWorkers: 16, // Explicit worker count matching available cores
    fileParallelism: true, // Enable file parallelism (vitest default)
    forceRerunTriggers: ['**/package.json/**', '**/vitest.config.*/**'],

    // Optimized environment settings
    experimentalVmThreads: false,

    // Reset concurrent execution to vitest default
    sequence: {
      concurrent: false, // Reset to vitest default (false) - parallel files still enabled via fileParallelism
      shuffle: false, // Maintain predictable order (vitest default)
      hooks: 'stack' // Use stack-based hook execution (vitest default)
    },

    // Coverage configuration (replaces c8)
    coverage: {
      provider: 'v8',
      reporter: ['text'], // Minimal coverage reporting
      exclude: [
        'tests/**',
        'node_modules/**',
        '**/*.config.js',
        '**/coverage/**'
      ]
    },

    // Performance settings
    slow: 2000, // Increase slow threshold

    // Enhanced test isolation and cleanup
    isolate: true, // Enable strong isolation
    clearMocks: true, // Clear mocks before each test
    restoreMocks: true, // Restore mocks after each test
    unstubEnvs: true, // Restore environment variables
    unstubGlobals: true, // Restore global variables

    // Memory optimization settings
    teardownTimeout: 5000, // Allow time for cleanup
    setupTimeout: 5000, // Allow time for setup

    // Disable file watching for performance
    watch: false,

    // Minimize global pollution
    globals: false, // Disable globals for better isolation

    // Enhanced retry and error handling
    retry: 0, // No retries to avoid masking issues

    // Optimize dependency handling
    deps: {
      optimizer: {
        web: {
          include: ['happy-dom'] // Use new optimizer config instead of deprecated inline
        }
      }
    }
  }
});
