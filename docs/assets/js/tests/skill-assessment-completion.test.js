/**
 * Skill Assessment Completion Experience Tests
 * Tests for personalized learning path recommendations and chatmode guidance
 */

import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';

describe('Skill Assessment Completion Experience', () => {
  let mockAssessmentResults;
  let mockAssessmentGenerator;

  beforeEach(() => {
    // Mock assessment results with different skill levels
    mockAssessmentResults = {
      beginner: {
        categories: {
          aiAssistedEngineering: { score: 2.0 },
          promptEngineering: { score: 1.5 },
          edgeDeployment: { score: 2.2 },
          systemTroubleshooting: { score: 1.8 }
        },
        overallScore: 1.9,
        skillLevel: 'beginner'
      },
      intermediate: {
        categories: {
          aiAssistedEngineering: { score: 3.2 },
          promptEngineering: { score: 2.8 },
          edgeDeployment: { score: 3.0 },
          systemTroubleshooting: { score: 3.1 }
        },
        overallScore: 3.0,
        skillLevel: 'intermediate'
      },
      advanced: {
        categories: {
          aiAssistedEngineering: { score: 4.2 },
          promptEngineering: { score: 4.0 },
          edgeDeployment: { score: 3.8 },
          systemTroubleshooting: { score: 4.1 }
        },
        overallScore: 4.0,
        skillLevel: 'advanced'
      }
    };

    // Mock the assessment path generator
    mockAssessmentGenerator = {
      analyzeAssessmentResults: vi.fn(),
      generateRecommendations: vi.fn(),
      renderLearningPath: vi.fn()
    };

    // Mock global assessment path generator
    global.assessmentPathGenerator = mockAssessmentGenerator;

    // Set up DOM
    document.body.innerHTML = `
      <div id="learning-progress-banner">
        <div class="kata-progress-status"></div>
        <div class="kata-progress-percentage">100% Complete (12/12 sections)</div>
      </div>
    `;
  });

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.innerHTML = '';
    delete global.assessmentPathGenerator;
  });

  describe('generatePersonalizedCompletionMessage', () => {
    it('should generate generic completion message when no assessment path generator', () => {
      // Arrange
      const mockResults = {
        skillLevel: 'beginner',
        score: 25,
        totalQuestions: 10
      };

      // Act
      const message = window.learningProgressTracker.generatePersonalizedCompletionMessage(mockResults);

      // Assert
      expect(message).toContain('🎉 Assessment Complete!');
      expect(message).toContain('Kata Coach');
      expect(message).toContain('customized recommendations based on your assessment results');
    });

    it('should handle missing assessment results gracefully', () => {
      // Act
      const message = window.learningProgressTracker.generatePersonalizedCompletionMessage(null);

      // Assert
      expect(message).toContain('Assessment Complete');
      expect(message).toContain('Learning Dashboard');
      expect(message).toContain('Kata Coach');
    });
  });

  describe('getChatmodeRecommendation', () => {
    it('should recommend kata coach for beginner skill level', () => {
      // Arrange
      const beginnerResults = { skillLevel: 'beginner' };

      // Act
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(beginnerResults);

      // Assert
      expect(recommendation).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });

    it('should recommend kata coach for intermediate skill level', () => {
      // Arrange
      const intermediateResults = { skillLevel: 'intermediate' };

      // Act
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(intermediateResults);

      // Assert
      expect(recommendation).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });

    it('should recommend kata coach for advanced skill level', () => {
      // Arrange
      const advancedResults = { skillLevel: 'advanced' };

      // Act
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(advancedResults);

      // Assert
      expect(recommendation).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });

    it('should handle missing assessment results', () => {
      // Act
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(null);

      // Assert
      expect(recommendation).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });

    it('should fallback to kata coach for unknown skill levels', () => {
      // Arrange
      const unknownResults = { skillLevel: 'unknown' };

      // Act
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(unknownResults);

      // Assert
      expect(recommendation).toEqual({
        chatmode: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      });
    });
  });

  describe('Integration Tests', () => {
    it('should provide complete enhanced completion experience for beginner', () => {
      // Arrange
      const assessmentResults = mockAssessmentResults.beginner;

      // Act
      const personalizedMessage = window.learningProgressTracker.generatePersonalizedCompletionMessage(assessmentResults);
      const recommendation = window.learningProgressTracker.getChatmodeRecommendation(assessmentResults);

      // Assert
      expect(personalizedMessage).toContain('Assessment Complete');
      expect(recommendation.chatmode).toBe('learning-kata-coach');
    });

    it('should handle assessment result parsing errors gracefully', () => {
      // Arrange
      const corruptedResults = { invalid: 'data' };

      // Act & Assert (should not throw)
      expect(() => {
        window.learningProgressTracker.generatePersonalizedCompletionMessage(corruptedResults);
        window.learningProgressTracker.getChatmodeRecommendation(corruptedResults);
      }).not.toThrow();
    });
  });
});
