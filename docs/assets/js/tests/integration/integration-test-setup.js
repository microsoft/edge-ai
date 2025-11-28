import { vi } from 'vitest';

// Global test setup for integration tests
global.URL = class URL {
  constructor(url) {
    this.href = url;
    this.origin = 'http://localhost';
    this.pathname = url.replace('http://localhost', '');
  }
};

// Mock Blob for file export tests
global.Blob = class Blob {
  constructor(parts, _options) {
    this.parts = parts;
    this.type = _options?.type || '';
    this.size = parts.reduce((acc, part) => acc + part.length, 0);
  }
};

// Mock createObjectURL
global.URL.createObjectURL = vi.fn(() => 'blob:mock-url');
global.URL.revokeObjectURL = vi.fn();

// Mock localStorage
global.localStorage = {
  getItem: vi.fn(() => null),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
};

// Mock document.createElement for dynamic link creation
const originalCreateElement = global.document?.createElement;
if (originalCreateElement) {
  global.document.createElement = function(tagName) {
    const element = originalCreateElement.call(this, tagName);
    if (tagName === 'a') {
      // Mock anchor element for download functionality
      element.click = vi.fn();
      element.download = '';
      element.href = '';
    }
    return element;
  };
}
