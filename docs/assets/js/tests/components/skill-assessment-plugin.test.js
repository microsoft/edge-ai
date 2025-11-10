/**
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// Import the plugin directly
import '../../plugins/skill-assessment-plugin.js';

describe('Skill Assessment Plugin', () => {

  let testUtils, assessmentPlugin, mockLocalStorage;

  beforeEach(() => {
    // Setup DOM utilities
    testUtils = window.createTestUtilities ? window.createTestUtilities() : {};
    // Mock localStorage
    const storage = {};
    mockLocalStorage = {
      getItem: vi.fn((key) => storage[key] || null),
      setItem: vi.fn((key, value) => { storage[key] = value; }),
      removeItem: vi.fn((key) => { delete storage[key]; }),
      clear: vi.fn(() => { for (const key in storage) delete storage[key]; })
    };
    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage,
      writable: true
    });
    // Setup DOM container
    document.body.innerHTML = `
      <div id="skill-assessment-container">
        <div class="assessment-question" data-question-id="1" data-skill="kubernetes" data-difficulty="beginner" role="group" aria-labelledby="q1-title">
          <h3 id="q1-title">What is Kubernetes?</h3>
          <div class="option" data-correct="true" tabindex="0" role="button" aria-describedby="q1-title">Container orchestration platform</div>
          <div class="option" data-correct="false" tabindex="0" role="button" aria-describedby="q1-title">Database management system</div>
        </div>
        <div class="assessment-question" data-question-id="2" data-skill="azure" data-difficulty="intermediate" role="group" aria-labelledby="q2-title">
          <h3 id="q2-title">What is Azure?</h3>
          <div class="option" data-correct="false" tabindex="0" role="button" aria-describedby="q2-title">Programming language</div>
          <div class="option" data-correct="true" tabindex="0" role="button" aria-describedby="q2-title">Cloud computing platform</div>
        </div>
        <div class="progress-indicator"></div>
        <div class="skill-breakdown"></div>
        <div class="assessment-complete" style="display: none;">Assessment completed!</div>
      </div>
    `;
    // Create plugin instance
    assessmentPlugin = new window.SkillAssessmentPlugin({
      container: '#skill-assessment-container'
    });
    // Initialize the plugin to load questions
    assessmentPlugin.init();
  });

  afterEach(() => {
    // Cleanup
    document.body.innerHTML = '';
    mockLocalStorage.clear.mockClear();
    mockLocalStorage.getItem.mockClear();
    mockLocalStorage.setItem.mockClear();
    testUtils.cleanup && testUtils.cleanup();
    vi.clearAllMocks();
  });

  describe('Plugin Initialization', () => {
    it('should initialize with default configuration', () => {
      const plugin = new window.SkillAssessmentPlugin();
      expect(plugin.config).toEqual({
        container: '#skill-assessment-container',
        autoSave: true,
        trackTime: true,
        storageKey: 'skill-assessment-progress',
        difficultyWeights: {
          beginner: 1,
          intermediate: 2,
          advanced: 3
        }
      });
    });

    it('should merge custom configuration', () => {
      const customConfig = {
        maxRetries: 5,
        showProgress: false
      };
      const plugin = new window.SkillAssessmentPlugin(customConfig);
      expect(plugin.config.maxRetries).toBe(5);
      expect(plugin.config.showProgress).toBe(false);
      expect(plugin.config.autoSave).toBe(true); // Should keep default
    });
  });

  describe('Assessment Data Management', () => {
    it('should track correct and incorrect answers', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      assessmentPlugin.answerQuestion('2', 'A storage solution', false);
      const progress = assessmentPlugin.getProgress();
      expect(progress.correctAnswers).toBe(1);
      expect(progress.answeredQuestions).toBe(2);
    });

    it('should persist progress to localStorage', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      expect(mockLocalStorage.setItem).toHaveBeenCalledWith(
        'skill-assessment-progress',
        expect.stringContaining('"1"')
      );
    });

    it('should load progress from localStorage', () => {
      // Simulate existing progress
      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        answers: {
          '1': { answer: 'A group of containers', correct: true, timestamp: Date.now() },
          '2': { answer: 'Edge platform for IoT', correct: true, timestamp: Date.now() }
        },
        startTime: Date.now() - 5000,
        timestamp: Date.now()
      }));
      const plugin = new window.SkillAssessmentPlugin({ container: '#skill-assessment-container' });
      plugin.loadProgress();
      const progress = plugin.getProgress();
      expect(progress.answeredQuestions).toBe(2);
    });
  });

  describe('Question Loading and Progress', () => {
    it('should load assessment questions from DOM', () => {
      expect(assessmentPlugin.questions).toHaveLength(2);
      expect(assessmentPlugin.questions[0].id).toBe('1');
      expect(assessmentPlugin.questions[0].skill).toBe('kubernetes');
      expect(assessmentPlugin.questions[1].skill).toBe('azure');
    });

    it('should calculate progress percentage', () => {
      // Answer first question
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      const progress = assessmentPlugin.getProgress();
      expect(progress.percentage).toBe(50);
    });

    it('should persist and load progress from localStorage', () => {
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      assessmentPlugin.answerQuestion('2', 'Edge platform for IoT', false);

      const newPlugin = new window.SkillAssessmentPlugin({ container: '#skill-assessment-container' });
      newPlugin.init(); // Initialize to load DOM questions
      const progress = newPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(2);
      expect(progress.correctAnswers).toBe(1);
    });
  });

  describe('Skill Breakdown Analysis', () => {
    it('should categorize progress by skill', () => {
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);  // kubernetes: correct
      assessmentPlugin.answerQuestion('2', 'Programming language', false);  // azure: incorrect
      const breakdown = assessmentPlugin.getSkillProgress();
      expect(breakdown.kubernetes.correct).toBe(1);
      expect(breakdown.kubernetes.total).toBe(1);
    });
  });

  describe('Visual Interface', () => {
    it('should update progress when questions are answered', () => {
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      const progressElement = document.querySelector('.progress-indicator');
      expect(progressElement.textContent).toContain('50%');
    });

    it('should render skill breakdown chart', () => {
      assessmentPlugin.answerQuestion('1', true);
      assessmentPlugin.updateSkillBreakdown();
      const skillBreakdown = document.querySelector('.skill-breakdown');
      expect(skillBreakdown).toBeTruthy();
      expect(skillBreakdown.innerHTML).toContain('kubernetes');
    });

    it('should highlight answered questions', () => {
      const questionElement = document.querySelector('[data-question-id="1"]');
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      expect(questionElement.classList.contains('answered')).toBe(true);
      expect(questionElement.classList.contains('correct')).toBe(true);
    });

    it('should show completion status', () => {
      // Answer all questions to complete assessment
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      assessmentPlugin.answerQuestion('2', 'Cloud computing platform', true);
      expect(assessmentPlugin.isComplete()).toBe(true);
      const completionElement = document.querySelector('.assessment-complete');
      expect(completionElement).toBeTruthy();
    });
  });

  describe('Interaction and Events', () => {
    it('should handle option click events', () => {
      const optionButton = document.querySelector('[data-question-id="1"] .option[data-correct="true"]');
      optionButton.click();
      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(1);
      expect(progress.correctAnswers).toBe(1);
    });

    it('should prevent multiple answers to same question', () => {
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);  // First answer
      assessmentPlugin.answerQuestion('1', 'Database management system', false); // Attempt second answer (should be ignored)
      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(1);
      expect(progress.correctAnswers).toBe(1);
    });

    it('should emit DOM events on progress updates', () => {
      const eventListener = vi.fn();
      document.addEventListener('assessmentProgressUpdated', eventListener);

      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            progress: expect.objectContaining({
              totalQuestions: 2,
              answeredQuestions: 1,
              percentage: 50
            })
          })
        })
      );

      document.removeEventListener('assessmentProgressUpdated', eventListener);
    });

    it('should emit completion event when assessment is finished', () => {
      const eventListener = vi.fn();
      document.addEventListener('assessmentCompleted', eventListener);

      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);
      assessmentPlugin.answerQuestion('2', 'Cloud computing platform', true);

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            finalScore: expect.objectContaining({
              earnedPoints: expect.any(Number),
              totalPoints: expect.any(Number),
              weightedScore: expect.any(Number)
            }),
            timeSpent: expect.any(Number),
            skillBreakdown: expect.any(Object)
          })
        })
      );

      document.removeEventListener('assessmentCompleted', eventListener);
    });
  });

  describe('Desktop-Only Interface', () => {
    it('should not include mobile-specific styling', () => {
      const mobileElements = document.querySelectorAll('[class*="mobile"], [class*="touch"]');
      expect(mobileElements).toHaveLength(0);
    });

    it('should support desktop interaction patterns', () => {
      const questionElements = document.querySelectorAll('.assessment-question');
      expect(questionElements.length).toBeGreaterThan(0);

      // Verify desktop-appropriate tabindex values
      const optionElements = document.querySelectorAll('.option');
      optionElements.forEach(element => {
        expect(element.getAttribute('tabindex')).toBe('0');
      });
    });
  });

  describe('Accessibility', () => {
    it('should have proper ARIA attributes', () => {
      const questionElements = document.querySelectorAll('.assessment-question');
      questionElements.forEach(element => {
        expect(element.getAttribute('role')).toBe('group');
        expect(element.getAttribute('aria-labelledby')).toBeTruthy();
      });
    });

    it('should support keyboard navigation', () => {
      const optionButton = document.querySelector('.option');
      optionButton.focus();

      // Simulate Enter key press
      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' });
      optionButton.dispatchEvent(enterEvent);

      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(1);
    });

    it('should announce progress updates to screen readers', () => {
      assessmentPlugin.answerQuestion('1', 'Container orchestration platform', true);

      const ariaLive = document.querySelector('[aria-live="polite"]');
      expect(ariaLive).toBeTruthy();
      expect(ariaLive.textContent).toContain('Progress: 50%');
    });
  });

  describe('Error Handling', () => {
    it('should handle invalid question IDs gracefully', () => {
      expect(() => {
        assessmentPlugin.answerQuestion('invalid-id', true);
      }).not.toThrow();

      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(0);
    });

    it('should handle localStorage errors gracefully', () => {
      mockLocalStorage.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      expect(() => {
        assessmentPlugin.answerQuestion('1', true);
      }).not.toThrow();
    });

    it('should handle missing DOM elements gracefully', () => {
      // Remove all assessment questions from DOM
      document.body.innerHTML = '<div id="skill-assessment-container"></div>';

      const newPlugin = new window.SkillAssessmentPlugin({ container: '#skill-assessment-container' });

      expect(() => {
        newPlugin.init();
      }).not.toThrow();

      expect(newPlugin.questions).toHaveLength(0);
    });
  });
});
