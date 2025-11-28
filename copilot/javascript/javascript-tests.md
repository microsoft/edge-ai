# JavaScript Testing Standards

## Overview

**Project Standard**: Use Vitest + Happy DOM for all JavaScript testing to maintain consistency and modern development practices.

This document defines comprehensive testing standards for JavaScript projects, covering both frontend and backend testing with modern tools and best practices.

## Framework Selection

### Vitest + Happy DOM Standard Testing Framework

| Use Case                                               | Framework              | Rationale                                                             |
|--------------------------------------------------------|------------------------|-----------------------------------------------------------------------|
| Unit tests for services, utilities, and business logic | **Vitest**             | Fast execution, excellent ESM support, built-in TypeScript support    |
| Backend API integration tests                          | **Vitest**             | Superior async handling, flexible assertion libraries, fast execution |
| Frontend component testing                             | **Vitest + Happy DOM** | Lightning-fast browser environment simulation, modern features        |
| Database integration tests                             | **Vitest**             | Setup/teardown control, timeout management, better performance        |
| Simple function/module testing                         | **Vitest**             | Consistent framework across all test types, zero-config setup         |
| Complex async workflows                                | **Vitest**             | Fine-grained control over test lifecycle, excellent async support     |

## Test Organization and Structure

### Directory Structure

```text
tests/
├── unit/          # Vitest unit tests
│   ├── services/
│   ├── utils/
│   └── models/
├── integration/   # Vitest integration tests
│   ├── api/
│   ├── database/
│   └── components/
├── frontend/      # Vitest frontend tests with Happy DOM
│   ├── components/
│   ├── utils/
│   └── ui/
└── helpers/       # Shared test utilities
    ├── fixtures/
    ├── mocks/
    └── test-setup.js
```

### File Naming Conventions

- **File Naming**: `[module-name].test.js` for Vitest testing
- **Test Suites**: Use descriptive `describe` blocks following module structure
- **Test Cases**: Use clear, behavior-driven `it` statements

## Configuration

### Vitest Configuration

```javascript
// Good: Vitest configuration (vitest.config.js)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: [
      "tests/unit/**/*.test.js",
      "tests/integration/**/*.test.js",
      "tests/frontend/**/*.test.js"
    ],
    setupFiles: ["./tests/helpers/vitest-setup.js"],
    environment: 'happy-dom',
    globals: true,
    testTimeout: 10000
  }
});
```

### Test Setup File

```javascript
// Good: Test setup (tests/helpers/vitest-setup.js)
import { beforeEach, afterEach, vi } from 'vitest';

// Global test setup
beforeEach(() => {
  // Reset all mocks before each test
  vi.clearAllMocks();
});

afterEach(() => {
  // Clean up after each test
  vi.restoreAllMocks();
});

// Mock global APIs
global.localStorage = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn()
};

global.fetch = vi.fn();
```

## Backend Testing Standards

### Unit Testing Patterns

```javascript
// Good: Backend unit test (tests/unit/services/user-service.test.js)
import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import { UserService } from '../../../src/services/user-service.js';
import { ValidationError, DatabaseError } from '../../../src/errors/index.js';

/**
 * UserService Unit Tests
 * Tests business logic in isolation with comprehensive mocking
 */
describe('UserService', () => {
  let userService;
  let mockRepository;
  let mockValidator;

  beforeEach(() => {
    // Create mocks with Vitest
    mockRepository = {
      findById: vi.fn(),
      save: vi.fn(),
      delete: vi.fn()
    };

    mockValidator = {
      validateUserData: vi.fn(),
      validateEmail: vi.fn()
    };

    userService = new UserService(mockRepository, mockValidator);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = { name: 'John Doe', email: 'john@example.com' };
      const expectedUser = { id: 1, ...userData };

      mockValidator.validateUserData.mockReturnValue(true);
      mockRepository.save.mockResolvedValue(expectedUser);

      // Act
      const result = await userService.createUser(userData);

      // Assert
      expect(result).toEqual(expectedUser);
      expect(mockValidator.validateUserData).toHaveBeenCalledWith(userData);
      expect(mockRepository.save).toHaveBeenCalledWith(userData);
    });

    it('should throw ValidationError for invalid data', async () => {
      // Arrange
      const invalidData = { name: '', email: 'invalid-email' };
      mockValidator.validateUserData.mockImplementation(() => {
        throw new ValidationError('Invalid user data');
      });

      // Act & Assert
      await expect(userService.createUser(invalidData)).rejects.toThrow(ValidationError);
      expect(mockRepository.save).not.toHaveBeenCalled();
    });

    it('should handle database errors gracefully', async () => {
      // Arrange
      const userData = { name: 'John Doe', email: 'john@example.com' };
      const dbError = new Error('Database connection failed');

      mockValidator.validateUserData.mockReturnValue(true);
      mockRepository.save.mockRejectedValue(dbError);

      // Act & Assert
      await expect(userService.createUser(userData)).rejects.toThrow(DatabaseError);
    });
  });
});
```

