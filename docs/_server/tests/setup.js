/**
 * Test Setup and Configuration
 * Global test setup for Vitest tests with ES6 modules
 */

import { vi } from 'vitest';
import process from 'process';
import { mockConsole, restoreConsole } from './helpers/console-mock.js';

// Set test environment
process.env.NODE_ENV = 'test';
process.env.PORT = '0'; // Use random port for tests
process.env.HOST = 'localhost';

// Global test configuration
globalThis.testConfig = {
  timeout: 5000,
  port: 0,
  host: 'localhost'
};

// Global test utilities
globalThis.sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Configure console mocking for performance
globalThis.setupConsoleMocking = () => {
  beforeEach(() => {
    mockConsole();
  });

  afterEach(() => {
    restoreConsole();
  });
};

// Configure Vitest mocks and utilities
vi.stubEnv('NODE_ENV', 'test');

// Configure process for clean test exits (but don't exit during tests)
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception in tests:', err);
  // Don't exit during tests - let Vitest handle it
});

process.on('unhandledRejection', (reason, _promise) => {
  console.error('Unhandled Rejection in tests:', reason);
  // Don't exit during tests - let Vitest handle it
});

console.log('Test environment initialized with Vitest and console mocking');
