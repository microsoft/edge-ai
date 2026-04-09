/**
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

describe('Skill Assessment Plugin', () => {
  let mockLocalStorage;
  let assessmentPlugin;

  beforeEach(() => {
    // Setup DOM with comprehensive assessment structure
    document.body.innerHTML = `
      <div id="skill-assessment-container">
        <div class="assessment-question" data-question-id="1" data-skill="kubernetes" data-difficulty="beginner">
          <h3>What is a Pod in Kubernetes?</h3>
          <div class="question-options">
            <button class="option" data-correct="true">A group of containers</button>
            <button class="option" data-correct="false">A single container</button>
            <button class="option" data-correct="false">A cluster node</button>
          </div>
        </div>
        <div class="assessment-question" data-question-id="2" data-skill="azure" data-difficulty="intermediate">
          <h3>What is Azure IoT Operations?</h3>
          <div class="question-options">
            <button class="option" data-correct="false">A database service</button>
            <button class="option" data-correct="true">Edge platform for IoT</button>
            <button class="option" data-correct="false">A storage solution</button>
          </div>
        </div>
        <div id="assessment-progress">
          <div class="progress-indicator"></div>
          <div class="skill-breakdown"></div>
        </div>
      </div>
    `;

    // Mock localStorage with comprehensive interface
    mockLocalStorage = {};
    vi.stubGlobal('localStorage', {
      getItem: vi.fn((key) => mockLocalStorage[key] || null),
      setItem: vi.fn((key, value) => { mockLocalStorage[key] = value; }),
      removeItem: vi.fn((key) => { delete mockLocalStorage[key]; }),
      clear: vi.fn(() => { mockLocalStorage = {}; })
    });

    // Mock performance API for time tracking
    vi.stubGlobal('performance', {
      now: vi.fn(() => Date.now())
    });

    // NOTE: Do not delete the plugin from window/globalThis as it's needed for tests
    // The plugin is loaded by plugin-loader.js setup file

    // Mock console methods
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
    mockLocalStorage = {};
    document.body.innerHTML = '';
  });

  describe('Plugin Initialization', () => {
    it('should initialize plugin with default configuration', () => {
      // This test should fail initially until plugin is implemented
      expect(() => {
        assessmentPlugin = new window.SkillAssessmentPlugin();
      }).not.toThrow();      expect(assessmentPlugin).toBeDefined();
      expect(assessmentPlugin.config).toBeDefined();
      expect(assessmentPlugin.config.autoSave).toBe(true);
      expect(assessmentPlugin.config.trackTime).toBe(true);
    });

    it('should initialize plugin with custom configuration', () => {
      const customConfig = {
        autoSave: false,
        trackTime: false,
        container: '#custom-container'
      };

      assessmentPlugin = new window.SkillAssessmentPlugin(customConfig);
      expect(assessmentPlugin.config.autoSave).toBe(false);
      expect(assessmentPlugin.config.trackTime).toBe(false);
      expect(assessmentPlugin.config.container).toBe('#custom-container');
    });

    it('should find and bind to assessment questions', () => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();

      expect(assessmentPlugin.questions).toHaveLength(2);
      expect(assessmentPlugin.questions[0].id).toBe('1');
      expect(assessmentPlugin.questions[0].skill).toBe('kubernetes');
      expect(assessmentPlugin.questions[1].id).toBe('2');
      expect(assessmentPlugin.questions[1].skill).toBe('azure');
    });

    it('should handle missing DOM elements gracefully', () => {
      document.body.innerHTML = '';

      expect(() => {
        assessmentPlugin = new window.SkillAssessmentPlugin();
        assessmentPlugin.init();
      }).not.toThrow();
    });
  });

  describe('Assessment Questions Management', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should parse and display assessment questions', () => {
      const questions = assessmentPlugin.questions;
      expect(questions).toHaveLength(2);

      const kubernetesQuestion = questions.find(q => q.skill === 'kubernetes');
      expect(kubernetesQuestion).toBeDefined();
      expect(kubernetesQuestion.difficulty).toBe('beginner');
    });

    it('should handle different question types and difficulties', () => {
      const questions = assessmentPlugin.questions;
      const difficulties = questions.map(q => q.difficulty);
      const skills = questions.map(q => q.skill);

      expect(difficulties).toContain('beginner');
      expect(difficulties).toContain('intermediate');
      expect(skills).toContain('kubernetes');
      expect(skills).toContain('azure');
    });

    it('should validate answer choices', () => {
      const firstQuestion = assessmentPlugin.questions[0];
      const options = firstQuestion.options;

      expect(options).toBeDefined();
      expect(options.some(opt => opt.correct === true)).toBe(true);
      expect(options.some(opt => opt.correct === false)).toBe(true);
    });

    it('should validate question data integrity', () => {
      // Remove required data attributes from a question
      const question = document.querySelector('.assessment-question');
      question.removeAttribute('data-skill');

      const newPlugin = new window.SkillAssessmentPlugin();
      newPlugin.init();

      // Should filter out invalid questions
      expect(newPlugin.questions.length).toBeLessThan(2);
    });
  });

  describe('Progress Tracking and Scoring', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should track question completion and calculate overall progress', () => {
      // Answer first question correctly
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      const progress = assessmentPlugin.getProgress();
      expect(progress.totalQuestions).toBe(2);
      expect(progress.answeredQuestions).toBe(1);
      expect(progress.correctAnswers).toBe(1);
      expect(progress.percentage).toBe(50);
    });

    it('should track skill-specific progress', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      assessmentPlugin.answerQuestion('2', 'Edge platform for IoT', true);

      const skillProgress = assessmentPlugin.getSkillProgress();
      expect(skillProgress.kubernetes.total).toBe(1);
      expect(skillProgress.kubernetes.correct).toBe(1);
      expect(skillProgress.azure.total).toBe(1);
      expect(skillProgress.azure.correct).toBe(1);
    });

    it('should calculate difficulty-based weighted scoring', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);  // beginner
      assessmentPlugin.answerQuestion('2', 'Edge platform for IoT', true);  // intermediate

      const score = assessmentPlugin.calculateWeightedScore();
      expect(score.totalPoints).toBeGreaterThan(0);
      expect(score.weightedScore).toBeGreaterThan(score.totalPoints / 2); // intermediate worth more
    });

    it('should track time spent on assessment', () => {
      vi.useFakeTimers();

      const startTime = assessmentPlugin.getStartTime();
      expect(startTime).toBeGreaterThan(0);

      // Simulate time passing
      vi.advanceTimersByTime(30000); // 30 seconds

      const timeSpent = assessmentPlugin.getTimeSpent();
      expect(timeSpent).toBeGreaterThanOrEqual(30000);

      vi.useRealTimers();
    });

    it('should calculate skill assessment scores', () => {
      // Answer questions with different correctness
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);   // Correct
      assessmentPlugin.answerQuestion('2', 'A database service', false);     // Incorrect

      const finalScore = assessmentPlugin.getFinalScore();
      expect(finalScore.accuracy).toBe(0.5); // 50% correct
      expect(finalScore.skillBreakdown.kubernetes.accuracy).toBe(1.0);
      expect(finalScore.skillBreakdown.azure.accuracy).toBe(0.0);
    });
  });

  describe('LocalStorage Persistence', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should persist assessment progress automatically', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'skill-assessment-progress',
        expect.stringContaining('"1"')
      );
    });

    it('should load previous progress from localStorage', () => {
      // Setup existing progress
      const existingProgress = {
        answers: { '1': { answer: 'A group of containers', correct: true, timestamp: Date.now() } },
        startTime: Date.now() - 60000
      };
      mockLocalStorage['skill-assessment-progress'] = JSON.stringify(existingProgress);

      const newPlugin = new window.SkillAssessmentPlugin();
      newPlugin.init();

      const progress = newPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(1);
      expect(progress.correctAnswers).toBe(1);
    });

    it('should handle corrupted localStorage data gracefully', () => {
      mockLocalStorage['skill-assessment-progress'] = 'invalid-json';

      expect(() => {
        const newPlugin = new window.SkillAssessmentPlugin();
        newPlugin.init();
      }).not.toThrow();
    });

    it('should handle localStorage errors gracefully', () => {
      // Mock localStorage failure
      localStorage.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      expect(() => {
        assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      }).not.toThrow();
    });
  });

  describe('Event Handling and User Interactions', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should handle answer selection clicks', () => {
      const optionButton = document.querySelector('.option[data-correct="true"]');
      const questionContainer = optionButton.closest('.assessment-question');

      // Mock event listener
      const eventSpy = vi.fn();
      assessmentPlugin.onQuestionAnswered = eventSpy;

      optionButton.click();

      expect(eventSpy).toHaveBeenCalledWith({
        questionId: '1',
        answer: 'A group of containers',
        correct: true,
        skill: 'kubernetes',
        difficulty: 'beginner'
      });
    });

    it('should provide immediate feedback on answers', () => {
      const optionButton = document.querySelector('.option[data-correct="true"]');
      optionButton.click();

      // Should show feedback UI
      const feedback = document.querySelector('.answer-feedback');
      expect(feedback).toBeDefined();
      expect(feedback.classList.contains('correct')).toBe(true);
    });

    it('should emit custom events for progress updates', () => {
      const eventSpy = vi.fn();
      document.addEventListener('assessmentProgressUpdated', eventSpy);

      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            progress: expect.any(Object),
            skillProgress: expect.any(Object)
          })
        })
      );
    });

    it('should handle assessment completion', () => {
      const completionSpy = vi.fn();
      document.addEventListener('assessmentCompleted', completionSpy);

      // Answer all questions
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      assessmentPlugin.answerQuestion('2', 'Edge platform for IoT', true);

      expect(completionSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            finalScore: expect.any(Object),
            timeSpent: expect.any(Number),
            skillBreakdown: expect.any(Object)
          })
        })
      );
    });

    it('should support assessment navigation', () => {
      // Mock navigation functionality
      expect(assessmentPlugin.canNavigateToQuestion).toBeDefined();
      expect(assessmentPlugin.goToQuestion).toBeDefined();
      expect(assessmentPlugin.goToNextQuestion).toBeDefined();
      expect(assessmentPlugin.goToPreviousQuestion).toBeDefined();
    });
  });

  describe('Progress Visualization', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should update progress indicator UI', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      const progressIndicator = document.querySelector('.progress-indicator');
      expect(progressIndicator.innerHTML).toContain('50%');
      expect(progressIndicator.innerHTML).toContain('1 of 2');
    });

    it('should update skill breakdown UI', () => {
      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      const skillBreakdown = document.querySelector('.skill-breakdown');
      expect(skillBreakdown.innerHTML).toContain('kubernetes');
      expect(skillBreakdown.innerHTML).toContain('1/1');
    });

    it('should handle responsive progress display', () => {
      // Simulate mobile viewport
      Object.defineProperty(window, 'innerWidth', { value: 400 });

      assessmentPlugin.answerQuestion('1', 'A group of containers', true);
      assessmentPlugin.updateProgressDisplay();

      const progressIndicator = document.querySelector('.progress-indicator');
      expect(progressIndicator.classList.contains('mobile-layout')).toBe(true);
    });
  });

  describe('Accessibility Features', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should have proper ARIA attributes', () => {
      const questions = document.querySelectorAll('.assessment-question');
      questions.forEach(question => {
        expect(question.getAttribute('role')).toBeDefined();
        expect(question.getAttribute('aria-labelledby')).toBeDefined();
      });

      const options = document.querySelectorAll('.option');
      options.forEach(option => {
        expect(option.getAttribute('role')).toBe('button');
        expect(option.getAttribute('tabindex')).toBeDefined();
      });
    });

    it('should support keyboard navigation', () => {
      const firstOption = document.querySelector('.option');
      firstOption.focus();

      // Simulate Enter key
      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' });
      firstOption.dispatchEvent(enterEvent);

      // Focus should move appropriately
      expect(document.activeElement).toBeDefined();
    });

    it('should provide screen reader announcements', () => {
      const ariaLive = document.querySelector('[aria-live]');

      assessmentPlugin.answerQuestion('1', 'A group of containers', true);

      expect(ariaLive.textContent).toContain('Question 1 answered correctly');
      expect(ariaLive.textContent).toContain('Progress: 50%');
    });

    it('should manage focus for keyboard navigation', () => {
      const firstOption = document.querySelector('.option');
      firstOption.focus();

      // Simulate arrow key navigation
      const arrowEvent = new KeyboardEvent('keydown', { key: 'ArrowDown' });
      firstOption.dispatchEvent(arrowEvent);

      // Focus should move to next option
      expect(document.activeElement).not.toBe(firstOption);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    beforeEach(() => {
      assessmentPlugin = new window.SkillAssessmentPlugin();
      assessmentPlugin.init();
    });

    it('should handle invalid question IDs gracefully', () => {
      expect(() => {
        assessmentPlugin.answerQuestion('invalid-id', 'Some answer', true);
      }).not.toThrow();

      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(0);
    });

    it('should gracefully handle malformed question data', () => {
      // Test with malformed DOM structure
      document.body.innerHTML = `
        <div class="assessment-question">
          <!-- Missing required data attributes -->
          <h3>Incomplete Question</h3>
        </div>
      `;

      expect(() => {
        const newPlugin = new window.SkillAssessmentPlugin();
        newPlugin.init();
      }).not.toThrow();
    });

    it('should handle network connectivity issues', () => {
      // Mock offline scenario
      Object.defineProperty(navigator, 'onLine', {
        writable: true,
        value: false
      });

      expect(() => {
        assessmentPlugin.syncProgress();
      }).not.toThrow();
    });

    it('should validate answer data before processing', () => {
      // Test with invalid answer data
      expect(() => {
        assessmentPlugin.answerQuestion('1', null, 'invalid-boolean');
      }).not.toThrow();

      const progress = assessmentPlugin.getProgress();
      expect(progress.answeredQuestions).toBe(0); // Should not count invalid answer
    });
  });
});