### Integration Testing Patterns

```javascript
// Good: Backend integration test (tests/integration/api/users.test.js)
import { expect, describe, it, beforeAll, afterAll, beforeEach, afterEach, vi } from 'vitest';
import request from 'supertest';
import app from '../../../src/app.js';
import { database } from '../../../src/config/database.js';
import { testHelpers } from '../../helpers/test-helpers.js';

/**
 * User API Integration Tests
 * Tests complete request/response cycle with real database
 */
describe('User API Integration Tests', () => {
  let testUser;

  beforeAll(async () => {
    // One-time setup for the entire test suite
    await database.connect();
    await database.migrate.latest();
  });

  afterAll(async () => {
    // One-time teardown
    await database.destroy();
  });

  beforeEach(async () => {
    // Fresh state for each test
    await testHelpers.clearDatabase();

    testUser = await testHelpers.createTestUser({
      name: 'Test User',
      email: 'test@example.com'
    });
  });

  afterEach(async () => {
    // Clean up after each test
    vi.restoreAllMocks();
  });

  describe('POST /api/users', () => {
    const validUserData = {
      name: 'New User',
      email: 'new@example.com',
      password: 'securepassword123'
    };

    it('should create user with valid data', async () => {
      const response = await request(app)
        .post('/api/users')
        .send(validUserData)
        .expect(201);

      expect(response.body).toMatchObject({
        success: true,
        data: expect.objectContaining({
          name: validUserData.name,
          email: validUserData.email
        })
      });

      expect(response.body.data).not.toHaveProperty('password');
    });

    it('should return 400 for invalid email', async () => {
      const invalidData = { ...validUserData, email: 'invalid-email' };

      const response = await request(app)
        .post('/api/users')
        .send(invalidData)
        .expect(400);

      expect(response.body).toMatchObject({
        success: false,
        error: expect.stringContaining('email')
      });
    });

    it('should return 409 for duplicate email', async () => {
      const duplicateData = { ...validUserData, email: testUser.email };

      const response = await request(app)
        .post('/api/users')
        .send(duplicateData)
        .expect(409);

      expect(response.body).toMatchObject({
        success: false,
        error: expect.stringContaining('already exists')
      });
    });
  });

  describe('GET /api/users/:id', () => {
    it('should return user by ID', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser.id}`)
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        data: expect.objectContaining({
          id: testUser.id,
          name: testUser.name,
          email: testUser.email
        })
      });
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/users/99999')
        .expect(404);

      expect(response.body).toMatchObject({
        success: false,
        error: expect.stringContaining('not found')
      });
    });
  });
});
```

## Frontend Testing Standards

### Component Testing with Happy DOM

```javascript
// Good: Frontend component test (tests/frontend/components/progress-tracker.test.js)
import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import { ProgressTracker, ProgressTrackerError } from '../../../src/components/progress-tracker.js';

/**
 * ProgressTracker Component Tests
 * Tests component behavior in browser environment with Happy DOM
 */
