/**
 * @fileoverview Test Suite: Path Builder Feature
 * Tests for learning path construction and customization functionality
 */

import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import { testPresets } from '../helpers/focused/preset-compositions.js';
import { PathBuilder } from '../../features/path-builder.js';

describe('PathBuilder', () => {
  let pathBuilder;
  let testHelper;

  beforeEach(() => {
    // Set up testHelper using featureModule for errorHandler, DOM and storage support
    testHelper = testPresets.featureModule('container');
    testHelper.beforeEach();

    // Spy on the actual globalThis.localStorage methods
    vi.spyOn(globalThis.localStorage, 'setItem');
    vi.spyOn(globalThis.localStorage, 'getItem');
    vi.spyOn(globalThis.localStorage, 'removeItem');

    // Set up basic DOM structure for path builder
    globalThis.document.body.innerHTML = `
      <div id="path-builder-container">
        <form id="path-builder-form">
          <input name="title" type="text" />
          <input name="description" type="text" />
          <select name="category">
            <option value="programming">Programming</option>
          </select>
          <select name="difficulty">
            <option value="beginner">Beginner</option>
          </select>
        </form>
        <select id="path-template-select"></select>
        <button id="validate-path-btn">Validate</button>
        <button id="save-path-btn">Save</button>
        <button id="load-path-btn">Load</button>
        <div id="path-builder-messages"></div>
      </div>
    `;

    // Initialize PathBuilder with mocked dependencies
    pathBuilder = new PathBuilder({
      errorHandler: testHelper.mocks.errorHandler,
      domUtils: testHelper.mocks.domUtils,
      debugHelper: testHelper.mocks.debugHelper
    });
  });

  afterEach(() => {
    pathBuilder.destroy();
    testHelper.afterEach();
  });

  describe('Constructor', () => {
    it('should create PathBuilder instance', () => {
      expect(pathBuilder).toBeInstanceOf(PathBuilder);
      expect(pathBuilder.isInitialized).toBe(true);
    });

    it('should initialize with default configuration', () => {
      expect(pathBuilder.config).toBeTypeOf('object');
      expect(pathBuilder.config.maxPathLength).toBe(50);
      expect(pathBuilder.config.minPathLength).toBe(1);
      expect(pathBuilder.config.autoSave).toBe(true);
    });

    it('should set up path templates', () => {
      const templates = pathBuilder.getTemplates();
      expect(templates).toBeInstanceOf(Array);
      expect(templates.length).toBeGreaterThan(0);
    });
  });

  describe('Path Building', () => {
    it('should build a custom learning path', () => {
      const components = [
        { id: 'step1', title: 'Introduction', type: 'lesson', weeks: 1 },
        { id: 'step2', title: 'Practice', type: 'project', weeks: 2 }
      ];

      const metadata = {
        title: 'My Custom Path',
        description: 'A custom learning path',
        category: 'programming',
        difficulty: 'beginner'
      };

      const result = pathBuilder.buildPath(components, metadata);

      expect(result).toBeTypeOf('object');
      expect(result.title).toBe('My Custom Path');
      expect(result.components).toHaveLength(2);
      expect(result.estimatedWeeks).toBe(3);
    });

    it('should validate path configuration', () => {
      const validPath = {
        id: 'test-path',
        title: 'Test Path',
        description: 'Test description',
        category: 'programming',
        difficulty: 'beginner',
        components: [
          { id: 'comp1', title: 'Component 1', type: 'lesson' }
        ]
      };

      const validation = pathBuilder.validatePath(validPath);
      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    it('should reject invalid path configuration', () => {
      const invalidPath = {
        // Missing required fields
        title: '',
        category: 'invalid-category',
        difficulty: 'invalid-difficulty',
        components: []
      };

      const validation = pathBuilder.validatePath(invalidPath);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.length).toBeGreaterThan(0);
    });
  });

  describe('Template Management', () => {
    it('should provide available templates', () => {
      const templates = pathBuilder.getTemplates();
      expect(templates).toBeInstanceOf(Array);
      expect(templates.length).toBeGreaterThan(0);

      const programmingTemplate = templates.find(t => t.id === 'programming-fundamentals');
      expect(programmingTemplate).toBeDefined();
      expect(programmingTemplate.title).toBe('Programming Fundamentals');
    });

    it('should clone template with customizations', () => {
      const customizations = {
        title: 'My Custom Programming Path',
        difficulty: 'advanced'
      };

      const clonedPath = pathBuilder.cloneTemplate('programming-fundamentals', customizations);

      expect(clonedPath.title).toBe('My Custom Programming Path');
      expect(clonedPath.difficulty).toBe('advanced');
      expect(clonedPath.components).toBeInstanceOf(Array);
    });
  });

  describe('Path Persistence', () => {
    it('should save path to localStorage', () => {
      const testPath = {
        id: 'test-path',
        title: 'Test Path',
        description: 'Test description',
        category: 'programming',
        difficulty: 'beginner',
        components: []
      };

      const success = pathBuilder.savePath(testPath);
      expect(success).toBe(true);
      expect(globalThis.localStorage.setItem).toHaveBeenCalled();
    });

    it('should load path from localStorage', () => {
      const testPath = {
        id: 'test-path',
        title: 'Test Path',
        description: 'Test description',
        category: 'programming',
        difficulty: 'beginner',
        components: []
      };

      globalThis.localStorage.getItem.mockReturnValue(JSON.stringify({
        'test-path': testPath
      }));

      const loadedPath = pathBuilder.loadPath('test-path');
      expect(loadedPath.title).toBe('Test Path');
    });

    it('should handle missing saved path gracefully', () => {
      globalThis.localStorage.getItem.mockReturnValue(JSON.stringify({}));
      const loadedPath = pathBuilder.loadPath('non-existent');
      expect(loadedPath).toBeNull();
    });
  });

  describe('Import/Export', () => {
    it('should export path as JSON', () => {
      const testPath = {
        id: 'test-path',
        title: 'Test Path',
        description: 'Test description',
        category: 'programming',
        difficulty: 'beginner',
        components: []
      };

      pathBuilder.pathData.set('test-path', testPath);
      const exported = pathBuilder.exportPath('test-path');

      expect(exported).toBeTypeOf('string');
      const parsed = JSON.parse(exported);
      expect(parsed.title).toBe('Test Path');
    });

    it('should import path from JSON', () => {
      const pathData = {
        id: 'imported-path',
        title: 'Imported Path',
        description: 'Imported description',
        category: 'programming',
        difficulty: 'beginner',
        components: [
          { id: 'comp1', title: 'Component 1', type: 'lesson' }
        ]
      };

      const jsonString = JSON.stringify(pathData);
      const imported = pathBuilder.importPath(jsonString);

      expect(imported.title).toBe('Imported Path');
      expect(imported.id).toContain('imported-path-imported-');
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed path data gracefully', () => {
      expect(() => {
        pathBuilder.validatePath({ invalid: 'data' });
      }).not.toThrow();
    });

    it('should handle localStorage errors gracefully', () => {
      globalThis.localStorage.setItem.mockImplementation(() => {
        throw new Error('Storage error');
      });

      const result = pathBuilder.savePath({ id: 'test', title: 'test', components: [] });
      expect(result).toBe(false);
    });
  });

  describe('Initialization', () => {
    it('should initialize successfully', () => {
      const result = pathBuilder.initialize();
      expect(result).toBe(true);
      expect(pathBuilder.isInitialized).toBe(true);
    });

    it('should not initialize twice', () => {
      pathBuilder.initialize();
      const result = pathBuilder.initialize();
      expect(result).toBe(true);
    });
  });
});
