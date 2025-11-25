import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    // Exclude debug and tracking directories from linting
    ignores: [
      '.copilot-tracking/**',
      'node_modules/**',
      'dist/**',
      'build/**'
    ]
  },
  {
    // Global configuration for all JavaScript files
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        // Node.js globals
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        global: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        setImmediate: 'readonly',
        clearImmediate: 'readonly'
      }
    },
    rules: {
      // ES6 module specific rules
      'no-undef': 'error',
      'no-unused-vars': ['warn', {
        'argsIgnorePattern': '^_',
        'varsIgnorePattern': '^_'
      }],

      // Code quality rules
      'no-console': 'off', // Allow console for server logging
      'no-debugger': 'warn',
      'no-alert': 'error',
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-new-func': 'error',

      // Best practices
      'eqeqeq': ['error', 'always'],
      'curly': ['error', 'all'],
      'dot-notation': 'error',
      'no-multi-spaces': 'error',
      'no-trailing-spaces': 'error',
      'no-multiple-empty-lines': ['error', { 'max': 2 }],

      // ES6 specific
      'prefer-const': 'error',
      'no-var': 'error',
      'prefer-arrow-callback': 'warn',
      'arrow-spacing': 'error',
      'prefer-template': 'warn',

      // Import/Export
      'no-duplicate-imports': 'error'
    }
  },
  {
    // Browser-specific configuration for frontend files
    files: ['docs/assets/js/**/*.js', 'docs/**/*.js', '*.js'],
    languageOptions: {
      globals: {
        // Browser globals
        window: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
        location: 'readonly',
        history: 'readonly',
        fetch: 'readonly',
        localStorage: 'readonly',
        sessionStorage: 'readonly',

        // Browser APIs
        AbortController: 'readonly',
        addEventListener: 'readonly',
        dispatchEvent: 'readonly',
        requestAnimationFrame: 'readonly',
        performance: 'readonly',
        innerHeight: 'readonly',
        innerWidth: 'readonly',

        // CSS APIs
        getComputedStyle: 'readonly',
        CSSRule: 'readonly',
        getEventListeners: 'readonly',

        // DOM APIs
        Element: 'readonly',
        HTMLElement: 'readonly',
        Node: 'readonly',
        Event: 'readonly',
        CustomEvent: 'readonly',
        MouseEvent: 'readonly',
        KeyboardEvent: 'readonly',
        FocusEvent: 'readonly',
        TouchEvent: 'readonly',
        HashChangeEvent: 'readonly',
        EventTarget: 'readonly',
        DOMException: 'readonly',
        MutationObserver: 'readonly',
        ResizeObserver: 'readonly',
        IntersectionObserver: 'readonly',

        // Animation APIs
        cancelAnimationFrame: 'readonly',

        // Web APIs
        Blob: 'readonly',
        URL: 'readonly',
        URLSearchParams: 'readonly',
        FormData: 'readonly',
        Storage: 'readonly',
        StorageEvent: 'readonly',

        // Browser dialogs (should be avoided in production)
        alert: 'readonly',
        confirm: 'readonly',
        prompt: 'readonly',

        // Docsify globals
        Docsify: 'readonly',
        $docsify: 'readonly',

        // Common libraries
        marked: 'readonly',

        // Module system
        module: 'readonly',
        require: 'readonly'
      }
    },
    rules: {
      'no-console': 'warn', // Warn for console in frontend
      'no-unused-vars': ['warn', {
        'argsIgnorePattern': '^_',
        'varsIgnorePattern': '^_',
        'caughtErrorsIgnorePattern': '^_'
      }]
    }
  },
  {
    // Server-specific configuration
    files: ['docs/_server/**/*.js'],
    languageOptions: {
      globals: {
        // Additional Node.js server globals if needed
      }
    },
    rules: {
      'no-console': 'off' // Allow console in server
    }
  },
  {
    // Test files specific configuration
    files: ['**/tests/**/*.js', '**/*.test.js', '**/test/**/*.js'],
    languageOptions: {
      globals: {
        // Vitest globals
        describe: 'readonly',
        it: 'readonly',
        test: 'readonly',
        before: 'readonly',
        after: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
        expect: 'readonly',
        vi: 'readonly',

        // Node.js globals for test context
        require: 'readonly',
        module: 'readonly',
        exports: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',

        // Browser globals for frontend tests
        window: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
        location: 'readonly',
        history: 'readonly',
        fetch: 'readonly',
        localStorage: 'readonly',
        sessionStorage: 'readonly',

        // Browser APIs for tests
        AbortController: 'readonly',
        addEventListener: 'readonly',
        dispatchEvent: 'readonly',
        requestAnimationFrame: 'readonly',
        performance: 'readonly',
        innerHeight: 'readonly',
        innerWidth: 'readonly',

        // CSS APIs for tests
        getComputedStyle: 'readonly',
        CSSRule: 'readonly',
        getEventListeners: 'readonly',

        // DOM APIs for tests
        Element: 'readonly',
        HTMLElement: 'readonly',
        Node: 'readonly',
        Event: 'readonly',
        CustomEvent: 'readonly',
        MouseEvent: 'readonly',
        KeyboardEvent: 'readonly',
        FocusEvent: 'readonly',
        TouchEvent: 'readonly',
        HashChangeEvent: 'readonly',
        EventTarget: 'readonly',
        DOMException: 'readonly',
        MutationObserver: 'readonly',
        ResizeObserver: 'readonly',
        IntersectionObserver: 'readonly',

        // Animation APIs for tests
        cancelAnimationFrame: 'readonly',

        // Web APIs for tests
        Blob: 'readonly',
        URL: 'readonly',
        URLSearchParams: 'readonly',
        FormData: 'readonly',
        Storage: 'readonly',
        StorageEvent: 'readonly',

        // Browser dialogs for tests
        alert: 'readonly',
        confirm: 'readonly',
        prompt: 'readonly',

        // Happy DOM globals for frontend tests
        global: 'readonly'
      }
    },
    rules: {
      'no-unused-expressions': 'off', // Chai assertions use expressions
      'no-console': 'off' // Allow console in tests
    }
  }
];