describe('ProgressTracker Component', () => {
  let container;
  let progressTracker;

  beforeEach(() => {
    // Setup DOM container with Happy DOM
    container = document.createElement('div');
    container.id = 'test-container';
    document.body.appendChild(container);

    // Mock localStorage with Vitest
    const localStorageMock = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn()
    };

    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true
    });

    progressTracker = new ProgressTracker(container);
  });

  afterEach(() => {
    // Clean up DOM
    container.remove();
    vi.restoreAllMocks();
  });

  describe('initialization', () => {
    it('should initialize with default options', () => {
      expect(progressTracker.container).toBe(container);
      expect(progressTracker.steps).toEqual([]);
      expect(progressTracker.currentStep).toBe(0);
    });

    it('should initialize with custom options', () => {
      const options = {
        steps: ['Step 1', 'Step 2', 'Step 3'],
        currentStep: 1
      };

      const customTracker = new ProgressTracker(container, options);

      expect(customTracker.steps).toEqual(options.steps);
      expect(customTracker.currentStep).toBe(options.currentStep);
    });

    it('should throw error with invalid container', () => {
      expect(() => new ProgressTracker(null)).toThrow(ProgressTrackerError);
      expect(() => new ProgressTracker(undefined)).toThrow(ProgressTrackerError);
    });
  });

  describe('step management', () => {
    beforeEach(() => {
      progressTracker.setSteps(['Start', 'Middle', 'End']);
    });

    it('should add step correctly', () => {
      progressTracker.addStep('New Step');
      expect(progressTracker.steps).toHaveLength(4);
      expect(progressTracker.steps[3]).toBe('New Step');
    });

    it('should navigate to next step', () => {
      progressTracker.nextStep();
      expect(progressTracker.currentStep).toBe(1);

      progressTracker.nextStep();
      expect(progressTracker.currentStep).toBe(2);
    });

    it('should not exceed total steps', () => {
      progressTracker.currentStep = 2;
      progressTracker.nextStep();
      expect(progressTracker.currentStep).toBe(2);
    });

    it('should navigate to previous step', () => {
      progressTracker.currentStep = 2;
      progressTracker.previousStep();
      expect(progressTracker.currentStep).toBe(1);
    });

    it('should not go below step 0', () => {
      progressTracker.previousStep();
      expect(progressTracker.currentStep).toBe(0);
    });
  });

  describe('DOM rendering', () => {
    beforeEach(() => {
      progressTracker.setSteps(['Step 1', 'Step 2', 'Step 3']);
    });

    it('should render progress tracker in DOM', () => {
      progressTracker.render();

      const progressElement = container.querySelector('.progress-tracker');
      expect(progressElement).toBeTruthy();
      expect(progressElement.children).toHaveLength(3);
    });

    it('should highlight current step', () => {
      progressTracker.currentStep = 1;
      progressTracker.render();

      const steps = container.querySelectorAll('.progress-step');
      expect(steps[0]).toHaveClass('completed');
      expect(steps[1]).toHaveClass('current');
      expect(steps[2]).not.toHaveClass('current');
      expect(steps[2]).not.toHaveClass('completed');
    });

    it('should handle click events on steps', () => {
      const clickHandler = vi.fn();
      progressTracker.onStepClick = clickHandler;
      progressTracker.render();

      const secondStep = container.querySelector('.progress-step:nth-child(2)');
      secondStep.click();

      expect(clickHandler).toHaveBeenCalledWith(1);
    });
  });

  describe('persistence', () => {
    it('should save progress to localStorage', () => {
      progressTracker.setSteps(['Step 1', 'Step 2']);
      progressTracker.currentStep = 1;
      progressTracker.saveProgress();

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'progress-tracker-state',
        JSON.stringify({
          steps: ['Step 1', 'Step 2'],
          currentStep: 1
        })
      );
    });

    it('should load progress from localStorage', () => {
      const savedState = {
        steps: ['Saved Step 1', 'Saved Step 2'],
        currentStep: 1
      };

      localStorage.getItem.mockReturnValue(JSON.stringify(savedState));
      progressTracker.loadProgress();

      expect(progressTracker.steps).toEqual(savedState.steps);
      expect(progressTracker.currentStep).toBe(savedState.currentStep);
    });

    it('should handle corrupted localStorage data', () => {
      localStorage.getItem.mockReturnValue('invalid-json');

      expect(() => progressTracker.loadProgress()).not.toThrow();
      expect(progressTracker.steps).toEqual([]);
      expect(progressTracker.currentStep).toBe(0);
    });
  });
});
```

### API Client Testing

```javascript
// Good: API client test (tests/frontend/utils/api-client.test.js)
import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import { APIClient, APIError } from '../../../src/utils/api-client.js';

