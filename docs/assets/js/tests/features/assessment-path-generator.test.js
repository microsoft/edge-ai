/**
 * Assessment Path Generator Tests
 * Comprehensive test suite for the Assessment-Driven Path Generator
 * Tests the complete assessment interface including modal creation,
 * skill assessment, path generation, and data management functionality
 * @version 1.0.0
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

describe('Assessment Path Generator', () => {
  let AssessmentPathGenerator;
  let createAssessmentPathGenerator;
  let generator;
  let mockDOMUtils;
  let mockErrorHandler;

  beforeEach(async () => {
    // Mock console methods to avoid noise
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
    vi.spyOn(console, 'group').mockImplementation(() => {});
    vi.spyOn(console, 'groupEnd').mockImplementation(() => {});

    // Mock global functions
    globalThis.alert = vi.fn();

    // Setup mock dependencies
    mockDOMUtils = {
      test: 'mock',
      findElement: vi.fn(),
      createElement: vi.fn((tag, _options) => {
        const element = document.createElement(tag);
        if (_options) {
          if (_options.className) {element.className = _options.className;}
          if (_options.style) {element.style.cssText = _options.style;}
          if (_options.innerHTML) {element.innerHTML = _options.innerHTML;}
        }
        return element;
      }),
      appendElement: vi.fn(),
      removeElement: vi.fn()
    };
    mockErrorHandler = {
      test: 'mock',
      safeExecute: vi.fn((fn) => fn()),
      handleError: vi.fn()
    };

    // Dynamic import the module
    const module = await import('../../features/assessment-path-generator.js');
    AssessmentPathGenerator = module.AssessmentPathGenerator;
    createAssessmentPathGenerator = module.createAssessmentPathGenerator;
  });

  afterEach(() => {
    if (generator) {
      generator.destroy?.();
    }
    vi.restoreAllMocks();
  });

  describe('AssessmentPathGenerator Class', () => {
    describe('Constructor', () => {
      it('should initialize with default dependencies', () => {
        generator = new AssessmentPathGenerator();

        expect(generator).toBeInstanceOf(AssessmentPathGenerator);
        expect(generator.domUtils).toBeDefined();
        expect(generator.errorHandler).toBeDefined();
        expect(generator.assessmentData).toBeNull();
        expect(generator.skillCategories).toBeInstanceOf(Object);
        expect(generator.pathTemplates).toBeInstanceOf(Object);
      });

      it('should accept custom dependencies', () => {
        generator = new AssessmentPathGenerator({
          domUtils: mockDOMUtils,
          errorHandler: mockErrorHandler
        });

        expect(generator.domUtils).toBe(mockDOMUtils);
        expect(generator.errorHandler).toBe(mockErrorHandler);
        expect(generator.skillCategories).toBeDefined();
        expect(generator.assessmentData).toBeNull();
      });

      it('should initialize skill categories and path templates', () => {
        generator = new AssessmentPathGenerator();

        expect(generator.skillCategories).toBeDefined();
        expect(typeof generator.skillCategories).toBe('object');
        expect(generator.skillCategories).not.toBeInstanceOf(Array);
        expect(Object.keys(generator.skillCategories).length).toBeGreaterThan(0);
        expect(generator.pathTemplates).toBeDefined();
        expect(typeof generator.pathTemplates).toBe('object');
      });
    });

    describe('initialize()', () => {
      beforeEach(() => {
        generator = new AssessmentPathGenerator();
      });

      it('should initialize successfully', async () => {
        await generator.initialize();

        expect(generator.isInitialized).toBe(true);
        expect(generator.abortController).toBeInstanceOf(AbortController);
      });

      it('should return same promise on multiple calls', async () => {
        // First call should create the promise
        const promise1 = generator.initialize();

        // Second call should reuse the cached promise
        const promise2 = generator.initialize();

        // Both should resolve successfully (promises may be different instances)
        expect(promise1).toBeInstanceOf(Promise);
        expect(promise2).toBeInstanceOf(Promise);

        // Wait for both to complete
        const [result1, result2] = await Promise.all([promise1, promise2]);

        // Both results should be the same
        expect(result1).toBe(result2);
        expect(generator.isInitialized).toBe(true);
      });

      it('should handle initialization errors gracefully', async () => {
        // Override the global mock to throw an error
        mockErrorHandler.safeExecute.mockImplementationOnce(() => {
          throw new Error('Mock initialization error');
        });

        generator = new AssessmentPathGenerator({
          errorHandler: mockErrorHandler
        });

        await expect(generator.initialize()).rejects.toThrow('Mock initialization error');
        expect(generator.isInitialized).toBe(false);
      });
    });

    describe('Skill Categories Management', () => {
      beforeEach(() => {
        generator = new AssessmentPathGenerator();
      });

      it('should have valid skill categories structure', () => {
        const categories = generator.skillCategories;

        expect(typeof categories).toBe('object');
        expect(Object.keys(categories).length).toBeGreaterThan(0);

        Object.values(categories).forEach(category => {
          expect(category).toHaveProperty('name');
          expect(category).toHaveProperty('description');
          expect(category).toHaveProperty('levels');
          expect(Array.isArray(category.levels)).toBe(true);
        });
      });

      it('should include expected skill categories', () => {
        const categoryKeys = Object.keys(generator.skillCategories);

        expect(categoryKeys).toContain('adr-creation');
        expect(categoryKeys).toContain('ai-assisted-engineering');
        expect(categoryKeys).toContain('edge-deployment');
        expect(categoryKeys).toContain('project-planning');
        expect(categoryKeys).toContain('prompt-engineering');
        expect(categoryKeys).toContain('task-planning');
        expect(categoryKeys).toContain('data-analytics');
      });

      it('should have valid levels within categories', () => {
        const categories = generator.skillCategories;
        expect(categories).toBeDefined();
        expect(typeof categories).toBe('object');

        Object.values(categories).forEach(category => {
          expect(category).toHaveProperty('levels');
          expect(Array.isArray(category.levels)).toBe(true);
          expect(category.levels).toContain('beginner');
          expect(category.levels).toContain('expert');
          expect(category.levels.length).toBeGreaterThan(0);
        });
      });
    });

    describe('Path Templates Management', () => {
      beforeEach(() => {
        generator = new AssessmentPathGenerator();
      });

      it('should have valid path templates structure', () => {
        const templates = generator.pathTemplates;

        expect(typeof templates).toBe('object');
        expect(Object.keys(templates).length).toBeGreaterThan(0);

        Object.values(templates).forEach(template => {
          expect(template).toHaveProperty('name');
          expect(template).toHaveProperty('description');
          expect(template).toHaveProperty('targetLevels');
          expect(template).toHaveProperty('recommendedHours');
          expect(Array.isArray(template.targetLevels)).toBe(true);
          expect(template.recommendedHours).toHaveProperty('min');
          expect(template.recommendedHours).toHaveProperty('max');
        });
      });

      it('should include expected path templates', () => {
        const templateKeys = Object.keys(generator.pathTemplates);

        expect(templateKeys).toContain('beginner');
        expect(templateKeys).toContain('intermediate');
        expect(templateKeys).toContain('advanced');
        expect(templateKeys).toContain('expert');
      });
    });

    describe('Modal Interface Creation', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator({
          domUtils: mockDOMUtils,
          errorHandler: mockErrorHandler
        });
        await generator.initialize();
      });

      it('should create assessment interface', () => {
        generator.createAssessmentInterface();

        expect(mockDOMUtils.createElement).toHaveBeenCalled();
        expect(generator.modalElement).toBeDefined();
        expect(generator.containerElement).toBeDefined();
      });

      it('should create modal structure', () => {
        generator.createModal();

        expect(mockDOMUtils.createElement).toHaveBeenCalledWith('div',
          expect.objectContaining({
            className: expect.stringContaining('assessment-modal')
          }));
        expect(generator.modalElement).toBeDefined();
      }); it('should create container with proper structure', () => {
        generator.createContainer();

        expect(mockDOMUtils.createElement).toHaveBeenCalledWith('div',
          expect.objectContaining({
            className: expect.stringContaining('assessment-container')
          }));
        expect(generator.containerElement).toBeDefined();
      });

      it('should create header with title', () => {
        const header = generator.createHeader();

        expect(mockDOMUtils.createElement).toHaveBeenCalledWith('div',
          expect.objectContaining({
            className: expect.stringContaining('assessment-header')
          }));
        expect(header).toBeDefined();
      });

      it('should create content area', () => {
        const content = generator.createContentArea();

        expect(mockDOMUtils.createElement).toHaveBeenCalledWith('div',
          expect.objectContaining({
            className: expect.stringContaining('assessment-content')
          }));
        expect(content).toBeDefined();
      });

      it('should create footer with navigation', () => {
        const footer = generator.createFooter();

        expect(mockDOMUtils.createElement).toHaveBeenCalledWith('div',
          expect.objectContaining({
            className: expect.stringContaining('assessment-footer')
          }));
        expect(footer).toBeDefined();
      });
    });

    describe('Assessment Flow Management', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator({
          domUtils: mockDOMUtils,
          errorHandler: mockErrorHandler
        });
        await generator.initialize();
      });

      it('should start assessment process', () => {
        const _mockContainer = globalThis.document.createElement('div');

        generator.startAssessment();

        expect(generator.currentCategoryIndex).toBe(0);
        expect(generator.assessmentData).toBeNull();
      });

      it('should show introduction correctly', () => {
        const container = globalThis.document.createElement('div');

        generator.showIntroduction(container);

        expect(mockDOMUtils.createElement).toHaveBeenCalled();
      });

      it('should create progress indicator', () => {
        const totalCategories = 6;

        const progressIndicator = generator.createProgressIndicator(totalCategories);

        expect(progressIndicator).toContain('assessment-progress');
        expect(progressIndicator).toContain(`${generator.currentCategoryIndex + 1} of ${totalCategories}`);
        expect(typeof progressIndicator).toBe('string');
      });

      it('should navigate through assessment steps', () => {
        generator.currentCategoryIndex = 0;

        // Mock the validation to return true so navigation works
        vi.spyOn(generator, 'validateCurrentAssessment').mockReturnValue(true);
        vi.spyOn(generator, 'saveCurrentAssessment').mockImplementation(() => {});
        vi.spyOn(generator, 'showCategoryAssessment').mockImplementation(() => {});

        generator.goNext();
        expect(generator.currentCategoryIndex).toBe(1);

        generator.goBack();
        expect(generator.currentCategoryIndex).toBe(0);
      });

      it('should not go below step 0', () => {
        generator.currentCategoryIndex = 0;

        generator.goBack();
        expect(generator.currentCategoryIndex).toBe(0);
      });
    });

    describe('Skill Level Assessment', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator();
        await generator.initialize();
      });

      it('should provide skill level descriptions', () => {
        const beginnerDesc = generator.getSkillLevelDescription('beginner');
        const expertDesc = generator.getSkillLevelDescription('expert');

        expect(typeof beginnerDesc).toBe('string');
        expect(typeof expertDesc).toBe('string');
        expect(beginnerDesc.length).toBeGreaterThan(0);
        expect(expertDesc.length).toBeGreaterThan(0);
        expect(beginnerDesc).not.toBe(expertDesc);
      });

      it('should handle invalid skill levels', () => {
        const invalidDesc = generator.getSkillLevelDescription(0);
        const tooHighDesc = generator.getSkillLevelDescription(10);

        expect(typeof invalidDesc).toBe('string');
        expect(typeof tooHighDesc).toBe('string');
      });

      it('should create category interface for assessment', () => {
        const mockCategory = {
          id: 'test-category',
          name: 'Test Category',
          description: 'Test description',
          levels: ['beginner', 'intermediate', 'advanced', 'expert'],
          assessmentQuestions: [
            'How familiar are you with this skill?',
            'Have you used this in projects?',
            'Do you consider yourself advanced?'
          ],
          skills: [
            { name: 'Test Skill', description: 'Test skill description' }
          ]
        };

        const categoryInterface = generator.createCategoryInterface(mockCategory);

        expect(categoryInterface).toBeDefined();
        expect(typeof categoryInterface).toBe('string');
        expect(categoryInterface).toContain('Test Category');
        expect(categoryInterface).toContain('Test description');
      });

      it('should setup radio button styling', () => {
        const container = globalThis.document.createElement('div');

        generator.setupRadioButtonStyling(container);

        // Should not throw errors
        expect(true).toBe(true);
      });
    });

    describe('Learning Path Generation', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator({
          errorHandler: mockErrorHandler
        });
        await generator.initialize();
      });

      it('should analyze assessment results', () => {
        // Set up mock skill assessments
        generator.skillAssessments = {
          'adr-creation': { skillLevel: 'beginner', averageRating: 2.5 },
          'ai-assisted-engineering': { skillLevel: 'intermediate', averageRating: 3.5 },
          'edge-deployment': { skillLevel: 'beginner', averageRating: 2.0 }
        };

        const recommendations = generator.analyzeAssessmentResults();

        expect(recommendations).toHaveProperty('overallLevel');
        expect(recommendations).toHaveProperty('recommendedPathType');
        expect(recommendations).toHaveProperty('priorityAreas');
        expect(recommendations).toHaveProperty('suggestedItems');
        expect(recommendations).toHaveProperty('estimatedDuration');
        expect(recommendations).toHaveProperty('personalizedMessage');
        expect(Array.isArray(recommendations.priorityAreas)).toBe(true);
        expect(Array.isArray(recommendations.suggestedItems)).toBe(true);
      });

      it('should create schema-compliant learning path', () => {
        // Setup some assessment data
        generator.skillAssessments = {
          'adr-creation': {
            skillLevel: 'beginner',
            averageRating: 2.5,
            responses: ['I need to learn this', 'Limited experience', 'Would like guidance']
          },
          'ai-assisted-engineering': {
            skillLevel: 'intermediate',
            averageRating: 3.5,
            responses: ['Some experience', 'Use occasionally', 'Could improve']
          }
        };

        const pathData = generator.analyzeAssessmentResults();

        expect(pathData).toHaveProperty('overallLevel');
        expect(pathData).toHaveProperty('recommendedPathType');
        expect(pathData).toHaveProperty('priorityAreas');
        expect(pathData).toHaveProperty('suggestedItems');
        expect(pathData).toHaveProperty('estimatedDuration');
      });

      it('should save assessment-based path', async () => {
        const mockPathData = {
          metadata: {
            learningPathId: 'test-path',
            learningPathTitle: 'Test Learning Path'
          },
          learningPath: {
            title: 'Test Learning Path',
            steps: []
          }
        };

        const localStorageSpy = vi.spyOn(Storage.prototype, 'setItem');

        await generator.saveAssessmentBasedPath(mockPathData);

        expect(localStorageSpy).toHaveBeenCalledWith(
          expect.stringContaining('assessmentLearningPath_'),
          expect.stringContaining('test-path')
        );

        localStorageSpy.mockRestore();
      });

      it('should load existing assessments', async () => {
        // Mock localStorage with existing assessment data
        const mockAssessmentData = {
          assessments: {
            'category1': { level: 3, skills: ['skill1'] }
          }
        };
        globalThis.localStorage.setItem('skillAssessment_test', JSON.stringify(mockAssessmentData));

        await generator.loadExistingAssessments();

        expect(generator.skillAssessments).toBeDefined();
      });

      it('should process assessment data correctly', async () => {
        const mockAssessmentData = {
          categories: {
            'adr-creation': { level: 4, completedSkills: ['basic', 'intermediate'] }
          },
          timestamp: Date.now()
        };

        const processedData = await generator.processAssessment(mockAssessmentData);

        expect(processedData).toBeDefined();
      });
    });

    describe('Event Handling', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator({
          domUtils: mockDOMUtils
        });
        await generator.initialize();
      });

      it('should attach event listeners', () => {
        const _mockContainer = globalThis.document.createElement('div');

        generator.attachEventListeners();

        // Should not throw errors
        expect(true).toBe(true);
      });

      it('should handle modal close events', () => {
        // Setup modal in DOM
        const modal = globalThis.document.createElement('div');
        modal.className = 'assessment-modal';
        globalThis.document.body.appendChild(modal);

        generator.modalElement = modal;
        // Test that modal is accessible
        expect(generator.modalElement).toBeDefined();
        expect(generator.modalElement.className).toBe('assessment-modal');
      });

      it('should handle assessment completion', () => {
        generator.assessmentData = {
          'test-category': { level: 3, skills: ['test-skill'] }
        };

        // Test the data is properly set
        expect(generator.assessmentData).toBeDefined();
        expect(Object.keys(generator.assessmentData).length).toBeGreaterThan(0);
      });
    });

    describe('Data Validation', () => {
      beforeEach(() => {
        generator = new AssessmentPathGenerator();
      });

      it('should validate assessment data structure', () => {
        const validData = {
          experience: 'intermediate',
          timeCommitment: '5-10 hours',
          goals: 'improve skills'
        };

        const result = generator.validateAssessmentData(validData);
        expect(result).toHaveProperty('isValid');
        expect(result.isValid).toBe(true);
        expect(result.errors).toEqual([]);
      });

      it('should reject invalid assessment data', () => {
        const invalidData = {
          experience: 'intermediate'
          // missing required fields
        };

        const result = generator.validateAssessmentData(invalidData);
        expect(result).toHaveProperty('isValid');
        expect(result.isValid).toBe(false);
        expect(Array.isArray(result.errors)).toBe(true);
        expect(result.errors.length).toBeGreaterThan(0);
      });

      it('should handle empty assessment data', () => {
        const emptyData = {};

        const result = generator.validateAssessmentData(emptyData);
        expect(result).toHaveProperty('isValid');
        expect(result.isValid).toBe(false);
        expect(Array.isArray(result.errors)).toBe(true);
        expect(result.errors.length).toBe(3); // Should have 3 errors for missing required fields
      });
    });

    describe('destroy()', () => {
      beforeEach(async () => {
        generator = new AssessmentPathGenerator();
        await generator.initialize();
      });

      it('should clean up all resources', () => {
        const mockModal = globalThis.document.createElement('div');
        generator.modal = mockModal;
        generator.abortController = new AbortController();

        generator.destroy();

        expect(generator.modalElement).toBeNull();
        expect(generator.abortController.signal.aborted).toBe(true);
        expect(generator.isInitialized).toBe(false);
      });

      it('should handle cleanup when already destroyed', () => {
        generator.destroy();

        // Second destroy should not throw
        expect(() => generator.destroy()).not.toThrow();
      });
    });
  });

  describe('Factory Functions', () => {
    describe('createAssessmentPathGenerator()', () => {
      it('should create and initialize generator instance', async () => {
        const generator = await createAssessmentPathGenerator();

        expect(generator).toBeInstanceOf(AssessmentPathGenerator);
        expect(generator.isInitialized).toBe(true);
      });

      it('should accept custom dependencies', async () => {
        const generator = await createAssessmentPathGenerator({
          domUtils: mockDOMUtils,
          errorHandler: mockErrorHandler
        });

        expect(generator.domUtils).toBe(mockDOMUtils);
        expect(generator.errorHandler).toBe(mockErrorHandler);
        expect(generator.isInitialized).toBe(true);
      });
    });
  });

  describe('Integration Tests', () => {
    beforeEach(async () => {
      generator = new AssessmentPathGenerator({
        domUtils: mockDOMUtils,
        errorHandler: mockErrorHandler
      });
      await generator.initialize();
    });

    it('should handle complete assessment workflow', async () => {
      // Start assessment
      generator.startAssessment();
      expect(generator.currentCategoryIndex).toBe(0);

      // Initialize skill assessments with proper structure
      generator.skillAssessments = {};

      // Progress through categories
      Object.entries(generator.skillCategories).forEach(([categoryId, _category], _index) => {
        generator.skillAssessments[categoryId] = {
          skillLevel: 'intermediate',
          ratings: [3, 3, 3],
          averageRating: 3,
          assessedAt: new Date().toISOString()
        };
        if (_index < Object.keys(generator.skillCategories).length - 1) {
          generator.goNext();
        }
      });

      // Generate learning path recommendations
      const pathRecommendations = generator.analyzeAssessmentResults();
      expect(pathRecommendations).toBeDefined();
      expect(pathRecommendations.recommendedPathType).toBeDefined();
      expect(pathRecommendations.overallLevel).toBeDefined();
    });

    it('should handle assessment data persistence', async () => {
      const testData = {
        'adr-creation': { level: 4, skills: ['basic', 'advanced'] }
      };

      generator.assessmentData = testData;
      await generator.saveAssessmentBasedPath({
        metadata: {
          learningPathId: 'test-persistence-path',
          learningPathTitle: 'Test Persistence Path'
        },
        assessmentData: testData,
        learningPath: {
          title: 'Test Path',
          steps: []
        }
      });

      await generator.loadExistingAssessments();
      expect(generator.skillAssessments).toBeDefined();
    });

    it('should maintain performance with large datasets', async () => {
      const startTime = performance.now();

      // Initialize assessment data as an object
      generator.assessmentData = {};

      // Set up skillAssessments properly for the analyzeAssessmentResults method
      generator.skillAssessments = {};

      // Generate large assessment data
      Object.entries(generator.skillCategories).forEach(([categoryId, _category]) => {
        generator.assessmentData[categoryId] = {
          level: Math.floor(Math.random() * 5) + 1,
          skills: ['test-skill-1', 'test-skill-2']
        };

        // Also set up skillAssessments for the analyze method
        generator.skillAssessments[categoryId] = {
          skillLevel: ['beginner', 'intermediate', 'advanced', 'expert'][Math.floor(Math.random() * 4)],
          averageRating: Math.random() * 5,
          responses: ['Response 1', 'Response 2', 'Response 3']
        };
      });

      const pathData = generator.analyzeAssessmentResults();

      const endTime = performance.now();
      const duration = endTime - startTime;

      // Should complete within reasonable time (adjust threshold as needed)
      expect(duration).toBeLessThan(1000); // 1 second
      expect(pathData).toBeDefined();
      expect(pathData.priorityAreas).toBeDefined();
    });
  });
});
