
# JavaScript Standards

## Context-Aware Application

**CRITICAL**: Apply standards based on development context:

- **New Projects**: Modern ES6 modules, comprehensive patterns
- **Backend Extensions**: Maintain CommonJS for consistency
- **Frontend Extensions**: Consider existing IIFE patterns, gradually modernize
- **Utility/Shared Code**: Prefer ES6 modules

Testing standards → [javascript-tests.md](./javascript-tests.md)

## Essential Patterns

### Module System Selection

```javascript
// ES6 Modules (preferred)
export const validateEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
export class APIClient { constructor(baseURL) { this.baseURL = baseURL; } }

// CommonJS (backend compatibility)
const FileProcessor = class { constructor(basePath) { this.basePath = basePath; } };
module.exports = FileProcessor;

// IIFE (frontend compatibility)
(function(window) { 'use strict'; window.UtilityLibrary = UtilityLibrary; })(window);
```

### Naming Conventions

```javascript
// Variables and functions: camelCase
const userService = new UserService();
const processUserData = (data) => data.map(item => item.value);

// Constants: UPPER_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_ATTEMPTS = 3;

// Classes: PascalCase
class UserService { constructor(apiClient) { this.apiClient = apiClient; } }

// Private members: underscore prefix
class EventProcessor { _validateInput(data) { return data !== null; } }
```

### Variable Declarations

```javascript
// const for immutable values
const config = { apiUrl: process.env.API_URL, timeout: 5000 };

// let for reassigned values
let currentUser = null;
let retryCount = 0;

// Destructuring with defaults
const { apiUrl, timeout = 3000 } = config;
const [first, second, ...rest] = items;

// Default parameters
function processRequest(data, options = {}) {
  const { validateInput = true, transformOutput = false } = options;
  return transformOutput ? this.transform(data) : data;
}
```

### Error Handling

```javascript
// Custom error classes
class ValidationError extends Error {
  constructor(field, value, message) {
    super(`${field}: ${message} (received: ${value})`);
    this.name = 'ValidationError';
    this.field = field;
    this.value = value;
  }
}

// Async error handling
async function fetchUserData(userId) {
  try {
    const response = await fetch(`/api/users/${userId}`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw new ValidationError('userId', userId, 'User not found');
  }
}
```

### Performance Patterns

```javascript
// Memory management
class ComponentManager {
  constructor(element) {
    this.element = element;
    this._boundClick = this.handleClick.bind(this);
  }

  initialize() { this.element.addEventListener('click', this._boundClick); }
  destroy() {
    this.element.removeEventListener('click', this._boundClick);
    this.element = null;
  }
}

// Async concurrency
async function loadUserProfile(userId) {
  const [profile, settings, preferences] = await Promise.all([
    fetchUserProfile(userId),
    fetchUserSettings(userId),
    fetchUserPreferences(userId)
  ]);
  return combineUserData(profile, settings, preferences);
}

// DOM optimization
function renderList(items) {
  const fragment = document.createDocumentFragment();
  items.forEach(item => {
    const element = document.createElement('div');
    element.textContent = item.name;
    fragment.appendChild(element);
  });
  container.appendChild(fragment);
}
```

### Function Types

```javascript
// Arrow functions: callbacks and functional patterns
const numbers = [1, 2, 3].map(n => n * 2);
const handleClick = (event) => event.preventDefault();

// Function declarations: main functions
function createLogger(options = {}) {
  return { log: (message) => console.log(`[${new Date().toISOString()}] ${message}`) };
}

// Method definitions: classes and objects
class DataProcessor {
  process(data) { return data.filter(item => item.isValid); }
  async save(data) { return await this.database.save(data); }
}
```

## Code Quality

### Documentation Standards

```javascript
/**
 * Validates and processes user input data
 * @param {Object} userData - User data object
 * @param {string} userData.email - User email address
 * @param {Object} options - Processing options
 * @param {boolean} options.strict - Enable strict validation
 * @returns {Promise<Object>} Processed user data
 * @throws {ValidationError} When validation fails
 */
async function processUserData(userData, options = {}) {
  if (!userData.email) throw new ValidationError('email', userData.email, 'Required field');
  return { ...userData, processedAt: new Date().toISOString() };
}
```

### Security Patterns

```javascript
// Input validation
function sanitizeInput(userInput) {
  return userInput.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
}

// Safe object access
function getNestedValue(obj, path, defaultValue = null) {
  return path.split('.').reduce((current, key) => current?.[key], obj) ?? defaultValue;
}
```