/**
 * APIClient Tests
 * Tests HTTP client functionality with mocked fetch
 */
describe('APIClient', () => {
  let apiClient;
  let mockFetch;

  beforeEach(() => {
    mockFetch = vi.fn();
    global.fetch = mockFetch;
    apiClient = new APIClient('https://api.example.com');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('GET requests', () => {
    it('should make successful GET request', async () => {
      const mockData = { id: 1, name: 'Test User' };
      mockFetch.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve(mockData)
      });

      const result = await apiClient.get('/users/1');

      expect(result).toEqual(mockData);
      expect(mockFetch).toHaveBeenCalledWith(
        'https://api.example.com/users/1',
        expect.objectContaining({
          method: 'GET',
          headers: expect.objectContaining({
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          })
        })
      );
    });

    it('should handle 404 errors', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 404,
        statusText: 'Not Found',
        json: () => Promise.resolve({ error: 'User not found' })
      });

      await expect(apiClient.get('/users/999')).rejects.toThrow(APIError);
      await expect(apiClient.get('/users/999')).rejects.toThrow('User not found');
    });

    it('should handle network errors', async () => {
      mockFetch.mockRejectedValue(new Error('Network error'));

      await expect(apiClient.get('/users/1')).rejects.toThrow('Network error');
    });
  });

  describe('POST requests', () => {
    it('should make successful POST request', async () => {
      const postData = { name: 'New User', email: 'new@example.com' };
      const responseData = { id: 2, ...postData };

      mockFetch.mockResolvedValue({
        ok: true,
        status: 201,
        json: () => Promise.resolve(responseData)
      });

      const result = await apiClient.post('/users', postData);

      expect(result).toEqual(responseData);
      expect(mockFetch).toHaveBeenCalledWith(
        'https://api.example.com/users',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(postData),
          headers: expect.objectContaining({
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          })
        })
      );
    });

    it('should handle validation errors', async () => {
      const invalidData = { name: '', email: 'invalid' };
      mockFetch.mockResolvedValue({
        ok: false,
        status: 400,
        json: () => Promise.resolve({
          error: 'Validation failed',
          details: ['Name is required', 'Email is invalid']
        })
      });

      await expect(apiClient.post('/users', invalidData)).rejects.toThrow(APIError);
    });
  });

  describe('request timeout handling', () => {
    it('should timeout long requests', async () => {
      const slowApiClient = new APIClient('https://api.example.com', {
        timeout: 100
      });

      mockFetch.mockImplementation(() =>
        new Promise(resolve => setTimeout(resolve, 200))
      );

      await expect(slowApiClient.get('/slow-endpoint')).rejects.toThrow('timeout');
    });
  });
});
```

## Mocking and Test Utilities

### Vitest Mocking Patterns

```javascript
// Good: Comprehensive mocking examples
import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';

describe('Mocking Examples', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Function Mocking', () => {
    it('should mock functions with vi.fn()', () => {
      const mockFn = vi.fn();
      mockFn.mockReturnValue('mocked value');

      const result = mockFn('test');

      expect(result).toBe('mocked value');
      expect(mockFn).toHaveBeenCalledWith('test');
      expect(mockFn).toHaveBeenCalledTimes(1);
    });

    it('should mock async functions', async () => {
      const mockAsyncFn = vi.fn().mockResolvedValue('async result');

      const result = await mockAsyncFn();

      expect(result).toBe('async result');
      expect(mockAsyncFn).toHaveBeenCalled();
    });

    it('should mock rejected promises', async () => {
      const mockAsyncFn = vi.fn().mockRejectedValue(new Error('Async error'));

      await expect(mockAsyncFn()).rejects.toThrow('Async error');
    });
  });

  describe('Object and Method Mocking', () => {
    it('should spy on object methods', () => {
      const obj = {
        method: () => 'original'
      };

      const spy = vi.spyOn(obj, 'method').mockReturnValue('mocked');

      const result = obj.method();

      expect(result).toBe('mocked');
      expect(spy).toHaveBeenCalled();
    });

    it('should mock entire modules', async () => {
      // Mock external module
      vi.mock('../../../src/services/email-service.js', () => ({
        EmailService: vi.fn().mockImplementation(() => ({
          sendEmail: vi.fn().mockResolvedValue({ messageId: 'test-id' })
        }))
      }));

      const { EmailService } = await import('../../../src/services/email-service.js');
      const emailService = new EmailService();

      const result = await emailService.sendEmail('test@example.com', 'Subject', 'Body');

      expect(result).toEqual({ messageId: 'test-id' });
      expect(emailService.sendEmail).toHaveBeenCalledWith('test@example.com', 'Subject', 'Body');
    });
  });

  describe('Timer Mocking', () => {
    it('should mock timers', () => {
      vi.useFakeTimers();
      const callback = vi.fn();

      setTimeout(callback, 1000);
      vi.advanceTimersByTime(1000);

      expect(callback).toHaveBeenCalled();

      vi.useRealTimers();
    });
  });
});
```

### Test Helper Utilities

```javascript
// Good: Test helpers (tests/helpers/test-helpers.js)
import { database } from '../../src/config/database.js';
import { UserService } from '../../src/services/user-service.js';

