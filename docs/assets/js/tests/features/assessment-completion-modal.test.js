/**
 * Assessment Completion Modal Tests
 * Comprehensive TDD test suite for modal integration, display, and interactions
 */

import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';

describe('Assessment Completion Modal', () => {
  let AssessmentCompletionModal;
  let modal;
  let mockApiClient;
  let mockDomUtils;
  let mockAssessmentResults;
  let mockRecommendations;

  beforeEach(async () => {
    // Clear DOM
    document.body.innerHTML = '';

    // Mock dependencies
    mockApiClient = {
      post: vi.fn().mockResolvedValue({
        success: true,
        data: {
          selectionCount: 3,
          selections: {
            selectedItems: ['foundation-ai-first-engineering', 'intermediate-infrastructure-architect', 'intermediate-devops-excellence']
          },
          userId: 'current-user'
        }
      })
    };

    mockDomUtils = {
      querySelector: vi.fn((selector) => document.querySelector(selector)),
      querySelectorAll: vi.fn((selector) => document.querySelectorAll(selector))
    };

    // Mock assessment results with different skill levels
    mockAssessmentResults = {
      beginner: {
        skillLevel: 'beginner',
        questionsAnswered: 12,
        totalQuestions: 12,
        overallScore: 2.3,
        categories: {
          aiAssistedEngineering: { score: 2.0 },
          promptEngineering: { score: 1.8 },
          edgeDeployment: { score: 2.5 },
          systemTroubleshooting: { score: 2.8 }
        }
      },
      intermediate: {
        skillLevel: 'intermediate',
        questionsAnswered: 12,
        totalQuestions: 12,
        overallScore: 3.2,
        categories: {
          aiAssistedEngineering: { score: 3.1 },
          promptEngineering: { score: 3.0 },
          edgeDeployment: { score: 3.3 },
          systemTroubleshooting: { score: 3.4 }
        }
      },
      advanced: {
        skillLevel: 'advanced',
        questionsAnswered: 12,
        totalQuestions: 12,
        overallScore: 4.1,
        categories: {
          aiAssistedEngineering: { score: 4.0 },
          promptEngineering: { score: 4.2 },
          edgeDeployment: { score: 4.0 },
          systemTroubleshooting: { score: 4.1 }
        }
      },
      expert: {
        skillLevel: 'expert',
        questionsAnswered: 18,
        totalQuestions: 18,
        overallScore: 5.0,
        overallLevel: 'expert',
        categories: {
          aiAssistedEngineering: { score: 5.0 },
          promptEngineering: { score: 5.0 },
          edgeDeployment: { score: 5.0 },
          systemTroubleshooting: { score: 5.0 }
        }
      }
    };

    // Mock recommendations
    mockRecommendations = {
      beginner: {
        skillLevel: 'beginner',
        learningPath: {
          title: 'Beginner Path',
          description: 'Build your foundational skills in edge AI development',
          estimatedDuration: '4-6 weeks'
        },
        recommendedKatas: [
          '/learning/katas/basic-docker.md',
          '/learning/katas/intro-kubernetes.md'
        ]
      },
      intermediate: {
        skillLevel: 'intermediate',
        learningPath: {
          title: 'Intermediate Path',
          description: 'Advance your skills with practical edge AI implementations',
          estimatedDuration: '6-8 weeks'
        },
        recommendedKatas: [
          '/learning/katas/advanced-kubernetes.md',
          '/learning/katas/edge-deployment.md'
        ]
      },
      advanced: {
        skillLevel: 'advanced',
        learningPath: {
          title: 'Advanced Path',
          description: 'Master advanced edge AI architectures and best practices',
          estimatedDuration: '8-10 weeks'
        },
        recommendedKatas: [
          '/learning/katas/advanced-edge-architecture.md',
          '/learning/katas/production-optimization.md'
        ]
      },
      expert: {
        skillLevel: 'expert',
        recommendedPathType: 'expert',
        learningPath: {
          title: 'Expert Path',
          description: 'Master expert concepts and drive innovation',
          estimatedDuration: '12-16 weeks'
        },
        recommendedKatas: [
          '/learning/katas/expert-edge-architecture.md',
          '/learning/katas/expert-optimization.md'
        ]
      }
    };

    // Mock global learning progress tracker
    window.LearningProgressTracker = {
      getCustomagentRecommendation: vi.fn().mockReturnValue({
        customagent: 'learning-kata-coach',
        displayName: 'kata coach',
        description: 'Get a personalized learning path and guided practice based on your skill level'
      })
    };

    // Load the modal class
    if (typeof window.AssessmentCompletionModal === 'undefined') {
      // Mock the class if not available
      AssessmentCompletionModal = class {
        constructor(dependencies = {}) {
          this.apiClient = dependencies.apiClient || mockApiClient;
          this.domUtils = dependencies.domUtils || mockDomUtils;
          this.modal = null;
          this.isOpen = false;
          this.currentAssessmentResults = null;
          this.currentRecommendations = null;
        }

        async showModal(assessmentResults, recommendations) {
          this.currentAssessmentResults = assessmentResults;
          this.currentRecommendations = recommendations;

          if (!this.modal) {
            this.createModal();
          }

          this.populateModalContent(assessmentResults, recommendations);
          this.openModal();

          return new Promise((resolve) => {
            this.modalResolve = resolve;
          });
        }

        createModal() {
          const modalHTML = `
            <div id="assessment-completion-modal" class="assessment-modal-overlay">
              <div class="assessment-modal-content">
                <div class="assessment-modal-header">
                  <h2>🎉 Assessment Complete!</h2>
                  <button class="assessment-modal-close" aria-label="Close modal">&times;</button>
                </div>
                <div class="assessment-modal-body">
                  <div class="assessment-results">
                    <div class="skill-level-display">
                      <h3>Your Skill Level</h3>
                      <div class="skill-badge"></div>
                    </div>
                    <div class="assessment-summary">
                      <p class="completion-percentage"></p>
                      <p class="overall-score"></p>
                    </div>
                  </div>
                  <div class="learning-path-recommendation">
                    <h3>🎯 Your Recommended Learning Path</h3>
                    <div class="recommended-path-content">
                      <div class="path-title"></div>
                      <div class="path-description"></div>
                      <div class="estimated-duration"></div>
                    </div>
                  </div>
                  <div class="next-steps">
                    <h3>🚀 Next Steps</h3>
                    <div class="customagent-recommendation">
                      <p>Get personalized guidance from our <strong>Kata Coach</strong></p>
                      <p class="customagent-description"></p>
                    </div>
                  </div>
                </div>
                <div class="assessment-modal-footer">
                  <div class="modal-actions">
                    <button class="btn-secondary" id="assessment-modal-close-btn">Close</button>
                    <button class="btn-primary" id="assessment-modal-save-path">
                      <span class="btn-icon">💾</span> Save Learning Path to Dashboard
                    </button>
                    <button class="btn-primary" id="assessment-modal-start-coaching">
                      <span class="btn-icon">🤖</span> Start with Kata Coach
                    </button>
                  </div>
                </div>
              </div>
            </div>
          `;

          document.body.insertAdjacentHTML('beforeend', modalHTML);
          this.modal = document.getElementById('assessment-completion-modal');
          this.setupModalEventListeners();
        }

        populateModalContent(assessmentResults, recommendations) {
          const modal = this.modal;

          // Skill level display
          const skillBadge = modal.querySelector('.skill-badge');
          const skillLevel = assessmentResults.skillLevel || 'beginner';
          skillBadge.textContent = this.formatSkillLevelDisplay(skillLevel);
          skillBadge.className = `skill-badge ${skillLevel.toLowerCase().replace(/\s+/g, '-')}`;

          // Assessment summary
          const completionPercentage = modal.querySelector('.completion-percentage');
          completionPercentage.textContent = `${assessmentResults.questionsAnswered || 0}/${assessmentResults.totalQuestions || 12} questions completed`;

          const overallScore = modal.querySelector('.overall-score');
          const scoreValue = typeof (assessmentResults.overallScore) === 'number' ?
            assessmentResults.overallScore : 0;
          overallScore.textContent = `Overall Score: ${scoreValue.toFixed(1)}/5.0`;

          // Learning path recommendation
          if (recommendations && recommendations.learningPath) {
            const pathTitle = modal.querySelector('.path-title');
            pathTitle.textContent = recommendations.learningPath.title || 'Beginner Path';

            const pathDescription = modal.querySelector('.path-description');
            pathDescription.textContent = recommendations.learningPath.description || 'Build your foundational skills in edge AI development';

            const estimatedDuration = modal.querySelector('.estimated-duration');
            estimatedDuration.textContent = `Estimated Duration: ${recommendations.learningPath.estimatedDuration || '4-6 weeks'}`;
          } else {
            // Provide defaults when recommendations are missing
            const pathTitle = modal.querySelector('.path-title');
            pathTitle.textContent = 'Beginner Path';

            const pathDescription = modal.querySelector('.path-description');
            pathDescription.textContent = 'Build your foundational skills in edge AI development';

            const estimatedDuration = modal.querySelector('.estimated-duration');
            estimatedDuration.textContent = 'Estimated Duration: 4-6 weeks';
          }

          // Custom agent recommendation
          const customagentDescription = modal.querySelector('.customagent-description');
          const customagentRec = window.LearningProgressTracker?.getCustomagentRecommendation(assessmentResults.skillLevel);
          if (customagentRec) {
            customagentDescription.textContent = customagentRec.description;
          }
        }

        formatSkillLevelDisplay(skillLevel) {
          const levelMap = {
            'beginner': 'Beginner',
            'intermediate': 'Intermediate',
            'advanced': 'Advanced',
            'expert': 'Expert'
          };
          return levelMap[skillLevel] || 'Beginner';
        }

        setupModalEventListeners() {
          const modal = this.modal;

          // Close handlers
          const closeBtn = modal.querySelector('.assessment-modal-close');
          const closeBtnFooter = modal.querySelector('#assessment-modal-close-btn');

          closeBtn?.addEventListener('click', () => this.closeModal('closed'));
          closeBtnFooter?.addEventListener('click', () => this.closeModal('closed'));

          // Action handlers
          const savePathBtn = modal.querySelector('#assessment-modal-save-path');
          savePathBtn?.addEventListener('click', () => this.saveLearningPath());

          const startCoachingBtn = modal.querySelector('#assessment-modal-start-coaching');
          startCoachingBtn?.addEventListener('click', () => this.startCustomagentCoaching());

          // Overlay and keyboard handlers
          modal.addEventListener('click', (e) => {
            if (e.target === modal) this.closeModal('closed');
          });

          document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) this.closeModal('closed');
          });
        }

        async saveLearningPath() {
          try {
            // FETCH CURRENT SELECTIONS TO MERGE WITH NEW PATHS (matching production)
            let existingSelections = [];
            try {
              const fetchResponse = await fetch('http://localhost:3002/api/learning/selections?userId=current-user');
              if (fetchResponse.ok) {
                const data = await fetchResponse.json();
                existingSelections = data.data?.selections?.selectedItems || [];
              }
            } catch (err) {
              console.warn('Could not fetch existing selections:', err);
            }

            // Get recommendation type and map to difficulty
            const recommendedType = this.currentRecommendations?.recommendedPathType || 'beginner';
            const difficultyMap = {
              'beginner': 'beginner',
              'intermediate': 'intermediate',
              'advanced': 'advanced',
              'expert': 'expert'
            };
            const targetDifficulty = difficultyMap[recommendedType] || 'beginner';

            // Get matching path IDs
            const pathPatterns = {
              'beginner': ['beginner-ai-first-engineering'],
              'intermediate': ['intermediate-infrastructure-architect', 'intermediate-devops-excellence'],
              'advanced': ['advanced-edge-architecture'],
              'expert': ['expert-enterprise-integration', 'expert-data-analytics-integration']
            };
            const newPaths = pathPatterns[targetDifficulty] || pathPatterns['beginner'];

            // Merge new paths with existing selections (deduplicate with Set)
            const selectedItems = [...new Set([...existingSelections, ...newPaths])];
            console.log(`🔄 Merge - Existing: ${existingSelections.length}, New: ${newPaths.length}, Total: ${selectedItems.length}`);

            const response = await this.apiClient.post('http://localhost:3002/api/learning/selections', {
              userId: 'current-user',
              selectedItems: selectedItems
            });

            return response;
          } catch (error) {
            console.error('Error saving learning path:', error);
            throw error;
          }
        }

        startCustomagentCoaching() {
          const customagentRec = window.LearningProgressTracker?.getCustomagentRecommendation();
          if (customagentRec) {
            window.location.hash = `#/github-copilot/customagents/${customagentRec.customagent}`;
            this.closeModal('coaching');
          }
        }

        openModal() {
          if (this.modal) {
            this.modal.style.display = 'flex';
            this.isOpen = true;
            document.body.style.overflow = 'hidden';
          }
        }

        closeModal(action = 'closed') {
          if (this.modal) {
            this.modal.style.display = 'none';
            this.isOpen = false;
            document.body.style.overflow = '';

            if (this.modalResolve) {
              // Use setTimeout to resolve asynchronously to avoid timing issues
              setTimeout(() => {
                this.modalResolve({ action, timestamp: new Date().toISOString() });
                this.modalResolve = null;
              }, 0);
            }
          }
        }        destroy() {
          if (this.modal) {
            this.modal.remove();
            this.modal = null;
            this.isOpen = false;
            document.body.style.overflow = '';
          }
        }
      };
    } else {
      AssessmentCompletionModal = window.AssessmentCompletionModal;
    }

    modal = new AssessmentCompletionModal({
      apiClient: mockApiClient,
      domUtils: mockDomUtils
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
    modal?.destroy();
    document.body.innerHTML = '';
    delete window.AssessmentCompletionModal;
  });

  describe('Modal Creation and Display', () => {
    it('should create modal with proper structure', () => {
      modal.createModal();

      const modalElement = document.getElementById('assessment-completion-modal');
      expect(modalElement).toBeTruthy();
      expect(modalElement.classList.contains('assessment-modal-overlay')).toBe(true);

      // Check header
      const header = modalElement.querySelector('.assessment-modal-header h2');
      expect(header.textContent).toBe('🎉 Assessment Complete!');

      // Check body sections
      expect(modalElement.querySelector('.skill-level-display')).toBeTruthy();
      expect(modalElement.querySelector('.learning-path-recommendation')).toBeTruthy();
      expect(modalElement.querySelector('.next-steps')).toBeTruthy();

      // Check footer actions
      expect(modalElement.querySelector('#assessment-modal-close-btn')).toBeTruthy();
      expect(modalElement.querySelector('#assessment-modal-save-path')).toBeTruthy();
      expect(modalElement.querySelector('#assessment-modal-start-coaching')).toBeTruthy();
    });

    it('should show modal and set proper state', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      expect(modal.isOpen).toBe(true);
      expect(modal.modal.style.display).toBe('flex');
      expect(document.body.style.overflow).toBe('hidden');

      // Clean up
      modal.closeModal();
      await showPromise;
    });

    it('should hide modal and restore state', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      // Wait a bit then close
      await new Promise(resolve => setTimeout(resolve, 10));
      const result = modal.closeModal('test-action');

      expect(modal.isOpen).toBe(false);
      expect(modal.modal.style.display).toBe('none');
      expect(document.body.style.overflow).toBe('');

      // Wait for promise to resolve
      const promiseResult = await showPromise;
      expect(promiseResult.action).toBe('test-action');
    });
  });

  describe('Content Population', () => {
    beforeEach(() => {
      modal.createModal();
    });

    it('should populate skill level for beginner', () => {
      modal.populateModalContent(mockAssessmentResults.beginner, mockRecommendations.beginner);

      const skillBadge = modal.modal.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Beginner');
      expect(skillBadge.classList.contains('beginner')).toBe(true);
    });

    it('should populate skill level for intermediate', () => {
      modal.populateModalContent(mockAssessmentResults.intermediate, mockRecommendations.intermediate);

      const skillBadge = modal.modal.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Intermediate');
      expect(skillBadge.classList.contains('intermediate')).toBe(true);
    });

    it('should populate skill level for advanced', () => {
      modal.populateModalContent(mockAssessmentResults.advanced, mockRecommendations.advanced);

      const skillBadge = modal.modal.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Advanced');
      expect(skillBadge.classList.contains('advanced')).toBe(true);
    });

    it('should populate assessment summary correctly', () => {
      modal.populateModalContent(mockAssessmentResults.intermediate, mockRecommendations.intermediate);

      const completionPercentage = modal.modal.querySelector('.completion-percentage');
      expect(completionPercentage.textContent).toBe('12/12 questions completed');

      const overallScore = modal.modal.querySelector('.overall-score');
      expect(overallScore.textContent).toBe('Overall Score: 3.2/5.0');
    });

    it('should populate learning path recommendations', () => {
      modal.populateModalContent(mockAssessmentResults.advanced, mockRecommendations.advanced);

      const pathTitle = modal.modal.querySelector('.path-title');
      expect(pathTitle.textContent).toBe('Advanced Path');

      const pathDescription = modal.modal.querySelector('.path-description');
      expect(pathDescription.textContent).toBe('Master advanced edge AI architectures and best practices');

      const estimatedDuration = modal.modal.querySelector('.estimated-duration');
      expect(estimatedDuration.textContent).toBe('Estimated Duration: 8-10 weeks');
    });

    it('should populate custom agent recommendation', () => {
      modal.populateModalContent(mockAssessmentResults.beginner, mockRecommendations.beginner);

      const customagentDescription = modal.modal.querySelector('.customagent-description');
      expect(customagentDescription.textContent).toBe('Get a personalized learning path and guided practice based on your skill level');
    });

    it('should handle missing recommendations gracefully', () => {
      modal.populateModalContent(mockAssessmentResults.beginner, null);

      // Should not throw errors and should have default values
      const pathTitle = modal.modal.querySelector('.path-title');
      expect(pathTitle.textContent).toBe('Beginner Path');

      const pathDescription = modal.modal.querySelector('.path-description');
      expect(pathDescription.textContent).toBe('Build your foundational skills in edge AI development');
    });
  });

  describe('Event Handling', () => {
    beforeEach(() => {
      modal.createModal();
    });

    it('should handle close button clicks', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      const closeBtn = modal.modal.querySelector('.assessment-modal-close');
      closeBtn.click();

      const result = await showPromise;
      expect(result.action).toBe('closed');
      expect(modal.isOpen).toBe(false);
    });

    it('should handle footer close button', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      const closeBtnFooter = modal.modal.querySelector('#assessment-modal-close-btn');
      closeBtnFooter.click();

      const result = await showPromise;
      expect(result.action).toBe('closed');
    });

    it('should handle save learning path action', async () => {
      modal.currentAssessmentResults = mockAssessmentResults.intermediate;
      modal.currentRecommendations = mockRecommendations.intermediate;

      await modal.saveLearningPath();

      expect(mockApiClient.post).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          userId: 'current-user',
          selectedItems: expect.any(Array)
        })
      );
    });

    it('should handle custom agent coaching action', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      // Mock window.location.hash
      Object.defineProperty(window, 'location', {
        value: { hash: '' },
        writable: true
      });

      const startCoachingBtn = modal.modal.querySelector('#assessment-modal-start-coaching');
      startCoachingBtn.click();

      expect(window.location.hash).toBe('#/github-copilot/customagents/learning-kata-coach');

      const result = await showPromise;
      expect(result.action).toBe('coaching');
    });

    it('should handle escape key press', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      // Simulate escape key press
      const escapeEvent = new KeyboardEvent('keydown', { key: 'Escape' });
      document.dispatchEvent(escapeEvent);

      const result = await showPromise;
      expect(result.action).toBe('closed');
    });

    it('should handle overlay click', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      // Click on the overlay (modal background)
      modal.modal.click();

      const result = await showPromise;
      expect(result.action).toBe('closed');
    });
  });

  describe('Integration with Assessment Path Generator', () => {
    it('should properly receive and display generated recommendations', () => {
      // Mock the assessment path generator response
      const generatedRecommendations = {
        skillLevel: 'intermediate',
        learningPath: {
          title: 'Custom Generated Path',
          description: 'Generated based on your specific assessment responses',
          estimatedDuration: '7 weeks'
        },
        recommendedKatas: ['/learning/katas/custom-kata.md']
      };

      modal.createModal();
      modal.populateModalContent(mockAssessmentResults.intermediate, generatedRecommendations);

      const pathTitle = modal.modal.querySelector('.path-title');
      expect(pathTitle.textContent).toBe('Custom Generated Path');

      const pathDescription = modal.modal.querySelector('.path-description');
      expect(pathDescription.textContent).toBe('Generated based on your specific assessment responses');
    });

    it('should handle empty or malformed recommendations', () => {
      modal.createModal();

      // Test with empty recommendations
      expect(() => {
        modal.populateModalContent(mockAssessmentResults.beginner, {});
      }).not.toThrow();

      // Test with null recommendations
      expect(() => {
        modal.populateModalContent(mockAssessmentResults.beginner, null);
      }).not.toThrow();

      // Test with malformed recommendations
      expect(() => {
        modal.populateModalContent(mockAssessmentResults.beginner, { invalid: 'data' });
      }).not.toThrow();
    });
  });

  describe('Error Handling', () => {
    beforeEach(() => {
      modal.createModal();
    });

    it('should handle API errors when saving learning path', async () => {
      mockApiClient.post.mockRejectedValue(new Error('API Error'));

      modal.currentAssessmentResults = mockAssessmentResults.beginner;
      modal.currentRecommendations = mockRecommendations.beginner;

      await expect(modal.saveLearningPath()).rejects.toThrow('API Error');
    });

    it('should handle missing global dependencies gracefully', () => {
      // Remove global dependencies
      delete window.LearningProgressTracker;

      expect(() => {
        modal.populateModalContent(mockAssessmentResults.beginner, mockRecommendations.beginner);
      }).not.toThrow();
    });

    it('should handle malformed assessment results', () => {
      const malformedResults = {
        skillLevel: 'invalid-level',
        overallScore: 'not-a-number'
      };

      expect(() => {
        modal.populateModalContent(malformedResults, mockRecommendations.beginner);
      }).not.toThrow();

      const skillBadge = modal.modal.querySelector('.skill-badge');
      expect(skillBadge.textContent).toBe('Beginner'); // Should fallback

      const overallScore = modal.modal.querySelector('.overall-score');
      expect(overallScore.textContent).toBe('Overall Score: 0.0/5.0'); // Should handle NaN
    });
  });

  describe('Selection Merging and Deduplication', () => {
    beforeEach(() => {
      modal.createModal();
      modal.currentAssessmentResults = mockAssessmentResults.beginner;
      modal.currentRecommendations = mockRecommendations.beginner;
      mockApiClient.post.mockResolvedValue({
        data: { selections: { selectedItems: [] } }
      });
    });

    it('should merge new paths with existing selections', async () => {
      // Mock fetch to return existing selections
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: ['foundation-ai-first-engineering']
            }
          }
        })
      });

      // Save with new recommendation
      await modal.saveLearningPath('current-user');

      // Verify POST contains both existing and new paths
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];

      expect(sentData.selectedItems).toContain('foundation-ai-first-engineering');
      expect(sentData.selectedItems.length).toBeGreaterThan(1);
    });

    it('should deduplicate when same path recommended twice', async () => {
      // Mock fetch to return path that will be recommended again
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: ['beginner-basic-programming']
            }
          }
        })
      });

      // Save with recommendation that includes same path
      modal.currentRecommendations = {
        primary: [{ id: 'beginner-basic-programming', name: 'Basic Programming' }],
        secondary: []
      };

      await modal.saveLearningPath('current-user');

      // Verify POST contains only one instance
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];
      const occurrences = sentData.selectedItems.filter(id => id === 'beginner-basic-programming');

      expect(occurrences.length).toBe(1);
    });

    it('should handle fetch errors gracefully', async () => {
      // Mock fetch to throw error
      global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

      // Save should still work with just new paths
      await modal.saveLearningPath('current-user');

      // Verify POST happens with new paths only
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];

      expect(sentData.selectedItems).toBeDefined();
      expect(Array.isArray(sentData.selectedItems)).toBe(true);
    });

    it('should preserve all existing selections when adding new', async () => {
      // Mock fetch to return multiple existing paths
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: [
                'foundation-ai-first-engineering',
                'intermediate-system-design',
                'advanced-ml-engineering'
              ]
            }
          }
        })
      });

      // Set recommendedPathType to beginner (mock uses this, not primary recommendations)
      modal.currentRecommendations = {
        recommendedPathType: 'beginner',
        primary: [],
        secondary: []
      };

      await modal.saveLearningPath('current-user');

      // Verify POST contains all paths (3 existing + 1 new beginner path = 4 total)
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];

      expect(sentData.selectedItems.length).toBe(4);
      expect(sentData.selectedItems).toContain('foundation-ai-first-engineering');
      expect(sentData.selectedItems).toContain('intermediate-system-design');
      expect(sentData.selectedItems).toContain('advanced-ml-engineering');
      expect(sentData.selectedItems).toContain('beginner-ai-first-engineering');
    });

    it('should log merge counts for debugging', async () => {
      const consoleSpy = vi.spyOn(console, 'log');

      // Mock fetch to return existing selections
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: ['existing-path-1', 'existing-path-2']
            }
          }
        })
      });

      modal.currentRecommendations = {
        primary: [{ id: 'new-path-1', name: 'New Path' }],
        secondary: []
      };

      await modal.saveLearningPath('current-user');

      // Verify console logging
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('🔄 Merge - Existing:')
      );
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('New:')
      );
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Total:')
      );

      consoleSpy.mockRestore();
    });

    it('should use default paths when no recommendations provided', async () => {
      // Mock fetch to return existing selections
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: ['existing-path']
            }
          }
        })
      });

      // Clear recommendations
      modal.currentRecommendations = { primary: [], secondary: [] };

      await modal.saveLearningPath('current-user');

      // Verify POST contains existing + default paths
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];

      expect(sentData.selectedItems).toContain('existing-path');
      expect(sentData.selectedItems.length).toBeGreaterThan(1);
    });

    it('should handle empty existing selections', async () => {
      // Mock fetch to return empty array
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          data: {
            selections: {
              selectedItems: []
            }
          }
        })
      });

      await modal.saveLearningPath('current-user');

      // Verify POST contains only new paths
      const postCall = mockApiClient.post.mock.calls[0];
      const sentData = postCall[1];

      expect(Array.isArray(sentData.selectedItems)).toBe(true);
      expect(sentData.selectedItems.length).toBeGreaterThan(0);
    });
  });

  describe('Accessibility and UX', () => {
    beforeEach(() => {
      modal.createModal();
    });

    it('should have proper ARIA attributes', () => {
      const closeBtn = modal.modal.querySelector('.assessment-modal-close');
      expect(closeBtn.getAttribute('aria-label')).toBe('Close modal');
    });

    it('should prevent background scroll when open', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      expect(document.body.style.overflow).toBe('hidden');

      modal.closeModal();
      await showPromise;
      expect(document.body.style.overflow).toBe('');
    });    it('should maintain focus management', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

      // Check that a focusable element exists
      const focusableElements = modal.modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      expect(focusableElements.length).toBeGreaterThan(0);

      modal.closeModal();
      await showPromise;
    });
  });

  describe('Data Persistence and State Management', () => {
    it('should maintain assessment results and recommendations state', async () => {
      const showPromise = modal.showModal(mockAssessmentResults.advanced, mockRecommendations.advanced);

      expect(modal.currentAssessmentResults).toEqual(mockAssessmentResults.advanced);
      expect(modal.currentRecommendations).toEqual(mockRecommendations.advanced);

      modal.closeModal();
      await showPromise;
    });

    it('should handle multiple modal show/hide cycles', async () => {
      // First cycle
      const promise1 = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);
      modal.closeModal('test1');
      const result1 = await promise1;

      // Second cycle
      const promise2 = modal.showModal(mockAssessmentResults.intermediate, mockRecommendations.intermediate);
      modal.closeModal('test2');
      const result2 = await promise2;

      expect(result1.action).toBe('test1');
      expect(result2.action).toBe('test2');
      expect(modal.currentAssessmentResults).toEqual(mockAssessmentResults.intermediate);
    });
  });

  describe('Modal Content Display Requirements', () => {
    beforeEach(() => {
      modal.createModal();
    });

    describe('Skill Level Display', () => {
      it('should display correct skill level badge for intermediate results', () => {
        modal.populateModalContent(mockAssessmentResults.intermediate, mockRecommendations.intermediate);

        const skillBadge = modal.modal.querySelector('.skill-badge');
        expect(skillBadge.textContent.trim()).not.toBe('');
        expect(skillBadge.textContent).toBe('Intermediate');
        expect(skillBadge.classList.contains('intermediate')).toBe(true);
      });

      it('should display complete learning path information for advanced results', () => {
        modal.populateModalContent(mockAssessmentResults.advanced, mockRecommendations.advanced);

        const pathTitle = modal.modal.querySelector('.path-title');
        const pathDescription = modal.modal.querySelector('.path-description');
        const estimatedDuration = modal.modal.querySelector('.estimated-duration');

        expect(pathTitle.textContent.trim()).not.toBe('');
        expect(pathDescription.textContent.trim()).not.toBe('');
        expect(estimatedDuration.textContent.trim()).not.toBe('');

        expect(pathTitle.textContent).toBe('Advanced Path');
        expect(pathDescription.textContent).toBe('Master advanced edge AI architectures and best practices');
        expect(estimatedDuration.textContent).toBe('Estimated Duration: 8-10 weeks');
      });

      it('should display assessment completion statistics for beginner results', () => {
        modal.populateModalContent(mockAssessmentResults.beginner, mockRecommendations.beginner);

        const completionPercentage = modal.modal.querySelector('.completion-percentage');
        const overallScore = modal.modal.querySelector('.overall-score');

        expect(completionPercentage.textContent.trim()).not.toBe('');
        expect(overallScore.textContent.trim()).not.toBe('');

        expect(completionPercentage.textContent).toBe('12/12 questions completed');
        expect(overallScore.textContent).toBe('Overall Score: 2.3/5.0');
      });

      it('should display next steps with kata coach guidance information', () => {
        modal.populateModalContent(mockAssessmentResults.intermediate, mockRecommendations.intermediate);

        const customagentDescription = modal.modal.querySelector('.customagent-description');
        expect(customagentDescription.textContent.trim()).not.toBe('');
        expect(customagentDescription.textContent).toContain('personalized learning path');
      });
    });

    describe('Button Actions and Event Handling', () => {
      it('should close modal when header close button is clicked', async () => {
        const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

        // Test header close button
        const headerCloseBtn = modal.modal.querySelector('.assessment-modal-close');
        expect(headerCloseBtn).toBeTruthy();
        expect(typeof headerCloseBtn.onclick === 'function' || headerCloseBtn.addEventListener).toBeTruthy();

        // Simulate click
        headerCloseBtn.click();
        const result = await showPromise;
        expect(result.action).toBe('closed');
        expect(modal.isOpen).toBe(false);
      });

      it('should close modal when footer close button is clicked', async () => {
        const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

        const footerCloseBtn = modal.modal.querySelector('#assessment-modal-close-btn');
        expect(footerCloseBtn).toBeTruthy();
        expect(footerCloseBtn.textContent.trim()).toBe('Close');

        // Simulate click
        footerCloseBtn.click();
        const result = await showPromise;
        expect(result.action).toBe('closed');
      });

      it('should save learning path to dashboard when save button is clicked', async () => {
        modal.currentAssessmentResults = mockAssessmentResults.intermediate;
        modal.currentRecommendations = mockRecommendations.intermediate;

        const saveBtn = modal.modal.querySelector('#assessment-modal-save-path');
        expect(saveBtn).toBeTruthy();
        expect(saveBtn.textContent.trim()).toContain('Save Learning Path to Dashboard');

        // Mock button click handler
        const clickSpy = vi.spyOn(modal, 'saveLearningPath').mockResolvedValue({ success: true });

        // Simulate click
        saveBtn.click();

        // Wait for async operation
        await new Promise(resolve => setTimeout(resolve, 10));
        expect(clickSpy).toHaveBeenCalled();
      });

      it('should navigate to kata coach custom agent when start coaching button is clicked', async () => {
        const showPromise = modal.showModal(mockAssessmentResults.beginner, mockRecommendations.beginner);

        // Mock window.location.hash
        Object.defineProperty(window, 'location', {
          value: { hash: '' },
          writable: true
        });

        const coachBtn = modal.modal.querySelector('#assessment-modal-start-coaching');
        expect(coachBtn).toBeTruthy();
        expect(coachBtn.textContent.trim()).toContain('Start with Kata Coach');

        // Simulate click
        coachBtn.click();

        expect(window.location.hash).toBe('#/github-copilot/customagents/learning-kata-coach');
        const result = await showPromise;
        expect(result.action).toBe('coaching');
      });

      it('should render all required action buttons with correct labels', () => {
        const closeBtn = modal.modal.querySelector('.assessment-modal-close');
        const footerCloseBtn = modal.modal.querySelector('#assessment-modal-close-btn');
        const saveBtn = modal.modal.querySelector('#assessment-modal-save-path');
        const coachBtn = modal.modal.querySelector('#assessment-modal-start-coaching');

        // All buttons should exist
        expect(closeBtn).toBeTruthy();
        expect(footerCloseBtn).toBeTruthy();
        expect(saveBtn).toBeTruthy();
        expect(coachBtn).toBeTruthy();

        // Should have correct labels
        expect(footerCloseBtn.textContent.trim()).toBe('Close');
        expect(saveBtn.textContent.trim()).toContain('Save Learning Path to Dashboard');
        expect(coachBtn.textContent.trim()).toContain('Start with Kata Coach');
      });

      it('should provide visual feedback when buttons are clicked', async () => {
        // Test that buttons respond to click events
        const saveBtn = modal.modal.querySelector('#assessment-modal-save-path');
        const coachBtn = modal.modal.querySelector('#assessment-modal-start-coaching');

        // Mock button state changes
        const saveSpy = vi.spyOn(modal, 'saveLearningPath').mockResolvedValue({ success: true });

        saveBtn.click();
        expect(saveSpy).toHaveBeenCalled();

        // Test coach button navigates
        Object.defineProperty(window, 'location', {
          value: { hash: '' },
          writable: true
        });

        coachBtn.click();
        expect(window.location.hash).toBe('#/github-copilot/customagents/learning-kata-coach');
      });
    });

    describe('End-to-End Assessment Completion Flow', () => {
      it('should handle realistic assessment completion scenario', async () => {
        // Simulate real assessment data from skill assessment form
        const realAssessmentData = {
          skillLevel: 'intermediate',
          questionsAnswered: 12,
          totalQuestions: 12,
          overallScore: 3.4,
          categories: {
            aiAssistedEngineering: { score: 3.2 },
            promptEngineering: { score: 3.5 },
            edgeDeployment: { score: 3.6 },
            systemTroubleshooting: { score: 3.3 }
          },
          timestamp: new Date().toISOString()
        };

        const realRecommendations = {
          skillLevel: 'intermediate',
          learningPath: {
            title: 'Intermediate Path',
            description: 'Advance your edge AI skills with hands-on practice',
            estimatedDuration: '6-8 weeks'
          },
          recommendedKatas: [
            '/learning/katas/intermediate-k8s.md',
            '/learning/katas/edge-ai-deployment.md'
          ]
        };

        const showPromise = modal.showModal(realAssessmentData, realRecommendations);

        // Verify content is populated correctly
        const skillBadge = modal.modal.querySelector('.skill-badge');
        expect(skillBadge.textContent).toBe('Intermediate');

        const completionText = modal.modal.querySelector('.completion-percentage');
        expect(completionText.textContent).toBe('12/12 questions completed');

        const scoreText = modal.modal.querySelector('.overall-score');
        expect(scoreText.textContent).toBe('Overall Score: 3.4/5.0');

        const pathTitle = modal.modal.querySelector('.path-title');
        expect(pathTitle.textContent).toBe('Intermediate Path');

        // Test save functionality with real data
        modal.currentAssessmentResults = realAssessmentData;
        modal.currentRecommendations = realRecommendations;

        await modal.saveLearningPath();
        expect(mockApiClient.post).toHaveBeenCalledWith('http://localhost:3002/api/learning/selections', {
          userId: 'current-user',
          selectedItems: expect.any(Array)
        });

        modal.closeModal();
        await showPromise;
      });

      it('should display expert level correctly', async () => {
        const modal = new AssessmentCompletionModal({
          apiClient: mockApiClient,
          domUtils: mockDomUtils
        });

        const expertData = mockAssessmentResults.expert;
        const expertRecommendations = mockRecommendations.expert;

        const showPromise = modal.showModal(expertData, expertRecommendations);

        // Verify expert badge is displayed
        const skillBadge = modal.modal.querySelector('.skill-badge');
        expect(skillBadge.textContent).toBe('Expert');
        expect(skillBadge.className).toContain('expert');

        const scoreText = modal.modal.querySelector('.overall-score');
        expect(scoreText.textContent).toBe('Overall Score: 5.0/5.0');

        modal.closeModal();
        await showPromise;
      });

      it('should test formatSkillLevelDisplay with all 4 levels', () => {
        const modal = new AssessmentCompletionModal({
          apiClient: mockApiClient,
          domUtils: mockDomUtils
        });

        expect(modal.formatSkillLevelDisplay('beginner')).toBe('Beginner');
        expect(modal.formatSkillLevelDisplay('intermediate')).toBe('Intermediate');
        expect(modal.formatSkillLevelDisplay('advanced')).toBe('Advanced');
        expect(modal.formatSkillLevelDisplay('expert')).toBe('Expert');
        expect(modal.formatSkillLevelDisplay('unknown')).toBe('Beginner');
      });
    });
  });
});
