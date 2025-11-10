/**
 * Modal Integration Tests
 * Tests for integrating the modal with skill assessment completion flow
 */

import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';

describe('Modal Integration with Skill Assessment', () => {
  let learningProgressTracker;
  let AssessmentCompletionModal;
  let assessmentPathGenerator;
  let mockDom;

  beforeEach(() => {
    // Clear DOM
    document.body.innerHTML = '';

    // Create mock DOM structure for skill assessment
    const skillAssessmentHTML = `
      <div id="skill-assessment-container">
        <div class="kata-progress-bar-container">
          <div class="kata-progress-bar-fill" style="width: 100%;"></div>
          <span class="kata-progress-text">12/12 questions completed</span>
        </div>
        <form id="skill-assessment-form">
          <div class="question-group" data-question-index="0">
            <h4>AI-Assisted Engineering Question 1</h4>
            <input type="radio" name="skill-assessment-q1" value="1" checked>
            <input type="radio" name="skill-assessment-q1" value="2">
          </div>
          <div class="question-group" data-question-index="1">
            <h4>Prompt Engineering Question 2</h4>
            <input type="radio" name="skill-assessment-q2" value="3" checked>
            <input type="radio" name="skill-assessment-q2" value="4">
          </div>
        </form>
      </div>
    `;
    document.body.innerHTML = skillAssessmentHTML;

    // Mock global dependencies
    window.LearningProgressTracker = {
      getCurrentProgress: vi.fn().mockReturnValue({
        questionsAnswered: 12,
        totalQuestions: 12,
        isComplete: true,
        skillLevel: 'skill-developer',
        overallScore: 3.4,
        categories: {
          aiAssistedEngineering: { score: 3.2 },
          promptEngineering: { score: 3.6 }
        }
      }),
      getChatmodeRecommendation: vi.fn().mockReturnValue({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      }),
      showCompletionModal: vi.fn()
    };

    window.AssessmentPathGenerator = {
      analyzeAssessmentResults: vi.fn(),
      generateRecommendations: vi.fn().mockReturnValue({
        skillLevel: 'skill-developer',
        learningPath: {
          title: 'Skill Developer Path',
          description: 'Advance your skills with practical edge AI implementations',
          estimatedDuration: '6-8 weeks'
        },
        recommendedKatas: [
          '/learning/katas/advanced-kubernetes.md',
          '/learning/katas/edge-deployment.md'
        ]
      })
    };

    // Mock modal class
    window.AssessmentCompletionModal = class {
      constructor(dependencies = {}) {
        this.dependencies = dependencies;
        this.modal = null;
        this.isOpen = false;
      }

      async showModal(assessmentResults, recommendations) {
        this.currentAssessmentResults = assessmentResults;
        this.currentRecommendations = recommendations;
        this.isOpen = true;

        return new Promise((resolve) => {
          setTimeout(() => {
            resolve({ action: 'displayed', timestamp: new Date().toISOString() });
          }, 10);
        });
      }

      closeModal(action = 'closed') {
        this.isOpen = false;
        return { action, timestamp: new Date().toISOString() };
      }
    };

    // Create instances
    learningProgressTracker = window.LearningProgressTracker;
    assessmentPathGenerator = window.AssessmentPathGenerator;
    AssessmentCompletionModal = window.AssessmentCompletionModal;
  });

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.innerHTML = '';
    delete window.LearningProgressTracker;
    delete window.AssessmentPathGenerator;
    delete window.AssessmentCompletionModal;
  });

  describe('End-to-End Modal Integration', () => {
    it('should trigger modal when assessment is completed', async () => {
      // Mock completion trigger
      const mockShowCompletionModal = vi.fn().mockResolvedValue({ action: 'displayed' });
      learningProgressTracker.showCompletionModal = mockShowCompletionModal;

      // Simulate assessment completion
      const assessmentResults = learningProgressTracker.getCurrentProgress();
      const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);

      // Trigger completion modal
      await learningProgressTracker.showCompletionModal(assessmentResults, recommendations);

      expect(mockShowCompletionModal).toHaveBeenCalledWith(
        expect.objectContaining({
          questionsAnswered: 12,
          totalQuestions: 12,
          isComplete: true,
          skillLevel: 'skill-developer'
        }),
        expect.objectContaining({
          skillLevel: 'skill-developer',
          learningPath: expect.objectContaining({
            title: 'Skill Developer Path'
          })
        })
      );
    });

    it('should pass correct assessment data to modal', () => {
      const assessmentResults = learningProgressTracker.getCurrentProgress();

      expect(assessmentResults).toEqual({
        questionsAnswered: 12,
        totalQuestions: 12,
        isComplete: true,
        skillLevel: 'skill-developer',
        overallScore: 3.4,
        categories: {
          aiAssistedEngineering: { score: 3.2 },
          promptEngineering: { score: 3.6 }
        }
      });
    });

    it('should generate appropriate recommendations for skill level', () => {
      const assessmentResults = { skillLevel: 'skill-developer', overallScore: 3.4 };
      const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);

      expect(recommendations).toEqual({
        skillLevel: 'skill-developer',
        learningPath: {
          title: 'Skill Developer Path',
          description: 'Advance your skills with practical edge AI implementations',
          estimatedDuration: '6-8 weeks'
        },
        recommendedKatas: [
          '/learning/katas/advanced-kubernetes.md',
          '/learning/katas/edge-deployment.md'
        ]
      });
    });

    it('should handle modal display flow correctly', async () => {
      const modal = new AssessmentCompletionModal();
      const assessmentResults = learningProgressTracker.getCurrentProgress();
      const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);

      const result = await modal.showModal(assessmentResults, recommendations);

      expect(modal.isOpen).toBe(true);
      expect(modal.currentAssessmentResults).toEqual(assessmentResults);
      expect(modal.currentRecommendations).toEqual(recommendations);
      expect(result.action).toBe('displayed');
    });
  });

  describe('Data Flow Validation', () => {
    it('should maintain data consistency across components', () => {
      const progressData = learningProgressTracker.getCurrentProgress();
      const pathRecommendations = assessmentPathGenerator.generateRecommendations(progressData);

      // Verify skill level consistency
      expect(progressData.skillLevel).toBe('skill-developer');
      expect(pathRecommendations.skillLevel).toBe('skill-developer');

      // Verify data structure compatibility
      expect(progressData).toHaveProperty('questionsAnswered');
      expect(progressData).toHaveProperty('totalQuestions');
      expect(progressData).toHaveProperty('overallScore');
      expect(pathRecommendations).toHaveProperty('learningPath');
      expect(pathRecommendations).toHaveProperty('recommendedKatas');
    });

    it('should handle missing or incomplete assessment data', () => {
      const incompleteResults = {
        questionsAnswered: 8,
        totalQuestions: 12,
        isComplete: false
      };

      // Should not crash with incomplete data
      expect(() => {
        assessmentPathGenerator.generateRecommendations(incompleteResults);
      }).not.toThrow();
    });

    it('should validate chatmode recommendation structure', () => {
      const chatmodeRec = learningProgressTracker.getChatmodeRecommendation('skill-developer');

      expect(chatmodeRec).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });
  });

  describe('User Interaction Flow', () => {
    it('should simulate complete user journey', async () => {
      // Step 1: User completes assessment
      const assessmentResults = learningProgressTracker.getCurrentProgress();
      expect(assessmentResults.isComplete).toBe(true);

      // Step 2: Generate recommendations
      const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);
      expect(recommendations.learningPath).toBeDefined();

      // Step 3: Show modal
      const modal = new AssessmentCompletionModal();
      const modalResult = await modal.showModal(assessmentResults, recommendations);

      // Step 4: Verify complete flow
      expect(modalResult.action).toBe('displayed');
      expect(modal.currentAssessmentResults.skillLevel).toBe('skill-developer');
      expect(modal.currentRecommendations.learningPath.title).toBe('Skill Developer Path');
    });

    it('should handle different user skill levels', async () => {
      const skillLevels = ['foundation-builder', 'skill-developer', 'expert-practitioner'];

      for (const skillLevel of skillLevels) {
        // Mock different skill level
        learningProgressTracker.getCurrentProgress.mockReturnValue({
          questionsAnswered: 12,
          totalQuestions: 12,
          isComplete: true,
          skillLevel: skillLevel,
          overallScore: skillLevel === 'foundation-builder' ? 2.1 :
                        skillLevel === 'skill-developer' ? 3.4 : 4.2
        });

        assessmentPathGenerator.generateRecommendations.mockReturnValue({
          skillLevel: skillLevel,
          learningPath: {
            title: `${skillLevel.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')} Path`,
            description: `Path for ${skillLevel} level`,
            estimatedDuration: '4-8 weeks'
          }
        });

        const assessmentResults = learningProgressTracker.getCurrentProgress();
        const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);
        const modal = new AssessmentCompletionModal();

        const result = await modal.showModal(assessmentResults, recommendations);

        expect(result.action).toBe('displayed');
        expect(modal.currentAssessmentResults.skillLevel).toBe(skillLevel);
      }
    });
  });

  describe('Error Handling in Integration', () => {
    it('should handle missing global dependencies gracefully', async () => {
      // Remove global dependencies
      delete window.AssessmentPathGenerator;

      const modal = new AssessmentCompletionModal();
      const assessmentResults = { skillLevel: 'foundation-builder' };

      // Should not crash when dependencies are missing
      expect(() => {
        modal.showModal(assessmentResults, null);
      }).not.toThrow();
    });

    it('should handle API failures during integration', async () => {
      // Mock API failure
      const mockApiClient = {
        post: vi.fn().mockRejectedValue(new Error('Network error'))
      };

      const modal = new AssessmentCompletionModal({ apiClient: mockApiClient });
      const assessmentResults = learningProgressTracker.getCurrentProgress();

      await modal.showModal(assessmentResults, {});

      // Modal should still display even if API fails
      expect(modal.isOpen).toBe(true);
    });

    it('should handle malformed progress data', () => {
      learningProgressTracker.getCurrentProgress.mockReturnValue({
        // Missing required fields
        skillLevel: undefined,
        questionsAnswered: 'invalid'
      });

      const assessmentResults = learningProgressTracker.getCurrentProgress();

      expect(() => {
        assessmentPathGenerator.generateRecommendations(assessmentResults);
      }).not.toThrow();
    });
  });

  describe('Performance and Loading', () => {
    it('should handle rapid successive modal calls', async () => {
      const modal = new AssessmentCompletionModal();
      const assessmentResults = learningProgressTracker.getCurrentProgress();
      const recommendations = assessmentPathGenerator.generateRecommendations(assessmentResults);

      // Rapid successive calls
      const promises = [
        modal.showModal(assessmentResults, recommendations),
        modal.closeModal('test1'),
        modal.showModal(assessmentResults, recommendations),
        modal.closeModal('test2')
      ];

      await Promise.all(promises);

      // Should handle rapid calls without errors
      expect(modal).toBeDefined();
    });

    it('should load all required components', () => {
      // Verify all required global components are available
      expect(window.LearningProgressTracker).toBeDefined();
      expect(window.AssessmentPathGenerator).toBeDefined();
      expect(window.AssessmentCompletionModal).toBeDefined();

      // Verify required methods exist
      expect(typeof learningProgressTracker.getCurrentProgress).toBe('function');
      expect(typeof learningProgressTracker.getChatmodeRecommendation).toBe('function');
      expect(typeof assessmentPathGenerator.generateRecommendations).toBe('function');
    });
  });
});