/**
 * Test Helper Utilities
 * Shared utilities for test setup, data creation, and assertions
 */

/**
 * Database helper utilities
 */
export const testHelpers = {
  /**
   * Clear all test data from database tables
   * @param {string[]} tables - Tables to clear (optional, defaults to all)
   */
  async clearTables(tables = ['users', 'user_sessions', 'audit_logs']) {
    for (const table of tables) {
      await database(table).del();
    }
  },

  /**
   * Clear entire database
   */
  async clearDatabase() {
    await database.raw('TRUNCATE TABLE users, user_sessions, audit_logs RESTART IDENTITY CASCADE');
  },

  /**
   * Create test user with default or custom data
   * @param {Object} userData - Custom user data
   * @returns {Object} Created user object
   */
  async createTestUser(userData = {}) {
    const defaultUser = {
      name: 'Test User',
      email: `test-${Date.now()}@example.com`,
      password: 'testpassword123',
      isActive: true,
      createdAt: new Date()
    };

    const user = { ...defaultUser, ...userData };
    const [createdUser] = await database('users').insert(user).returning('*');
    return createdUser;
  },

  /**
   * Create multiple test users
   * @param {number} count - Number of users to create
   * @param {Object} baseData - Base data for all users
   * @returns {Object[]} Array of created users
   */
  async createTestUsers(count = 3, baseData = {}) {
    const users = [];
    for (let i = 0; i < count; i++) {
      const userData = {
        ...baseData,
        name: `Test User ${i + 1}`,
        email: `test-user-${i + 1}-${Date.now()}@example.com`
      };
      users.push(await this.createTestUser(userData));
    }
    return users;
  },

  /**
   * Wait for async operations to complete
   * @param {number} ms - Milliseconds to wait
   */
  async wait(ms = 10) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
};

/**
 * Mock factory utilities
 */
export const mockFactories = {
  /**
   * Create mock database with common methods
   * @returns {Object} Mock database object
   */
  createMockDatabase() {
    return {
      users: {
        findById: vi.fn(),
        findByEmail: vi.fn(),
        save: vi.fn(),
        delete: vi.fn(),
        update: vi.fn()
      },
      query: vi.fn(),
      transaction: vi.fn(),
      raw: vi.fn()
    };
  },

  /**
   * Create mock logger
   * @returns {Object} Mock logger object
   */
  createMockLogger() {
    return {
      info: vi.fn(),
      error: vi.fn(),
      warn: vi.fn(),
      debug: vi.fn()
    };
  },

  /**
   * Create mock HTTP request object
   * @param {Object} data - Request data
   * @returns {Object} Mock request object
   */
  createMockRequest(data = {}) {
    return {
      body: data.body || {},
      params: data.params || {},
      query: data.query || {},
      headers: data.headers || {},
      user: data.user || null,
      ip: data.ip || '127.0.0.1',
      ...data
    };
  },

  /**
   * Create mock HTTP response object
   * @returns {Object} Mock response object
   */
  createMockResponse() {
    const res = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn().mockReturnThis(),
      send: vi.fn().mockReturnThis(),
      redirect: vi.fn().mockReturnThis(),
      cookie: vi.fn().mockReturnThis(),
      header: vi.fn().mockReturnThis()
    };
    return res;
  }
};

