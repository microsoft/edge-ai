/**
 * Integration tests for Assessment Completion Modal Display
 * Tests end-to-end display logic with real data structures from form and generator
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

describe('Assessment Modal Display Integration', () => {
  let modalContainer;
  let AssessmentCompletionModal;
  let modal;

  beforeEach(async () => {
    // Setup DOM
    document.body.innerHTML = `
      <div id="assessment-completion-modal" class="modal-overlay" role="dialog" aria-labelledby="modal-title" aria-modal="true">
        <div class="modal-content">
          <div class="modal-header">
            <h2 id="modal-title">Assessment Complete</h2>
            <button id="assessment-modal-close-x" class="close-btn" aria-label="Close modal">×</button>
          </div>
          <div class="modal-body">
            <div class="skill-badge"></div>
            <div class="completion-percentage"></div>
            <div class="overall-score"></div>
            <div class="path-title"></div>
            <div class="path-description"></div>
            <div class="estimated-duration"></div>
            <div class="chatmode-description"></div>
          </div>
          <div class="modal-footer">
            <button id="assessment-modal-save-path">Save Learning Path</button>
            <button id="assessment-modal-start-coaching">Start Coaching</button>
          </div>
        </div>
      </div>
    `;

    modalContainer = document.getElementById('assessment-completion-modal');

    // Import module
    const module = await import('../../features/assessment-completion-modal.js');
    AssessmentCompletionModal = module.AssessmentCompletionModal;
    modal = new AssessmentCompletionModal();
  });

  afterEach(() => {
    document.body.innerHTML = '';
    vi.clearAllMocks();
  });

  describe('Expert Level Display', () => {
    it('should display "Expert" badge when all scores are 5.0', () => {
      // Exact data structure from user's console log
      const assessmentResults = {
        results: {
          overallScore: 5.0,
          overallLevel: 'expert',
          categoryScores: {
            'ai-assisted-engineering': { score: 5, level: 'expert' },
            'prompt-engineering': { score: 5, level: 'expert' },
            'iac-automation': { score: 5, level: 'expert' },
            'edge-ai-ml': { score: 5, level: 'expert' },
            'testing-quality': { score: 5, level: 'expert' },
            'security-compliance': { score: 5, level: 'expert' }
          }
        },
        questionsAnswered: 18,
        overallScore: 5.0,
        overallLevel: 'expert',
        recommendedPath: 'expert'
      };

      const recommendations = {
        recommendedPathType: 'expert',
        personalizedMessage: 'Master expert concepts and drive innovation',
        estimatedDuration: { hours: 120, weeks: 12 },
        suggestedItems: []
      };

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Expert');
      expect(skillBadge.className).toContain('expert');
    });

    it('should fallback to recommendedPath when recommendedPathType missing', () => {
      const assessmentResults = {
        results: {
          overallScore: 5.0,
          overallLevel: 'expert'
        },
        questionsAnswered: 18,
        overallScore: 5.0,
        overallLevel: 'expert',
        recommendedPath: 'expert'
      };

      // Missing recommendedPathType - should fallback to recommendedPath
      const recommendations = {
        recommendedPath: 'expert',
        personalizedMessage: 'Expert guidance',
        suggestedItems: []
      };

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Expert');
    });

    it('should fallback to overallLevel when recommendations incomplete', () => {
      const assessmentResults = {
        results: {
          overallScore: 5.0,
          overallLevel: 'expert'
        },
        questionsAnswered: 18,
        overallScore: 5.0,
        overallLevel: 'expert'
      };

      // Empty recommendations - should fallback to assessmentResults.overallLevel
      const recommendations = {};

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Expert');
    });

    it('should fallback to nested overallLevel when top-level missing', () => {
      const assessmentResults = {
        results: {
          overallScore: 5.0,
          overallLevel: 'expert'
        },
        questionsAnswered: 18,
        overallScore: 5.0
      };

      const recommendations = {};

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Expert');
    });
  });

  describe('All Skill Levels Display', () => {
    const testCases = [
      { level: 'beginner', expectedDisplay: 'Beginner', expectedTitle: 'Foundation Builder' },
      { level: 'intermediate', expectedDisplay: 'Intermediate', expectedTitle: 'Skill Developer' },
      { level: 'advanced', expectedDisplay: 'Advanced', expectedTitle: 'Advanced Practitioner' },
      { level: 'expert', expectedDisplay: 'Expert', expectedTitle: 'Expert Practitioner' }
    ];

    testCases.forEach(({ level, expectedDisplay, expectedTitle }) => {
      it(`should display "${expectedDisplay}" badge and "${expectedTitle}" title for ${level} level`, () => {
        const assessmentResults = {
          results: {
            overallScore: level === 'beginner' ? 2.0 : level === 'intermediate' ? 3.0 : level === 'advanced' ? 4.0 : 5.0,
            overallLevel: level
          },
          questionsAnswered: 18,
          overallScore: level === 'beginner' ? 2.0 : level === 'intermediate' ? 3.0 : level === 'advanced' ? 4.0 : 5.0,
          overallLevel: level
        };

        const recommendations = {
          recommendedPathType: level,
          personalizedMessage: `${expectedTitle} guidance`,
          suggestedItems: []
        };

        modal.showModal(assessmentResults, recommendations);

        const skillBadge = modalContainer.querySelector('.skill-badge');
        expect(skillBadge.textContent).toBe(expectedDisplay);
        expect(skillBadge.className).toContain(level);

        const pathTitle = modalContainer.querySelector('.path-title');
        expect(pathTitle.textContent).toBe(expectedTitle);
      });
    });
  });

  describe('Nested Results Structure', () => {
    it('should handle nested results.overallLevel correctly', () => {
      const assessmentResults = {
        results: {
          overallScore: 4.5,
          overallLevel: 'advanced',
          categoryScores: {}
        },
        questionsAnswered: 18,
        overallScore: 4.5
        // Missing top-level overallLevel - should use results.overallLevel
      };

      const recommendations = {};

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Advanced');
    });
  });

  describe('Default Fallback Behavior', () => {
    it('should default to Beginner when all fallbacks are missing', () => {
      const assessmentResults = {
        results: {},
        questionsAnswered: 18
      };

      const recommendations = {};

      modal.showModal(assessmentResults, recommendations);

      const skillBadge = modalContainer.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Beginner');
    });
  });
});