## Performance Guidelines

### Memory Management Patterns

- **Event Listener Cleanup**: Always remove event listeners to prevent memory leaks
- **Reference Management**: Clear object references and avoid circular references
- **Closure Optimization**: Be mindful of closure scope to prevent unwanted variable retention
- **Weak References**: Use WeakMap and WeakSet for object associations that shouldn't prevent garbage collection

```javascript
// Good: Proper event listener cleanup
class ComponentManager {
  constructor(element) {
    this.element = element;
    this.handlers = new Map();
    this._boundHandleClick = this.handleClick.bind(this);
  }

  initialize() {
    this.element.addEventListener('click', this._boundHandleClick);
    this.handlers.set('click', this._boundHandleClick);
  }

  destroy() {
    // Good: Clean up event listeners
    this.handlers.forEach((handler, event) => {
      this.element.removeEventListener(event, handler);
    });
    this.handlers.clear();

    // Good: Clear references
    this.element = null;
    this._boundHandleClick = null;
  }
}
```

### Async/Await vs Promise Performance

- **Use async/await for readability**: More readable than Promise chains for complex operations
- **Use Promise.all() for concurrency**: When operations can run in parallel
- **Avoid unnecessary async/await**: Don't wrap synchronous operations
- **Handle rejections properly**: Always use try/catch or .catch()

```javascript
// Good: Proper async patterns
class DataService {
  async fetchUserData(userId) {
    try {
      // Run independent operations concurrently
      const [profile, settings, preferences] = await Promise.all([
        this.fetchUserProfile(userId),
        this.fetchUserSettings(userId),
        this.fetchUserPreferences(userId)
      ]);

      return this.combineUserData(profile, settings, preferences);
    } catch (error) {
      console.error('Failed to fetch user data:', error);
      throw new Error('User data unavailable');
    }
  }

  // Good: Sequential when order matters
  async updateUserProfile(userId, updates) {
    const user = await this.fetchUserProfile(userId);
    const validated = await this.validateUpdates(user, updates);
    return await this.saveUserProfile(userId, validated);
  }
}
```

### DOM Manipulation Optimization

- **Batch DOM updates**: Minimize reflows and repaints
- **Use DocumentFragment**: For multiple element insertions
- **Cache DOM queries**: Store frequently accessed elements
- **Use event delegation**: For dynamic content and better performance

```javascript
// Good: Efficient DOM manipulation
class ListRenderer {
  constructor(containerElement) {
    this.container = containerElement;
    this.cachedElements = new Map();
  }

  renderItems(items) {
    // Good: Use DocumentFragment for batch operations
    const fragment = document.createDocumentFragment();

    items.forEach(item => {
      const element = this.createItemElement(item);
      fragment.appendChild(element);
    });

    // Single DOM update
    this.container.appendChild(fragment);
  }

  createItemElement(item) {
    const element = document.createElement('div');
    element.className = 'list-item';
    element.dataset.id = item.id;
    element.innerHTML = `
      <h3>${this.escapeHtml(item.title)}</h3>
      <p>${this.escapeHtml(item.description)}</p>
    `;
    return element;
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}
```

## Code Conventions and Styles

### Module System Selection (Project-Wide Standards)

#### ES6 Modules (Preferred for New Code)

- **When to Use**: New utility modules, shared libraries, modern frontend components
- **File Extensions**: Use `.js` for ES6 modules with proper package.json configuration
- **Import/Export**: Use named exports by default, default exports sparingly

```javascript
// Good: ES6 module exports
export const validateEmail = (email) => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

export const formatCurrency = (amount, currency = 'USD') => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency
  }).format(amount);
};

export class APIClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
  }
}
```

#### CommonJS (Use for Backend Consistency)

- **When to Use**: Extending existing backend code (docs/_server/), maintaining compatibility
- **File Extensions**: Use `.js` with CommonJS patterns in Node.js environments
- **Module Exports**: Use module.exports for main exports, exports.* for utilities

```javascript
// Good: CommonJS patterns for backend
const path = require('path');
const fs = require('fs').promises;

class FileProcessor {
  constructor(basePath) {
    this.basePath = basePath;
  }

  async processFile(filename) {
    const filePath = path.join(this.basePath, filename);
    return await fs.readFile(filePath, 'utf8');
  }
}

module.exports = FileProcessor;
```