/**
 * Assertion helper utilities
 */
export const assertionHelpers = {
  /**
   * Assert API response structure
   * @param {Object} response - Response to validate
   * @param {Object} expectedData - Expected data structure
   */
  expectValidApiResponse(response, expectedData = {}) {
    expect(response).toHaveProperty('success');
    expect(response).toHaveProperty('data');

    if (expectedData) {
      expect(response.data).toMatchObject(expectedData);
    }
  },

  /**
   * Assert error response structure
   * @param {Object} response - Error response to validate
   * @param {string} expectedError - Expected error message
   */
  expectValidErrorResponse(response, expectedError) {
    expect(response).toHaveProperty('success', false);
    expect(response).toHaveProperty('error');

    if (expectedError) {
      expect(response.error).toContain(expectedError);
    }
  },

  /**
   * Assert database record matches expected data
   * @param {Object} record - Database record
   * @param {Object} expectedData - Expected data
   */
  expectValidDatabaseRecord(record, expectedData) {
    expect(record).toBeTruthy();
    expect(record).toMatchObject(expectedData);
    expect(record).toHaveProperty('id');
    expect(record).toHaveProperty('createdAt');
  }
};
```

## Best Practices

### Test Structure and Organization

- **Descriptive Names**: Use clear, behavior-driven test names
- **AAA Pattern**: Follow Arrange-Act-Assert pattern consistently
- **Single Responsibility**: Each test should verify one specific behavior
- **Test Independence**: Tests should not depend on each other

### Mocking Strategy

- **Mock External Dependencies**: Always mock external services, APIs, and databases
- **Test Boundaries**: Mock at the edges of your system, not internal logic
- **Realistic Mocks**: Ensure mocks behave like real implementations
- **Mock Cleanup**: Always restore mocks after tests

### Assertion Guidelines

- **Specific Assertions**: Use the most specific assertion available
- **Error Testing**: Test both success and failure scenarios
- **Edge Cases**: Include tests for boundary conditions and edge cases
- **Performance**: Consider performance implications in integration tests

### Documentation

- **Test Purpose**: Document why tests exist, not just what they do
- **Complex Logic**: Explain non-obvious test setup or assertions
- **Coverage Notes**: Document intentionally untested scenarios
- **Maintenance**: Keep test documentation up-to-date with code changes

## Common Patterns and Examples

### Testing Async Operations

```javascript
describe('Async Operations', () => {
  it('should handle concurrent operations', async () => {
    const promises = [
      apiClient.get('/resource/1'),
      apiClient.get('/resource/2'),
      apiClient.get('/resource/3')
    ];

    const results = await Promise.all(promises);

    expect(results).toHaveLength(3);
    results.forEach(result => {
      expect(result).toHaveProperty('id');
    });
  });

  it('should handle async errors properly', async () => {
    const errorService = {
      riskyOperation: vi.fn().mockRejectedValue(new Error('Operation failed'))
    };

    await expect(errorService.riskyOperation()).rejects.toThrow('Operation failed');
  });
});
```

### Testing Event-Driven Code

```javascript
describe('Event-Driven Code', () => {
  it('should handle custom events', () => {
    const eventHandler = vi.fn();
    const component = new EventComponent();

    component.addEventListener('custom-event', eventHandler);
    component.triggerEvent('custom-event', { data: 'test' });

    expect(eventHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        detail: { data: 'test' }
      })
    );
  });
});
```

### Testing Form Interactions

```javascript
describe('Form Interactions', () => {
  it('should validate form submission', () => {
    const form = document.createElement('form');
    const nameInput = document.createElement('input');
    nameInput.name = 'name';
    nameInput.value = 'John Doe';
    form.appendChild(nameInput);

    const validator = new FormValidator(form);
    const result = validator.validate();

    expect(result.isValid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });
});
```

This testing standards document provides comprehensive guidelines for JavaScript testing using Vitest and Happy DOM, covering both frontend and backend scenarios with practical examples and best practices.
