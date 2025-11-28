/**
 * @fileoverview Preset Compositions for Test Helpers
 * Provides pre-configured combinations of focused helpers for common test patterns
 *
 * Usage:
 *   import { testPresets } from '../helpers/focused/preset-compositions.js';
 *
 *   describe('MyModule', () => {
 *     const testHelper = testPresets.coreModule();
 *
 *     beforeEach(testHelper.beforeEach);
 *     afterEach(testHelper.afterEach);
 *
 *     it('should work', () => {
 *       // Use testHelper.sandbox, testHelper.mocks, etc.
 *     });
 *   });
 *
 * @version 1.0.0
 */

import { composeHelpers } from './compose-helpers.js';

/**
 * Test Presets - Common combinations of focused helpers
 * Based on analysis of existing module-test-helpers.js usage patterns
 */
export const testPresets = {
  /**
   * Core Module Tests - Vitest mocks only
   * For modules like ErrorHandler, StorageManager that need minimal setup
   * @returns {Object} Test context with mock utilities
   */
  coreModule() {
    return composeHelpers({ mockUtils: true });
  },

  /**
   * Core Module with Storage - Vitest mocks + Storage mocking
   * For modules like StorageManager, ProgressSystemManager that work with localStorage
   * @param {Object} storageOptions - Storage configuration options
   * @returns {Object} Test context with mocks and storage
   */
  coreModuleWithStorage(storageOptions = {}) {
    return composeHelpers({
      mockUtils: true,
      storage: storageOptions
    });
  },

  /**
   * Component Tests - Vitest mocks + DOM container
   * For modules like TreeNavigation, ProgressBar that need DOM structure
   * @param {string} domType - Type of DOM structure ('container', 'form', 'nav', 'checkbox')
   * @returns {Object} Test context with mocks and DOM
   */
  componentModule(domType = 'container') {
    return composeHelpers({
      mockUtils: true,
      dom: domType
    });
  },

  /**
   * Feature Tests - Vitest mocks + DOM + Storage
   * For modules like SidebarChevrons, SkillAssessment that need DOM and localStorage
   * @param {string} domType - Type of DOM structure
   * @param {Object} storageOptions - Storage configuration options
   * @returns {Object} Test context with mocks, DOM, and storage
   */
  featureModule(domType = 'container', storageOptions = {}) {
    return composeHelpers({
      mockUtils: true,
      dom: domType,
      storage: storageOptions
    });
  },

  /**
   * Utility Tests - Vitest mocks + Error handler stubs
   * For modules like DOMUtils that need minimal error handling
   * @returns {Object} Test context with mocks and error handler
   */
  utilityModule() {
    return composeHelpers({
      mockUtils: true,
      errorHandler: true
    });
  },

  /**
   * Integration Tests - All helpers
   * For complex modules that need full isolation and mocking
   * @param {string} domType - Type of DOM structure
   * @param {Object} storageOptions - Storage configuration options
   * @returns {Object} Test context with all helpers
   */
  integrationModule(domType = 'container', storageOptions = {}) {
    return composeHelpers({
      mockUtils: true,
      dom: domType,
      storage: storageOptions,
      errorHandler: true
    });
  },

  /**
   * Docsify Plugin Tests - Vitest mocks + DOM + Error handler
   * For Docsify-specific modules that need plugin environment simulation
   * @returns {Object} Test context optimized for Docsify plugins
   */
  docsifyPlugin() {
    return composeHelpers({
      mockUtils: true,
      dom: 'container',
      errorHandler: true
    });
  },

  /**
   * Storage-Heavy Tests - Vitest mocks + Enhanced Storage
   * For modules that do heavy localStorage operations with events
   * @returns {Object} Test context with enhanced storage simulation
   */
  storageHeavy() {
    return composeHelpers({
      mockUtils: true,
      storage: {
        simulateEvents: true,
        maxSize: 5000000 // 5MB limit for testing
      }
    });
  },

  /**
   * Form Component Tests - Vitest mocks + Form DOM
   * For modules that work with forms and form elements
   * @returns {Object} Test context with form DOM structure
   */
  formComponent() {
    return composeHelpers({
      mockUtils: true,
      dom: 'form'
    });
  },

  /**
   * Navigation Tests - Vitest mocks + Navigation DOM
   * For modules that work with navigation elements
   * @returns {Object} Test context with navigation DOM structure
   */
  navigationComponent() {
    return composeHelpers({
      mockUtils: true,
      dom: 'nav'
    });
  },

  /**
   * Checkbox List Tests - Vitest mocks + Checkbox DOM
   * For modules that work with checkbox lists and selections
   * @returns {Object} Test context with checkbox list DOM structure
   */
  checkboxComponent() {
    return composeHelpers({
      mockUtils: true,
      dom: 'checkbox'
    });
  },

  /**
   * Analytics Tests - Vitest mocks + Storage + Error handler
   * For modules like LearningAnalyticsEngine that track data and handle errors
   * @returns {Object} Test context optimized for analytics modules
   */
  analyticsModule() {
    return composeHelpers({
      mockUtils: true,
      storage: { simulateEvents: true },
      errorHandler: true
    });
  },

  /**
   * Learning Path Tests - Vitest mocks + Storage + Error handler
   * For modules like LearningPathManager that manage learning progress
   * @returns {Object} Test context optimized for learning modules
   */
  learningModule() {
    return composeHelpers({
      mockUtils: true,
      storage: { simulateEvents: true },
      errorHandler: true
    });
  },

  /**
   * Minimal Tests - Vitest mocks only (alias for coreModule)
   * For simple unit tests that just need mocking
   * @returns {Object} Test context with mocks only
   */
  minimal() {
    return this.coreModule();
  },

  /**
   * Full Tests - All helpers (alias for integrationModule)
   * For comprehensive tests that need everything
   * @param {string} domType - Type of DOM structure
   * @param {Object} storageOptions - Storage configuration options
   * @returns {Object} Test context with all helpers
   */
  full(domType = 'container', storageOptions = {}) {
    return this.integrationModule(domType, storageOptions);
  }
};

/**
 * Legacy compatibility mapping
 * Maps old module-test-helpers.js functions to new presets
 */
export const legacyMapping = {
  createCoreModuleTest: () => testPresets.coreModule(),
  createFeatureModuleTest: (domType) => testPresets.featureModule(domType),
  createComponentModuleTest: (_componentType) => testPresets.componentModule('container'),
  createUtilityModuleTest: () => testPresets.utilityModule(),
  createDocsifyPluginTest: () => testPresets.docsifyPlugin()
};

/**
 * Quick access to most common presets
 */
export const quickPresets = {
  // Most common patterns based on analysis
  core: testPresets.coreModule,
  storage: testPresets.coreModuleWithStorage,
  component: testPresets.componentModule,
  feature: testPresets.featureModule,
  utility: testPresets.utilityModule,
  integration: testPresets.integrationModule,

  // Specialized patterns
  form: testPresets.formComponent,
  nav: testPresets.navigationComponent,
  checkbox: testPresets.checkboxComponent,
  analytics: testPresets.analyticsModule,
  learning: testPresets.learningModule,
  docsify: testPresets.docsifyPlugin
};

// Default export for convenience
export default testPresets;
