import { vi, describe, it, beforeEach, afterEach, expect } from 'vitest';
/**
 * @fileoverview Comprehensive Tests for Kata Detection Utility
 * Tests kata and lab page detection, content type extraction, and learning context
 */

import { testPresets } from '../helpers/focused/preset-compositions.js';
import { KataDetection } from '../../utils/kata-detection.js';
import { sinonUtils as _sinonUtils } from '../helpers/common-test-utils.js';

describe('KataDetection', () => {

  let kataDetection;
  let locationMock;
  let historyMock;
  let documentMock;
  let testHelper;

  beforeEach(() => {
    // Only setup DOM helpers for tests that need them
    try {
      testHelper = testPresets.integrationModule();
    } catch {
      // Fallback for tests that don't need DOM
      testHelper = null;
    }

    // Mock location object
    locationMock = {
      hash: '',
      pathname: '/learning/',
      href: 'http://localhost:3000/learning/'
    };
    // Mock history API - must be defined after locationMock
    historyMock = {
      pushState: vi.fn(),
      replaceState: vi.fn(),
      back: vi.fn(),
      forward: vi.fn(),
      go: vi.fn(),
    };
    // Mock document with content element
    const contentElement = {
      textContent: '',
      innerHTML: ''
    };
    documentMock = {
      querySelector: vi.fn(),
      getElementById: vi.fn(),
      body: {
        innerHTML: '',
        appendChild: vi.fn(),
        removeChild: vi.fn()
      },
      // Essential DOM methods that tests might need
      createElement: (tagName) => ({ tagName, style: {} }),
      createTextNode: (text) => ({ textContent: text }),
      createDocumentFragment: () => ({ appendChild: () => {} })
    };
    // Set up global mocks
    global.window = {
      location: locationMock,
      history: historyMock
    };
    global.document = documentMock;

    // Default querySelector behavior - return content element for #main
    documentMock.querySelector.mockReturnValue(contentElement);
    documentMock.querySelector.mockReturnValue(null);

    kataDetection = new KataDetection();
  });

  afterEach(() => {
    testHelper?.afterEach?.();
  });
    describe('Constructor and Initialization', () => {

    it('should create instance with default kata categories', () => {
      expect(kataDetection).toBeInstanceOf(KataDetection);
      expect(kataDetection.kataCategories).toBeTypeOf('object');

      expect(kataDetection.kataCategories).toHaveProperty('ai-assisted-engineering')});
    it('should create instance with default training labs', () => {

      expect(kataDetection.trainingLabs).toBeTypeOf('object');

      expect(kataDetection.trainingLabs).toHaveProperty('01-ai-assisted-engineering')});
    it('should have all required methods', () => {

      expect(kataDetection.isKataPage).toBeTypeOf('function');
      expect(kataDetection.isLabPage).toBeTypeOf('function');
      expect(kataDetection.getContentType).toBeTypeOf('function');
      expect(kataDetection.extractKataId).toBeTypeOf('function');
      expect(kataDetection.extractLabId).toBeTypeOf('function');

      expect(kataDetection.extractKataCategory).toBeTypeOf('function')})});
    describe('Page Type Detection', () => {

    it('should detect kata pages by hash', () => {
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals'

      expect(kataDetection.isKataPage()).toBe(true)});
    it('should detect kata pages by pathname', () => {

      locationMock.pathname = '/learning/katas/prompt-engineering/01-prompt-creation-and-refactoring-workflow';
      locationMock.hash = ''

      expect(kataDetection.isKataPage()).toBe(true)});
    it('should detect lab pages by hash', () => {

      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering'

      expect(kataDetection.isLabPage()).toBe(true)});
    it('should detect lab pages by pathname', () => {

      locationMock.pathname = '/learning/training-labs/02-edge-to-cloud-systems';
      locationMock.hash = ''

      expect(kataDetection.isLabPage()).toBe(true)});
    it('should return false for non-learning pages', () => {

      locationMock.hash = '#/docs/getting-started';
      locationMock.pathname = '/docs/getting-started';
      expect(kataDetection.isKataPage()).toBe(false)

      expect(kataDetection.isLabPage()).toBe(false)})});
    describe('Content Type Detection', () => {

    it('should return "kata" for kata pages', () => {
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals'

      expect(kataDetection.getContentType()).toBe('kata')});
    it('should return "lab" for training lab pages', () => {

      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering'

      expect(kataDetection.getContentType()).toBe('lab')});
    it('should return "unknown" for other pages', () => {

      locationMock.hash = '#/docs/getting-started';
      locationMock.pathname = '/docs/getting-started'

      expect(kataDetection.getContentType()).toBe('unknown')})});
    describe('ID Extraction', () => {

    it('should extract kata ID from hash URL', () => {
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals'

      expect(kataDetection.extractKataId()).toBe('ai-assisted-engineering/01-ai-development-fundamentals')});
    it('should extract kata ID from pathname', () => {

      locationMock.pathname = '/learning/katas/prompt-engineering/01-prompt-creation-and-refactoring-workflow';
      locationMock.hash = ''

      expect(kataDetection.extractKataId()).toBe('prompt-engineering/01-prompt-creation-and-refactoring-workflow')});
    it('should extract lab ID from hash URL', () => {

      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering'

      expect(kataDetection.extractLabId()).toBe('01-ai-assisted-engineering')});
    it('should extract lab ID from pathname', () => {

      locationMock.pathname = '/learning/training-labs/02-edge-to-cloud-systems';
      locationMock.hash = ''

      expect(kataDetection.extractLabId()).toBe('02-edge-to-cloud-systems')});
    it('should return null for invalid URLs', () => {

      locationMock.hash = '#/docs/getting-started';
      locationMock.pathname = '/docs/getting-started';
      expect(kataDetection.extractKataId()).toBeNull()

      expect(kataDetection.extractLabId()).toBeNull()})});
    describe('Category Extraction', () => {

    it('should extract kata category from hash URL', () => {
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals'

      expect(kataDetection.extractKataCategory()).toBe('ai-assisted-engineering')});
    it('should extract kata category from pathname', () => {

      locationMock.pathname = '/learning/katas/prompt-engineering/01-prompt-creation-and-refactoring-workflow';
      locationMock.hash = ''

      expect(kataDetection.extractKataCategory()).toBe('prompt-engineering')});
    it('should return null for non-kata pages', () => {

      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering'

      expect(kataDetection.extractKataCategory()).toBeNull()})});
    describe('Learning Context Integration', () => {

    it('should return complete learning context for kata pages', () => {
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals';

      const context = kataDetection.getCurrentLearningContext();
      expect(context).not.toBeNull();
      expect(context).toMatchObject({
        type: 'kata',
        categoryId: 'ai-assisted-engineering',
        kataId: '01-ai-development-fundamentals'})});
    it('should return complete learning context for lab pages', () => {
      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering';

      const context = kataDetection.getCurrentLearningContext();
      expect(context).not.toBeNull();
      expect(context).toMatchObject({
        type: 'lab',
        labId: '01-ai-assisted-engineering'
      });
    });

    it('should return null context for non-learning pages', () => {
      locationMock.hash = '#/docs/getting-started';
      locationMock.pathname = '/docs/getting-started';

      const context = kataDetection.getCurrentLearningContext();
      expect(context).toBeNull();
    });
  });
    describe('Data Access Methods', () => {

    it('should return all kata categories', () => {
      const categories = kataDetection.getAllKataCategories();
      expect(categories).toBeTypeOf('object');
      expect(categories).toHaveProperty('ai-assisted-engineering');
      expect(categories).toHaveProperty('prompt-engineering');

      expect(categories).toHaveProperty('task-planning')});
    it('should return all training labs', () => {

      const labs = kataDetection.getAllTrainingLabs();
      expect(labs).toBeTypeOf('object');
      expect(labs).toHaveProperty('01-ai-assisted-engineering');

      expect(labs).toHaveProperty('02-edge-to-cloud-systems')});
    it('should return specific kata category data', () => {

      const category = kataDetection.getKataCategory('ai-assisted-engineering');
      expect(category).toBeTypeOf('object');
      expect(category).toHaveProperty('name');

      expect(category).toHaveProperty('description')});
    it('should return null for unknown kata category', () => {
      const category = kataDetection.getKataCategory('unknown-category');
      expect(category).toBeNull();
    });
  });
    describe('DOM Safety and Error Handling', () => {

    it('should handle missing window object gracefully', () => {
      // Create a kataDetection instance that will check for undefined window internally
      const result1 = kataDetection.isKataPage();
      const result2 = kataDetection.isLabPage();
      const result3 = kataDetection.getContentType();

      // Should not throw and should return safe fallbacks
      expect(result1).toBeDefined();
      expect(result2).toBeDefined();
      expect(result3).toBeDefined();
    });

    it('should handle missing location object gracefully', () => {
      // Test with instance that has mocked location (undefined location is handled internally)
      const originalLocation = global.window.location;
      global.window.location = undefined;

      try {
        expect(() => kataDetection.isKataPage()).not.toThrow();
        expect(() => kataDetection.isLabPage()).not.toThrow();
        expect(() => kataDetection.getContentType()).not.toThrow();
      } finally {
        global.window.location = originalLocation;
      }
    });

    it('should handle missing document object gracefully', () => {
      // Test with instance that has mocked document (undefined document is handled internally)
      const originalDocument = global.document;
      global.document = undefined;

      try {
        expect(() => kataDetection.getCurrentLearningContext()).not.toThrow();
      } finally {
        global.document = originalDocument;
      }
    });

    it('should ensure content element exists before setting textContent', () => {
      // Simulate missing content element
      if (documentMock && documentMock.querySelector) {
        documentMock.querySelector.mockReturnValue(null);
      }

      expect(() => kataDetection.getCurrentLearningContext()).not.toThrow();
    });
  });

  describe('History API Integration', () => {
    it('should work with history.pushState navigation', () => {
      // Simulate navigation via history API
      historyMock.pushState({}, '', '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals');
      locationMock.hash = '#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals';

      expect(kataDetection.isKataPage()).toBe(true);
      expect(kataDetection.extractKataId()).toBe('ai-assisted-engineering/01-ai-development-fundamentals');
    });

    it('should work with history.replaceState navigation', () => {
      // Simulate navigation via history API
      historyMock.replaceState({}, '', '#/learning/training-labs/01-ai-assisted-engineering');
      locationMock.hash = '#/learning/training-labs/01-ai-assisted-engineering';

      expect(kataDetection.isLabPage()).toBe(true);
      expect(kataDetection.extractLabId()).toBe('01-ai-assisted-engineering');
    });
  });
});
