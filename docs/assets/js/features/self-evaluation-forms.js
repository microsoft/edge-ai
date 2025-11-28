/**
 * @fileoverview Self-Evaluation Forms Manager - ES6 Module for post-kata self-assessment    } catch (_error) {
      // Silent error handling for draft save
    }rms
 *
 * @description
 * This module provides functionality for:
 * - Managing self-evaluation forms for kata completion
 * - Handling form progress tracking and validation
 * - Integrating with GitHub Copilot for skill assessment
 * - Managing form data storage and export capabilities
 *
 * Features:
 * - Comprehensive self-evaluation templates for different skill areas
 * - Form progress tracking with auto-save functionality
 * - Integration with skill assessment systems
 * - Export capabilities for external analysis
 * - LocalStorage management for draft saving and progress persistence
 *
 * @author Edge AI Team
 * @since 2025-08-01
 * @version 3.0.0
 */

import { ErrorHandler } from '../core/error-handler.js';
import { DOMUtils } from '../utils/dom-utils.js';

/**
 * Default configuration for self-evaluation forms
 */
const DEFAULT_CONFIG = {
  debug: false,
  autoSave: true,
  autoSaveInterval: 30000,
  enableValidation: true,
  maxRetries: 3,
  apiTimeout: 10000,
  storageKey: 'self-evaluation-forms'
};

/**
 * Storage manager for handling form data persistence
 */
class StorageManager {
  constructor(config = DEFAULT_CONFIG) {
    this.config = config;
  }

  /**
   * Save form draft to localStorage
   * @param {string} key - Storage key
   * @param {Object} data - Form data to save
   * @returns {boolean} Success status
   */
  saveDraft(key, data) {
    try {
      const storageData = this.getStorageData();
      storageData.drafts[key] = {
        data: data,
        timestamp: new Date().toISOString()
      };
      localStorage.setItem(this.config.storageKey, JSON.stringify(storageData));
      return true;
    } catch {
      // Error saving draft - logging disabled for production
      return false;
    }
  }

  /**
   * Load form draft from localStorage
   * @param {string} key - Storage key
   * @returns {Object|null} Form data or null if not found
   */
  loadDraft(key) {
    try {
      const storageData = this.getStorageData();
      const draft = storageData.drafts[key];
      return draft ? draft.data : null;
    } catch {
      // Error loading draft - logging disabled for production
      return null;
    }
  }

  /**
   * Get storage data structure
   * @returns {Object} Storage data object
   */
  getStorageData() {
    try {
      const stored = localStorage.getItem(this.config.storageKey);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch {
      // Error parsing storage data - logging disabled for production
    }

    return {
      drafts: {},
      completed: {},
      version: '3.0.0'
    };
  }
}

/**
 * Self-Evaluation Manager for coordinating evaluation forms
 */
export class SelfEvaluationManager {
  /**
   * Constructor for SelfEvaluationManager
   * @param {Object} dependencies - Dependencies object
   * @param {ErrorHandler} dependencies.errorHandler - Error handler instance
   * @param {DOMUtils} dependencies.domUtils - DOM utilities instance
   * @param {Object} dependencies.debugHelper - Debug helper (optional)
   * @param {Object} dependencies.config - Configuration options
   */
  constructor({ errorHandler, domUtils, debugHelper, config } = {}) {
    this.errorHandler = errorHandler || new ErrorHandler('self-evaluation-forms');
    this.domUtils = domUtils || new DOMUtils();
    this.debugHelper = debugHelper || console;
    this.config = { ...DEFAULT_CONFIG, ...(config || {}) };

    this.storage = new StorageManager(this.config);
    this.evaluationTemplates = new Map();
    this.isInitialized = false;

    this.debugHelper?.log?.('🎯 [SELF-EVAL] SelfEvaluationManager instance created');
    this.initializeTemplates();
  }

  /**
   * Initialize evaluation templates for different skill areas
   */
  initializeTemplates() {
    this.evaluationTemplates.set('learning-skill-assessment', {
      id: 'learning-skill-assessment',
      title: 'Learning Path Self-Assessment',
      description: 'Evaluate your skills and knowledge gained through this learning path',
      sections: [
        {
          id: 'prompt-engineering',
          title: 'AI Prompt Engineering',
          description: 'Assess your ability to create effective prompts for AI systems and optimize interactions.',
          questions: [
            {
              id: 'q1-basic-prompting',
              type: 'rating',
              question: 'How skilled are you at creating clear, specific prompts that generate accurate AI responses?',
              scale: 5,
              labels: [
                'Novice - I\'m learning the basics of prompt structure and clarity',
                'Developing - I can create simple prompts and understand basic principles',
                'Competent - I regularly create effective prompts with clear intent and context',
                'Proficient - I craft sophisticated prompts with nuanced context and constraints',
                'Expert - I develop prompt frameworks and train others in advanced techniques'
              ],
              category: 'prompt-engineering',
              required: true
            }
          ]
        }
      ]
    });

    this.debugHelper?.log?.('✅ [SELF-EVAL] Evaluation templates initialized');
  }

