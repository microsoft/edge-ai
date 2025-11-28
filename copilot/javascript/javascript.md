# JavaScript Instructions

## Framework Standards

**Testing**: Vitest + Happy DOM for all JavaScript testing
**Modules**: ES6 modules preferred, CommonJS for legacy compatibility
**Package Manager**: npm with package-lock.json

## Project Structure

```plaintext
package.json           # Dependencies and scripts
src/                   # Source code
  index.js            # Entry point
  modules/            # Application modules
tests/                # Test files (.test.js)
.eslintrc.json        # Linting configuration
```

## Essential Dependencies

### Install Vitest Testing Stack

```bash
npm install --save-dev vitest happy-dom @vitest/coverage-v8
npm uninstall mocha chai sinon nyc jest  # Remove legacy testing
```

### Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage"
  }
}
```

## Module System Selection

### ES6 Modules (Preferred)

```javascript
// Export
export const utils = { formatDate: (date) => date.toISOString() };
export default class APIClient { constructor(baseURL) { this.baseURL = baseURL; } }

// Import
import APIClient, { utils } from './api.js';
```

### CommonJS (Backend Compatibility)

```javascript
// Export
const FileProcessor = class { constructor(basePath) { this.basePath = basePath; } };
module.exports = FileProcessor;

// Import
const FileProcessor = require('./file-processor');
```

## Context-Aware Application

- **New Projects**: Use ES6 modules and modern patterns
- **Backend Extensions**: Maintain CommonJS for consistency
- **Frontend Extensions**: Consider existing patterns, gradually modernize
- **Shared/Utility Code**: Prefer ES6 modules

## Development Contexts

### Backend (Node.js)

- Use Express.js for APIs
- Environment variables for configuration
- Proper error handling and logging
- RESTful API design

### Frontend

- Modern JavaScript (ES2015+)
- DOM manipulation best practices
- Async/await for promises
- Event delegation patterns

For detailed coding standards → [javascript-standards.md](./javascript-standards.md)
For comprehensive testing patterns → [javascript-tests.md](./javascript-tests.md)