#### IIFE (Maintain for Frontend Compatibility)

- **When to Use**: Extending existing frontend code that uses IIFE patterns
- **Global Variables**: Minimize global namespace pollution
- **Compatibility**: Ensure compatibility with existing scripts

```javascript
// Good: IIFE pattern for frontend compatibility
(function(window) {
  'use strict';

  function UtilityLibrary() {
    this.version = '1.0.0';
  }

  UtilityLibrary.prototype.formatDate = function(date) {
    return date.toLocaleDateString();
  };

  // Expose to global scope responsibly
  window.UtilityLibrary = UtilityLibrary;
})(window);
```

### Naming Conventions (Code Standards)

- **Variables**: Use camelCase for variables and functions
- **Constants**: Use UPPER_SNAKE_CASE for module-level constants
- **Classes**: Use PascalCase for class names
- **Private Members**: Use underscore prefix for private/internal methods
- **Files**: Use kebab-case for file names

```javascript
// Good: Consistent naming conventions
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_ATTEMPTS = 3;

class UserService {
  constructor(apiClient) {
    this.apiClient = apiClient;
    this._cache = new Map();
  }

  async fetchUserById(userId) {
    return await this._getFromCacheOrFetch(userId);
  }

  _getFromCacheOrFetch(key) {
    // Private method implementation
  }
}
```

### Function Declarations

- **Arrow Functions**: Use for short callbacks and functional patterns
- **Function Declarations**: Use for main functions that may be hoisted
- **Method Definitions**: Use concise method syntax in classes and objects
- **Async Functions**: Always use async/await for asynchronous operations

```javascript
// Good: Appropriate function types
class EventProcessor {
  // Method definition
  processEvents(events) {
    return events
      .filter(event => event.isValid) // Arrow function for callback
      .map(event => this.transformEvent(event));
  }

  // Async method
  async saveEvents(events) {
    try {
      return await this.database.saveMany(events);
    } catch (error) {
      this.logger.error('Failed to save events:', error);
      throw error;
    }
  }
}

// Function declaration for utilities
function createLogger(options = {}) {
  return {
    log: (message) => console.log(`[${new Date().toISOString()}] ${message}`),
    error: (message, error) => console.error(`[ERROR] ${message}`, error)
  };
}
```

### Variable Declarations (Best Practices)

- **const**: Use for values that won't be reassigned
- **let**: Use for variables that will be reassigned
- **var**: Avoid in new code, only use when maintaining legacy code
- **Destructuring**: Use for extracting values from objects and arrays

```javascript
// Good: Proper variable declarations
const config = {
  apiUrl: process.env.API_URL,
  timeout: 5000
};

let currentUser = null;
let retryCount = 0;

// Good: Destructuring
const { apiUrl, timeout } = config;
const [first, second, ...rest] = items;

// Good: Default parameters
function processRequest(data, options = {}) {
  const { validateInput = true, transformOutput = false } = options;

  if (validateInput) {
    // Validation logic
  }

  return transformOutput ? this.transform(data) : data;
}
```

### Error Handling and Try/Catch Best Practices

- **Specific Error Types**: Create custom error classes for different scenarios
- **Error Context**: Include relevant context information in error messages
- **Graceful Degradation**: Handle errors gracefully with fallback behavior
- **Logging**: Log errors with appropriate detail level

```javascript
// Good: Custom error classes
class ValidationError extends Error {
  constructor(field, value, message) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.value = value;
  }
}

class APIError extends Error {
  constructor(status, message, originalError = null) {
    super(message);
    this.name = 'APIError';
    this.status = status;
    this.originalError = originalError;
  }
}

// Good: Comprehensive error handling
class UserController {
  async createUser(userData) {
    try {
      // Validation
      this.validateUserData(userData);

      // Business logic
      const user = await this.userService.create(userData);

      return {
        success: true,
        data: user
      };
    } catch (error) {
      if (error instanceof ValidationError) {
        return {
          success: false,
          error: {
            type: 'validation',
            field: error.field,
            message: error.message
          }
        };
      }

      if (error instanceof APIError) {
        this.logger.error('API error during user creation:', error);
        return {
          success: false,
          error: {
            type: 'api',
            message: 'Service temporarily unavailable'
          }
        };
      }

      // Unexpected error
      this.logger.error('Unexpected error during user creation:', error);
      return {
        success: false,
        error: {
          type: 'internal',
          message: 'An unexpected error occurred'
        }
      };
    }
  }
}
```