  /**
   * Create a new evaluation form for a specific kata
   * @param {string} kataPath - Path to the kata
   * @param {string} evaluationType - Type of evaluation
   * @returns {SelfEvaluationForm|null} The created form instance
   */
  createEvaluationForm(kataPath, evaluationType = 'skill-assessment') {
    try {
      const template = this.evaluationTemplates.get(`learning-${evaluationType}`);
      if (!template) {
        throw new Error(`No template found for evaluation type: ${evaluationType}`);
      }

      const form = new SelfEvaluationForm({
        kataPath,
        template,
        errorHandler: this.errorHandler,
        domUtils: this.domUtils,
        debugHelper: this.debugHelper,
        storage: this.storage,
        config: this.config
      });

      this.debugHelper?.log?.(`✅ [SELF-EVAL] Created evaluation form for ${kataPath}`);
      return form;
    } catch (_error) {
      this.errorHandler.safeExecute(() => {
        this.debugHelper?.log?.(`❌ [SELF-EVAL] Error creating evaluation form: ${_error.message}`);
      });
      return null;
    }
  }

  /**
   * Clean up resources and reset state
   */
  cleanup() {
    try {
      this.debugHelper?.log?.('🧹 [SELF-EVAL] Cleaning up manager resources...');
      this.debugHelper?.log?.('✅ [SELF-EVAL] Manager cleanup complete');
    } catch (_error) {
      this.errorHandler.safeExecute(() => {
        this.debugHelper?.log?.(`❌ [SELF-EVAL] Error during cleanup: ${_error.message}`);
      });
    }
  }
}

/**
 * Self-Evaluation Form class for handling individual form instances
 */
export class SelfEvaluationForm {
  /**
   * Constructor for SelfEvaluationForm
   * @param {Object} options - Form options
   * @param {string} options.kataPath - Path to the kata
   * @param {Object} options.template - Form template
   * @param {ErrorHandler} options.errorHandler - Error handler instance
   * @param {DOMUtils} options.domUtils - DOM utilities instance
   * @param {StorageManager} options.storage - Storage manager instance
   * @param {Object} options.debugHelper - Debug helper
   * @param {Object} options.config - Configuration
   */
  constructor({ kataPath, template, errorHandler, domUtils, storage, debugHelper, config }) {
    this.kataPath = kataPath;
    this.template = template;
    this.errorHandler = errorHandler;
    this.domUtils = domUtils;
    this.storage = storage;
    this.debugHelper = debugHelper;
    this.config = config;

    this.evaluationKey = `${kataPath}-${template.id}`;
    this.formElement = null;
    this.formData = {};
    this.isInitialized = false;
    this.autoSaveTimer = null;

    this.debugHelper?.log?.(`🎯 [SELF-EVAL] SelfEvaluationForm instance created for ${kataPath}`);
  }

  /**
   * Initialize the form
   * @returns {Promise<boolean>} Success status
   */
  async initialize() {
    try {
      const draft = this.storage.loadDraft(this.evaluationKey);
      if (draft) {
        this.formData = draft;
        this.debugHelper?.log?.('📋 [SELF-EVAL] Loaded draft data');
      }

      if (this.config.autoSave) {
        this.setupAutoSave();
      }

      this.isInitialized = true;
      this.debugHelper?.log?.('✅ [SELF-EVAL] Form initialized');
      return true;
    } catch (_error) {
      this.errorHandler.safeExecute(() => {
        this.debugHelper?.log?.(`❌ [SELF-EVAL] Error initializing form: ${_error.message}`);
      });
      return false;
    }
  }

  /**
   * Set up auto-save functionality
   */
  setupAutoSave() {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
    }

    this.autoSaveTimer = setInterval(() => {
      this.storage.saveDraft(this.evaluationKey, this.formData);
    }, this.config.autoSaveInterval);

    this.debugHelper?.log?.('⏰ [SELF-EVAL] Auto-save enabled');
  }

  /**
   * Clean up form resources
   */
  cleanup() {
    try {
      if (this.autoSaveTimer) {
        clearInterval(this.autoSaveTimer);
        this.autoSaveTimer = null;
      }

      if (this.formElement && this.formElement.parentNode) {
        this.formElement.parentNode.removeChild(this.formElement);
        this.formElement = null;
      }

      this.debugHelper?.log?.('🧹 [SELF-EVAL] Form cleanup complete');
    } catch (_error) {
      this.errorHandler.safeExecute(() => {
        this.debugHelper?.log?.(`❌ [SELF-EVAL] Error during cleanup: ${_error.message}`);
      });
    }
  }
}

export { StorageManager };
export default SelfEvaluationManager;
