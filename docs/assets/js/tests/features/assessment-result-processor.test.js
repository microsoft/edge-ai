/**
 * Assessment Result Processor Tests
 * Comprehensive test suite for assessment-driven dashboard population
 *
 * @description Tests assessment result processing, dashboard population,
 * skill level analysis, and learning path recommendations
 *
 * @version 1.0.0
 * @since 2025-09-03
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { AssessmentResultProcessor } from '../../features/assessment-result-processor.js';

describe('AssessmentResultProcessor', () => {
  let processor;
  let mockDependencies;
  let mockLocalStorage;

  beforeEach(async () => {
    // Setup DOM environment using happy-dom (already available in test environment)
    document.documentElement.innerHTML = `
      <html>
        <head><title>Test</title></head>
        <body>
          <div class="learning-path-item" data-path="getting-started/ai-assisted-development-basics">
            <h3>AI-Assisted Development Basics</h3>
            <div class="dual-checkbox-container">
              <input type="checkbox" data-type="path" id="path-1">
              <input type="checkbox" data-type="completed" id="completed-1">
            </div>
          </div>
          <div class="learning-path-item" data-path="getting-started/containerization-basics">
            <h3>Containerization Basics</h3>
            <div class="dual-checkbox-container">
              <input type="checkbox" data-type="path" id="path-2">
              <input type="checkbox" data-type="completed" id="completed-2">
            </div>
          </div>
          <div class="learning-path-item" data-path="intermediate/advanced-prompt-engineering">
            <h3>Advanced Prompt Engineering</h3>
            <div class="dual-checkbox-container">
              <input type="checkbox" data-type="path" id="path-3">
              <input type="checkbox" data-type="completed" id="completed-3">
            </div>
          </div>
        </body>
      </html>
    `;

    // Mock localStorage
    mockLocalStorage = new Map();
    global.localStorage = {
      getItem: vi.fn((key) => mockLocalStorage.get(key) || null),
      setItem: vi.fn((key, value) => mockLocalStorage.set(key, value)),
      removeItem: vi.fn((key) => mockLocalStorage.delete(key)),
      clear: vi.fn(() => mockLocalStorage.clear()),
      get length() { return mockLocalStorage.size; },
      key: vi.fn((index) => Array.from(mockLocalStorage.keys())[index] || null)
    };

    // Mock dependencies
    mockDependencies = {
      domUtils: {
        waitForElement: vi.fn().mockResolvedValue(document.querySelector('.learning-path-item'))
      },
      errorHandler: {
        safeExecute: vi.fn().mockImplementation(async (fn) => await fn()),
        logInfo: vi.fn(),
        logWarning: vi.fn(),
        logError: vi.fn()
      },
      learningPathManager: {
        savePath: vi.fn().mockResolvedValue(true)
      }
    };

    processor = new AssessmentResultProcessor(mockDependencies);
    await processor.init();
  });

  afterEach(() => {
    mockLocalStorage.clear();
    vi.clearAllMocks();
  });

  describe('Initialization', () => {
    it('should initialize successfully', () => {
      expect(processor.isInitialized).toBe(true);
      expect(mockDependencies.errorHandler.logInfo).toHaveBeenCalledWith(
        'Assessment result processor initialized'
      );
    });

    it('should setup event listeners', async () => {
      // Create a new processor to test event listener setup
      const testProcessor = new AssessmentResultProcessor(mockDependencies);

      // Spy on the handler before initialization
      const handleSpy = vi.spyOn(testProcessor, 'handleAssessmentCompletion');

      // Initialize the processor (this sets up event listeners)
      await testProcessor.init();

      // Test that event listeners are set up by dispatching an event
      const mockEvent = new CustomEvent('learningPathCreated', {
        detail: {
          source: 'assessment',
          pathData: {
            metadata: {
              assessmentData: {
                'ai-assisted-engineering': { q1: 2, q2: 1 }
              }
            }
          }
        }
      });

      document.dispatchEvent(mockEvent);

      expect(handleSpy).toHaveBeenCalled();
    });

    it('should check for pending assessment results on init', async () => {
      // Setup pending assessment data
      mockLocalStorage.set('skillAssessment_test', JSON.stringify({
        assessments: {
          'ai-assisted-engineering': { q1: 3, q2: 4 }
        },
        processed: false
      }));

      // Create new processor to test init behavior
      const newProcessor = new AssessmentResultProcessor(mockDependencies);
      await newProcessor.init();

      // Should have processed the pending assessment
      expect(mockDependencies.errorHandler.logInfo).toHaveBeenCalledWith(
        'Found pending assessment result',
        expect.objectContaining({ key: 'skillAssessment_test' })
      );
    });
  });

  describe('Assessment Score Analysis', () => {
    it('should analyze assessment scores correctly', () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 2, q2: 3, q3: 2 },
        'edge-deployment': { q1: 4, q2: 5, q3: 4 },
        'project-planning': { q1: 1, q2: 2, q3: 1 }
      };

      const analysis = processor.analyzeAssessmentScores(assessmentData);

      expect(analysis.skillLevels).toHaveProperty('ai-assisted-engineering');
      expect(analysis.skillLevels['ai-assisted-engineering'].level).toBe('intermediate');
      expect(analysis.skillLevels['edge-deployment'].level).toBe('advanced');
      expect(analysis.skillLevels['project-planning'].level).toBe('beginner');

      expect(analysis.strengthAreas).toContain('edge-deployment');
      expect(analysis.improvementAreas).toContain('project-planning');
      expect(analysis.priorityAreas).toContain('ai-assisted-engineering');
    });

    it('should determine skill levels correctly', () => {
      expect(processor.determineSkillLevel(1.5)).toBe('beginner');
      expect(processor.determineSkillLevel(3.0)).toBe('intermediate');
      expect(processor.determineSkillLevel(4.0)).toBe('advanced');
      expect(processor.determineSkillLevel(4.8)).toBe('expert');
    });

    it('should calculate overall level accurately', () => {
      const assessmentData = {
        'skill1': { q1: 4, q2: 4 }, // 4.0 average
        'skill2': { q1: 3, q2: 3 }, // 3.0 average
        'skill3': { q1: 2, q2: 2 } // 2.0 average
      };

      const analysis = processor.analyzeAssessmentScores(assessmentData);
      expect(analysis.overallLevel).toBe('intermediate'); // 3.0 overall
      expect(analysis.overallScore).toBe(3.0);
    });
  });

  describe('Learning Path Recommendations', () => {
    it('should generate path recommendations based on analysis', () => {
      const analysisResults = {
        overallLevel: 'intermediate',
        overallScore: 3.0,
        skillLevels: {
          'ai-assisted-engineering': { averageScore: 2.0, level: 'beginner' },
          'edge-deployment': { averageScore: 4.0, level: 'advanced' }
        },
        improvementAreas: ['ai-assisted-engineering'],
        priorityAreas: [],
        strengthAreas: ['edge-deployment']
      };

      const recommendations = processor.generatePathRecommendations(analysisResults);

      expect(recommendations.summary.overallLevel).toBe('intermediate');
      expect(recommendations.itemsToAdd.length).toBeGreaterThan(0);
      expect(recommendations.focusAreas).toContainEqual(
        expect.objectContaining({
          area: 'ai-assisted-engineering',
          level: 'beginner'
        })
      );

      // Should have high priority items for improvement areas
      const highPriorityItems = recommendations.itemsToAdd.filter(item => item.priority === 'high');
      expect(highPriorityItems.length).toBeGreaterThan(0);
    });

    it('should estimate time correctly for different levels', () => {
      expect(processor.estimateItemTime('beginner')).toBe(4);
      expect(processor.estimateItemTime('intermediate')).toBe(6);
      expect(processor.estimateItemTime('advanced')).toBe(8);
      expect(processor.estimateItemTime('unknown')).toBe(5);
    });

    it('should generate appropriate recommendation reasons', () => {
      const skillLevel = { averageScore: 2.0, level: 'beginner' };
      const reason = processor.generateRecommendationReason('ai-assisted-engineering', skillLevel);

      expect(reason).toContain('AI-Assisted Development');
      expect(reason).toContain('2.0/5');
      expect(reason).toContain('foundational concepts');
    });
  });

  describe('Dashboard Population', () => {
    it('should populate dashboard items successfully', async () => {
      const recommendations = {
        itemsToAdd: [
          {
            itemPath: 'getting-started/ai-assisted-development-basics',
            skillArea: 'ai-assisted-engineering',
            level: 'beginner',
            priority: 'high',
            order: 1,
            estimatedTime: 4,
            reason: 'Test reason'
          }
        ],
        summary: { totalItems: 1, priorityCount: 1 },
        focusAreas: [{ area: 'ai-assisted-engineering', level: 'beginner' }],
        estimatedDuration: { hours: 4, weeks: 1 }
      };

      await processor.populateDashboard(recommendations);

      // Check that checkbox was checked
      const pathCheckbox = document.querySelector('[data-path="getting-started/ai-assisted-development-basics"] input[data-type="path"]');
      expect(pathCheckbox.checked).toBe(true);

      // Check that indicator was added
      const indicator = document.querySelector('.assessment-populated-indicator');
      expect(indicator).toBeTruthy();
      expect(indicator.textContent).toContain('Added from assessment');
    });

    it('should add assessment populated class to items', async () => {
      const recommendation = {
        itemPath: 'getting-started/ai-assisted-development-basics',
        skillArea: 'ai-assisted-engineering',
        level: 'beginner',
        priority: 'high',
        reason: 'Test reason'
      };

      const success = await processor.populateItem(recommendation);
      expect(success).toBe(true);

      const item = document.querySelector('[data-path="getting-started/ai-assisted-development-basics"]');
      expect(item.classList.contains('assessment-populated')).toBe(true);
    });

    it('should show population notification', () => {
      const recommendations = {
        summary: { totalItems: 2, priorityCount: 1 },
        focusAreas: [{ area: 'ai-assisted-engineering' }],
        estimatedDuration: { hours: 8, weeks: 1 }
      };

      processor.showPopulationNotification(2, 0, recommendations);

      const notification = document.querySelector('.assessment-population-notification');
      expect(notification).toBeTruthy();
      expect(notification.textContent).toContain('2 items');
      expect(notification.textContent).toContain('added to your learning path');
    });

    it('should handle items not found on dashboard', async () => {
      const recommendation = {
        itemPath: 'non-existent/path',
        skillArea: 'ai-assisted-engineering',
        level: 'beginner',
        priority: 'high',
        reason: 'Test reason'
      };

      const success = await processor.populateItem(recommendation);
      expect(success).toBe(false);

      expect(mockDependencies.errorHandler.logWarning).toHaveBeenCalledWith(
        'Learning item not found on dashboard',
        expect.objectContaining({ itemPath: 'non-existent/path' })
      );
    });
  });

  describe('Event Handling', () => {
    it('should handle learning path creation events', async () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 2, q2: 1 }
      };

      const pathData = {
        metadata: { assessmentData },
        learningPath: { title: 'Test Path' }
      };

      const event = new CustomEvent('learningPathCreated', {
        detail: {
          source: 'assessment',
          pathData
        }
      });

      const processSpy = vi.spyOn(processor, 'processAssessmentResults');
      document.dispatchEvent(event);

      expect(processSpy).toHaveBeenCalledWith(assessmentData, pathData);
    });

    it('should handle direct assessment events', async () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 3, q2: 4 }
      };

      const event = new CustomEvent('assessmentCompleted', {
        detail: { assessmentData }
      });

      const processSpy = vi.spyOn(processor, 'processAssessmentResults');
      document.dispatchEvent(event);

      expect(processSpy).toHaveBeenCalled();
    });

    it('should handle storage change events', () => {
      const assessmentData = {
        assessments: {
          'ai-assisted-engineering': { q1: 3, q2: 4 }
        },
        processed: false
      };

      // Mock StorageEvent using Event with custom properties
      const event = new Event('storage');
      event.key = 'skillAssessment_new';
      event.newValue = JSON.stringify(assessmentData);

      const handleSpy = vi.spyOn(processor, 'handleDirectAssessment');
      window.dispatchEvent(event);

      expect(handleSpy).toHaveBeenCalled();
    });
  });

  describe('Coach System Integration', () => {
    it('should notify coach system of assessment completion', async () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 3, q2: 4 }
      };

      const recommendations = {
        summary: { overallLevel: 'intermediate' },
        focusAreas: [{ area: 'ai-assisted-engineering' }]
      };

      let coachEventFired = false;
      document.addEventListener('assessmentResultsForCoach', () => {
        coachEventFired = true;
      });

      await processor.notifyCoachSystem(assessmentData, recommendations);

      expect(coachEventFired).toBe(true);
      expect(mockLocalStorage.get('latestAssessmentForCoach')).toBeTruthy();
    });
  });

  describe('Manual Processing', () => {
    it('should process manual assessments', async () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 2, q2: 3 },
        'edge-deployment': { q1: 4, q2: 5 }
      };

      const results = await processor.processManualAssessment(assessmentData);

      expect(results.analysis).toBeTruthy();
      expect(results.recommendations).toBeTruthy();
      expect(results.pathData).toBeTruthy();
      expect(results.analysis.skillLevels).toHaveProperty('ai-assisted-engineering');
      expect(results.recommendations.itemsToAdd.length).toBeGreaterThan(0);
    });
  });

  describe('State Management', () => {
    it('should track processing state correctly', () => {
      const state = processor.getProcessingState();

      expect(state.isInitialized).toBe(true);
      expect(state.isProcessing).toBe(false);
      expect(state.processedAt).toBeNull();
      expect(state.results).toBeNull();
    });

    it('should update processing state during processing', async () => {
      const assessmentData = {
        'ai-assisted-engineering': { q1: 3, q2: 4 }
      };

      await processor.processManualAssessment(assessmentData);

      const state = processor.getProcessingState();
      expect(state.processedAt).toBeTruthy();
      expect(state.results).toBeTruthy();
    });
  });

  describe('Path Data Creation', () => {
    it('should create schema-compliant path data', () => {
      const recommendations = {
        summary: { overallLevel: 'intermediate', totalItems: 2 },
        focusAreas: [
          { area: 'ai-assisted-engineering', level: 'beginner' }
        ],
        estimatedDuration: { hours: 8, weeks: 1 },
        itemsToAdd: [
          {
            itemPath: 'getting-started/ai-basics',
            skillArea: 'ai-assisted-engineering',
            level: 'beginner',
            order: 1,
            estimatedTime: 4,
            reason: 'Test reason'
          }
        ]
      };

      const assessmentData = {
        'ai-assisted-engineering': { q1: 2, q2: 3 }
      };

      const pathData = processor.createPathDataFromRecommendations(recommendations, assessmentData);

      expect(pathData.metadata).toBeTruthy();
      expect(pathData.metadata.version).toBe('1.0.0');
      expect(pathData.metadata.source).toBe('assessment-processor');
      expect(pathData.learningPath).toBeTruthy();
      expect(pathData.learningPath.items).toHaveLength(1);
      expect(pathData.learningPath.items[0]).toHaveProperty('id');
      expect(pathData.learningPath.items[0]).toHaveProperty('type', 'learning-item');
    });
  });

  describe('Error Handling', () => {
    it('should handle errors gracefully during processing', async () => {
      // Mock an error in populateItem
      const originalPopulateItem = processor.populateItem;
      processor.populateItem = vi.fn().mockRejectedValue(new Error('Test error'));

      const recommendations = {
        itemsToAdd: [
          {
            itemPath: 'test/path',
            skillArea: 'test',
            level: 'beginner',
            priority: 'high',
            order: 1,
            estimatedTime: 4,
            reason: 'Test'
          }
        ],
        summary: { totalItems: 1, priorityCount: 1 },
        focusAreas: [],
        estimatedDuration: { hours: 4, weeks: 1 }
      };

      // Should not throw despite the error
      await expect(processor.populateDashboard(recommendations)).resolves.not.toThrow();

      // Restore original method
      processor.populateItem = originalPopulateItem;
    });

    it('should handle malformed assessment data', () => {
      const malformedData = {
        'skill1': 'not-an-object',
        'skill2': null,
        'skill3': { q1: 'not-a-number' }
      };

      const analysis = processor.analyzeAssessmentScores(malformedData);

      // Should still produce valid analysis with defaults
      expect(analysis.skillLevels).toBeTruthy();
      expect(analysis.overallLevel).toBeTruthy();
    });
  });
});