### JSDoc Documentation Standards

- **Function Documentation**: Document all public functions with parameters and return values
- **Class Documentation**: Document class purpose, constructor parameters, and public methods
- **Type Information**: Include type information for better IDE support
- **Examples**: Provide usage examples for complex functions

```javascript
/**
 * Manages user authentication and session handling
 * @class
 */
class AuthManager {
  /**
   * Creates an instance of AuthManager
   * @param {Object} options - Configuration options
   * @param {string} options.apiUrl - Base API URL for authentication
   * @param {number} [options.sessionTimeout=3600] - Session timeout in seconds
   * @param {Function} [options.onSessionExpired] - Callback for session expiration
   */
  constructor(options = {}) {
    this.apiUrl = options.apiUrl;
    this.sessionTimeout = options.sessionTimeout || 3600;
    this.onSessionExpired = options.onSessionExpired || (() => {});
  }

  /**
   * Authenticates a user with credentials
   * @param {Object} credentials - User credentials
   * @param {string} credentials.username - Username or email
   * @param {string} credentials.password - User password
   * @returns {Promise<Object>} Authentication result
   * @throws {ValidationError} When credentials are invalid
   * @throws {APIError} When authentication service fails
   *
   * @example
   * const authManager = new AuthManager({ apiUrl: '/api' });
   * try {
   *   const result = await authManager.authenticate({
   *     username: 'user@example.com',
   *     password: 'securepassword'
   *   });
   *   console.log('Authenticated:', result.user);
   * } catch (error) {
   *   console.error('Authentication failed:', error.message);
   * }
   */
  async authenticate(credentials) {
    // Implementation
  }
}
```

## Architecture and Design Patterns

### Separation of Concerns

- **Single Responsibility**: Each module/class should have one reason to change
- **Dependency Injection**: Pass dependencies rather than creating them internally
- **Interface Segregation**: Create focused interfaces rather than large ones
- **Configuration Management**: Externalize configuration from business logic

```javascript
// Good: Separated concerns
class OrderService {
  constructor(paymentService, inventoryService, notificationService, logger) {
    this.paymentService = paymentService;
    this.inventoryService = inventoryService;
    this.notificationService = notificationService;
    this.logger = logger;
  }

  async processOrder(orderData) {
    try {
      // Each service handles its own responsibility
      await this.inventoryService.reserveItems(orderData.items);
      const payment = await this.paymentService.processPayment(orderData.payment);
      const order = await this.createOrder(orderData, payment);
      await this.notificationService.sendOrderConfirmation(order);

      return order;
    } catch (error) {
      this.logger.error('Order processing failed:', error);
      throw error;
    }
  }
}
```

### Factory and Builder Patterns

- **Factory Pattern**: Create objects without specifying their exact classes
- **Builder Pattern**: Construct complex objects step by step
- **Abstract Factory**: Create families of related objects
- **Configuration Objects**: Use objects for complex parameter passing

```javascript
// Good: Factory pattern for creating API clients
class APIClientFactory {
  static create(type, config) {
    switch (type) {
      case 'rest':
        return new RESTAPIClient(config);
      case 'graphql':
        return new GraphQLAPIClient(config);
      case 'websocket':
        return new WebSocketAPIClient(config);
      default:
        throw new Error(`Unknown API client type: ${type}`);
    }
  }
}

// Good: Builder pattern for complex configurations
class QueryBuilder {
  constructor() {
    this.query = {
      select: [],
      from: null,
      where: [],
      orderBy: [],
      limit: null
    };
  }

  select(...fields) {
    this.query.select.push(...fields);
    return this;
  }

  from(table) {
    this.query.from = table;
    return this;
  }

  where(condition) {
    this.query.where.push(condition);
    return this;
  }

  orderBy(field, direction = 'ASC') {
    this.query.orderBy.push({ field, direction });
    return this;
  }

  limit(count) {
    this.query.limit = count;
    return this;
  }

  build() {
    return { ...this.query };
  }
}

// Usage
const query = new QueryBuilder()
  .select('id', 'name', 'email')
  .from('users')
  .where('active = true')
  .orderBy('created_at', 'DESC')
  .limit(10)
  .build();
```

This concludes the JavaScript coding standards document. For comprehensive testing standards, patterns, and examples, refer to [javascript-tests.md](./javascript-tests.md).
