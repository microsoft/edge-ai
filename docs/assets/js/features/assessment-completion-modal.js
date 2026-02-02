/**
 * Assessment Completion Modal
 * Displays personalized results and allows users to save learning path to dashboard
 */

import { LEARNING_PATH_CONSTANTS } from '../core/learning-path-constants.js';
const { DIFFICULTY } = LEARNING_PATH_CONSTANTS;

class AssessmentCompletionModal {
    constructor(dependencies = {}) {
        this.apiClient = dependencies.apiClient || this.createDefaultApiClient();
        this.domUtils = dependencies.domUtils || this.createDefaultDomUtils();
        this.modal = null;
        this.isOpen = false;
    }

    /**
     * Shows the completion modal with assessment results
     * @param {Object} assessmentResults - Results from skill assessment
     * @param {Object} recommendations - Learning path recommendations
     */
    async showModal(assessmentResults, recommendations) {
        try {
            // Store current results for button actions
            this.currentAssessmentResults = assessmentResults;
            this.currentRecommendations = recommendations;

            // Create modal if it doesn't exist
            if (!this.modal) {
                this.createModal();
            }

            // Populate modal content
            this.populateModalContent(assessmentResults, recommendations);

            // Show modal
            this.openModal();

            // Return promise that resolves when user makes a choice
            return new Promise((resolve) => {
                this.modalResolve = resolve;
            });
        } catch (error) {
            console.error('Error showing completion modal:', error);
            throw error;
        }
    }

    /**
     * Creates the modal DOM structure
     */
    createModal() {
        const modalHTML = `
            <div id="assessment-completion-modal" class="assessment-modal-overlay">
                <div class="assessment-modal-content">
                    <div class="assessment-modal-header">
                        <h2>🎉 Assessment Complete!</h2>
                        <button class="assessment-modal-close" id="assessment-modal-close-x" aria-label="Close modal">
                            ✕
                        </button>
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
                            <button class="btn-primary" id="assessment-modal-save-path">
                                <span class="btn-icon">💾</span>
                                Save Learning Path to Dashboard
                            </button>
                            <button class="btn-primary" id="assessment-modal-start-coaching">
                                <span class="btn-icon">🤖</span>
                                Start with Kata Coach
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Insert modal into DOM
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        this.modal = document.getElementById('assessment-completion-modal');

        // Add event listeners
        this.setupModalEventListeners();

        // Add CSS styles
        this.addModalStyles();
    }

    /**
     * Populates modal with assessment results and recommendations
     */
    populateModalContent(assessmentResults, recommendations) {
        const modal = this.modal;

        // Handle null assessmentResults gracefully
        if (!assessmentResults) {
            console.warn('Assessment results not available, using defaults');
            assessmentResults = {
                skillLevel: LEARNING_PATH_CONSTANTS.SKILL_LEVELS.BEGINNER,
                category: 'Foundation',
                score: 0,
                totalQuestions: 0
            };
        }

        // Skill level display
        const skillBadge = modal.querySelector('.skill-badge');

        // Get skill level from recommendations (use recommended path type directly)
        let skillLevel = recommendations?.recommendedPathType ||
                        recommendations?.recommendedPath ||
                        assessmentResults?.overallLevel ||
                        assessmentResults?.results?.overallLevel ||
                        LEARNING_PATH_CONSTANTS.SKILL_LEVELS.BEGINNER;

        skillBadge.textContent = this.formatSkillLevelDisplay(skillLevel);
        skillBadge.className = `skill-badge ${skillLevel.toLowerCase().replace(/\s+/g, '-')}`;

        // Assessment summary
        const completionPercentage = modal.querySelector('.completion-percentage');
        // Use questionsAnswered as both values since that's the actual count of questions with responses
        const answeredCount = assessmentResults.questionsAnswered || 0;
        completionPercentage.textContent = `${answeredCount}/${answeredCount} questions completed`;

        const overallScore = modal.querySelector('.overall-score');
        const scoreValue = typeof assessmentResults.overallScore === 'number' ? assessmentResults.overallScore : 0;
        overallScore.textContent = `Overall Score: ${scoreValue.toFixed(1)}/5.0`;

        // Learning path recommendation
        if (recommendations && (recommendations.recommendedPathType || recommendations.recommendedPath)) {
            // Map path type to display text
            const pathTypeMap = {
                'beginner': {
                    title: 'Foundation Builder',
                    description: 'Build core skills across essential areas'
                },
                'intermediate': {
                    title: 'Skill Developer',
                    description: 'Enhance intermediate skills and learn advanced techniques'
                },
                'advanced': {
                    title: 'Advanced Practitioner',
                    description: 'Apply advanced techniques and lead technical initiatives'
                },
                'expert': {
                    title: 'Expert Practitioner',
                    description: 'Master expert concepts and drive innovation'
                }
            };

            const pathInfo = pathTypeMap[skillLevel] || pathTypeMap['beginner'];

            const pathTitle = modal.querySelector('.path-title');
            pathTitle.textContent = pathInfo.title;

            const pathDescription = modal.querySelector('.path-description');
            pathDescription.textContent = recommendations.personalizedMessage || pathInfo.description;

            const estimatedDuration = modal.querySelector('.estimated-duration');
            if (recommendations.estimatedDuration) {
                const { hours, weeks } = recommendations.estimatedDuration;
                estimatedDuration.textContent = `Estimated Duration: ${hours} hours (${weeks} weeks)`;
            } else {
                estimatedDuration.textContent = 'Estimated Duration: 4-6 weeks';
            }
        } else {
            // Provide defaults when recommendations are missing
            const pathTitle = modal.querySelector('.path-title');
            pathTitle.textContent = 'Foundation Path';

            const pathDescription = modal.querySelector('.path-description');
            pathDescription.textContent = 'Build your foundational skills in edge AI development';

            const estimatedDuration = modal.querySelector('.estimated-duration');
            estimatedDuration.textContent = 'Estimated Duration: 4-6 weeks';
        }

        // Custom agent recommendation
        const customagentDescription = modal.querySelector('.customagent-description');

        // Use recommendations data if available
        if (recommendations && recommendations.suggestedItems && recommendations.suggestedItems.length > 0) {
            // Show first 3 suggested items
            const topSuggestions = recommendations.suggestedItems.slice(0, 3);
            const suggestionsText = topSuggestions.map(item =>
                `• ${item.title} (${item.difficulty}, ~${item.estimatedTime} min)`
            ).join('\n');

            customagentDescription.textContent = `Here are your top recommended learning activities:\n\n${suggestionsText}\n\nOur Kata Coach can guide you through these items step-by-step.`;
        } else {
            // Fallback to generic custom agent recommendation
            const skillLevel = assessmentResults?.skillLevel || DIFFICULTY.BEGINNER;
            const customagentRec = window.LearningProgressTracker?.getCustomagentRecommendation(skillLevel);
            if (customagentRec) {
                customagentDescription.textContent = customagentRec.description;
            } else {
                customagentDescription.textContent = 'Our AI-powered Kata Coach will provide personalized guidance based on your assessment results.';
            }
        }
    }

    /**
     * Formats skill level for display
     */
  formatSkillLevelDisplay(skillLevel) {
    const levelMap = {
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
      'expert': 'Expert'
    };
    return levelMap[skillLevel] || 'Beginner';
  }    /**
     * Sets up modal event listeners
     */
    async setupModalEventListeners() {
      const modal = this.modal;

      // Close handlers - X button in header
      const closeBtnX = modal.querySelector('#assessment-modal-close-x');

      if (closeBtnX) {
        closeBtnX.addEventListener('click', () => this.closeModal());
      }

      // Action handlers
      const savePathBtn = modal.querySelector('#assessment-modal-save-path');
      if (savePathBtn) {
        savePathBtn.addEventListener('click', () => this.saveLearningPath());
      }

      const startCoachingBtn = modal.querySelector('#assessment-modal-start-coaching');
      if (startCoachingBtn) {
        startCoachingBtn.addEventListener('click', () => this.startCustomagentCoaching());
      }

      // Overlay and keyboard handlers
      modal.addEventListener('click', (e) => {
        if (e.target === modal) this.closeModal('closed');
      });

      const escapeHandler = (e) => {
        if (e.key === 'Escape' && this.isOpen) {
          this.closeModal('closed');
        }
      };

      document.addEventListener('keydown', escapeHandler);

      // Store handler for cleanup
      this.escapeHandler = escapeHandler;
    }    /**
     * Saves the recommended learning path to user's dashboard via API
     * Dashboard will load selections from server on page load
     */
    async saveLearningPath() {
        try {
            const saveBtn = this.modal.querySelector('#assessment-modal-save-path');

            // Show loading state
            saveBtn.innerHTML = '<span class="btn-icon">⏳</span> Saving...';
            saveBtn.disabled = true;

            // Get recommendation data
            const recommendedType = this.currentRecommendations?.recommendedPathType ||
                                   this.currentRecommendations?.recommendedPath ||
                                   this.currentAssessmentResults?.overallLevel ||
                                   this.currentAssessmentResults?.results?.overallLevel ||
                                   DIFFICULTY.BEGINNER;
            const targetDifficulty = recommendedType;

            console.log(`🎯 Saving recommended paths - Type: ${recommendedType}, Difficulty: ${targetDifficulty}`);

            // FETCH CURRENT SELECTIONS TO MERGE WITH NEW PATHS
            let existingSelections = [];
            try {
                const fetchResponse = await fetch('http://localhost:3002/api/learning/selections?userId=default-user');
                if (fetchResponse.ok) {
                    const data = await fetchResponse.json();
                    existingSelections = data.data?.selections?.selectedItems || [];
                    console.log(`📥 Fetched ${existingSelections.length} existing selection(s)`);
                }
            } catch (err) {
                console.warn('Could not fetch existing selections, will use empty array:', err);
            }

            // Get actual path IDs from recommendations or fallback to difficulty-based defaults
            let newPaths = [];

            // If recommendations include suggestedItems (path IDs), use those
            if (this.currentRecommendations?.suggestedItems?.length > 0) {
                newPaths = this.currentRecommendations.suggestedItems
                    .filter(item => item.type === 'path')
                    .map(item => item.id);
            }

            // Fallback to difficulty-based pattern if no specific recommendations
            if (newPaths.length === 0) {
                // Use path ID format from manifest (singular 'path-' not 'paths-')
                const pathDefaults = {
                    'foundation': ['path-foundation-ai-first-engineering'],
                    'intermediate': ['path-intermediate-infrastructure-architect'],
                    'expert': ['path-expert-enterprise-integration']
                };
                newPaths = pathDefaults[targetDifficulty] || pathDefaults['foundation'];
            }

            // Merge new paths with existing selections (deduplicate with Set)
            const selectedItems = [...new Set([...existingSelections, ...newPaths])];
            console.log(`🔄 Merge - Existing: ${existingSelections.length}, New: ${newPaths.length}, Total: ${selectedItems.length}`);

            // Save via API with correct property name
            const response = await this.apiClient.post('http://localhost:3002/api/learning/selections', {
                userId: 'default-user',
                selectedItems: selectedItems
            });

            if (response.success) {
                saveBtn.innerHTML = '<span class="btn-icon">✅</span> Saved to Dashboard!';
                saveBtn.className = 'btn-success';

                // Show success message
                this.showModalMessage(`${response.data.selectionCount} learning path(s) saved! Redirecting...`, 'success');

                console.log(`✅ Successfully saved ${response.data.selectionCount} path(s) to server`);

                // Navigate to dashboard to show the selections
                setTimeout(() => {
                    this.closeModal('saved');
                    window.location.hash = '#/learning/paths/';
                }, 1500);
            } else {
                throw new Error(response.error || 'Failed to save learning path selections');
            }

        } catch (error) {
            console.error('Error saving learning path:', error);

            const saveBtn = this.modal.querySelector('#assessment-modal-save-path');
            saveBtn.innerHTML = '<span class="btn-icon">❌</span> Save Failed';
            saveBtn.className = 'btn-error';

            this.showModalMessage('Failed to save to server. Please try again.', 'error');

            // Reset button after delay
            setTimeout(() => {
                saveBtn.innerHTML = '<span class="btn-icon">💾</span> Save Learning Path to Dashboard';
                saveBtn.className = 'btn-primary';
                saveBtn.disabled = false;
            }, 3000);
        }
    }

    /**
     * Starts custom agent coaching session
     */
    startCustomagentCoaching() {
        const customagentRec = window.LearningProgressTracker?.getCustomagentRecommendation();
        if (customagentRec) {
            // Navigate to custom agent - use correct Docsify path
            const customagentUrl = `#/docs/github-copilot/customagents/${customagentRec.customagent}`;
            window.location.hash = customagentUrl;

            // Close modal
            this.closeModal('coaching');
        }
    }

    /**
     * Shows a message within the modal
     */
    showModalMessage(message, type = 'info') {
        const modalBody = this.modal.querySelector('.assessment-modal-body');

        // Remove existing message
        const existingMessage = modalBody.querySelector('.modal-message');
        if (existingMessage) {
            existingMessage.remove();
        }

        // Create new message
        const messageElement = document.createElement('div');
        messageElement.className = `modal-message ${type}`;
        messageElement.textContent = message;

        // Insert at top of modal body
        modalBody.insertBefore(messageElement, modalBody.firstChild);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (messageElement.parentNode) {
                messageElement.remove();
            }
        }, 5000);
    }

    /**
     * Opens the modal
     */
    openModal() {
        if (this.modal) {
            this.modal.style.display = 'flex';
            this.isOpen = true;
            document.body.style.overflow = 'hidden'; // Prevent background scroll

            // Focus management for accessibility
            const firstFocusable = this.modal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
            if (firstFocusable) {
                firstFocusable.focus();
            }
        }
    }

    /**
     * Closes the modal
     */
    closeModal(action = 'closed') {
        if (this.modal) {
            // Resolve the promise if it exists
            if (this.modalResolve) {
                this.modalResolve({ action, timestamp: new Date().toISOString() });
                this.modalResolve = null;
            }

            // Call destroy() instead of just hiding to ensure proper cleanup
            this.destroy();
        }
    }

    /**
     * Destroys the modal and cleans up
     */
    destroy() {
      if (this.modal) {
        this.modal.remove();
        this.modal = null;
        this.isOpen = false;
        document.body.style.overflow = '';

        // Clean up event listeners
        if (this.escapeHandler) {
          document.removeEventListener('keydown', this.escapeHandler);
          this.escapeHandler = null;
        }
      }
    }    /**
     * Adds CSS styles for the modal
     */
    addModalStyles() {
        if (document.getElementById('assessment-modal-styles')) return;

        const styles = `
            <style id="assessment-modal-styles">
                .assessment-modal-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.7);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 10000;
                    backdrop-filter: blur(4px);
                }

                .assessment-modal-content {
                    background: var(--theme-color, #fff);
                    border-radius: 12px;
                    max-width: 600px;
                    width: 90%;
                    max-height: 90vh;
                    overflow-y: auto;
                    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                    position: relative;
                    color: var(--text-color-base, #333);
                }

                .assessment-modal-header {
                    padding: 24px 24px 16px;
                    border-bottom: 1px solid var(--border-color, #eee);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }

                .assessment-modal-header h2 {
                    margin: 0;
                    font-size: 24px;
                    font-weight: 600;
                }

                .assessment-modal-close {
                    background: none;
                    border: none;
                    font-size: 24px;
                    cursor: pointer;
                    padding: 4px 8px;
                    border-radius: 4px;
                    transition: background-color 0.2s;
                }

                .assessment-modal-close:hover {
                    background: var(--border-color, #eee);
                }

                .assessment-modal-body {
                    padding: 24px;
                }

                .assessment-results,
                .learning-path-recommendation,
                .next-steps {
                    margin-bottom: 24px;
                    padding: 16px;
                    border-radius: 8px;
                    background: var(--background-color, #f8f9fa);
                }

                .skill-level-display {
                    text-align: center;
                    margin-bottom: 16px;
                }

                .skill-badge {
                    display: inline-block;
                    padding: 8px 16px;
                    border-radius: 20px;
                    font-weight: 600;
                    font-size: 14px;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }

                .skill-badge.foundation {
                    background: #e3f2fd;
                    color: #1565c0;
                }

                .skill-badge.intermediate {
                    background: #f3e5f5;
                    color: #6a1b9a;
                }

                .skill-badge.expert {
                    background: #e8f5e8;
                    color: #2e7d32;
                }

                .assessment-summary p {
                    margin: 8px 0;
                    font-size: 16px;
                }

                .recommended-path-content {
                    margin-top: 12px;
                }

                .path-title {
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 8px;
                }

                .path-description {
                    margin-bottom: 8px;
                    color: var(--text-color-secondary, #666);
                }

                .estimated-duration {
                    font-size: 14px;
                    font-weight: 500;
                    color: var(--accent-color, #0084ff);
                }

                .customagent-recommendation {
                    text-align: center;
                }

                .modal-message {
                    padding: 12px 16px;
                    border-radius: 6px;
                    margin-bottom: 16px;
                    font-weight: 500;
                }

                .modal-message.success {
                    background: #d4edda;
                    color: #155724;
                    border: 1px solid #c3e6cb;
                }

                .modal-message.error {
                    background: #f8d7da;
                    color: #721c24;
                    border: 1px solid #f5c6cb;
                }

                .assessment-modal-footer {
                    padding: 16px 24px 24px;
                    border-top: 1px solid var(--border-color, #eee);
                }

                .modal-actions {
                    display: flex;
                    gap: 12px;
                    justify-content: flex-end;
                    flex-wrap: wrap;
                }

                .modal-actions button {
                    padding: 12px 20px;
                    border: none;
                    border-radius: 6px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.2s;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    min-width: 140px;
                    justify-content: center;
                }

                .btn-primary {
                    background: var(--accent-color, #0084ff);
                    color: white;
                }

                .btn-primary:hover {
                    background: var(--accent-color-dark, #006fd6);
                    transform: translateY(-1px);
                }

                .btn-secondary {
                    background: transparent;
                    color: var(--text-color-base, #333);
                    border: 1px solid var(--border-color, #ddd);
                }

                .btn-secondary:hover {
                    background: var(--border-color, #eee);
                }

                .btn-success {
                    background: #28a745;
                    color: white;
                }

                .btn-error {
                    background: #dc3545;
                    color: white;
                }

                .btn-icon {
                    font-size: 16px;
                }

                @media (max-width: 768px) {
                    .assessment-modal-content {
                        width: 95%;
                        margin: 20px;
                    }

                    .modal-actions {
                        flex-direction: column;
                    }

                    .modal-actions button {
                        width: 100%;
                    }
                }
            </style>
        `;

        document.head.insertAdjacentHTML('beforeend', styles);
    }

    /**
     * Creates default API client for saving learning paths
     */
    createDefaultApiClient() {
        return {
            async post(url, data) {
                try {
                    const response = await fetch(url, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify(data)
                    });

                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }

                    return await response.json();
                } catch (error) {
                    // Fallback for development/testing
                    console.warn('API call failed, using localStorage fallback:', error);

                    // Save to localStorage as fallback
                    const learningPaths = JSON.parse(localStorage.getItem('saved-learning-paths') || '[]');
                    learningPaths.push({
                        id: Date.now(),
                        ...data,
                        savedAt: new Date().toISOString()
                    });
                    localStorage.setItem('saved-learning-paths', JSON.stringify(learningPaths));

                    return { success: true, fallback: true };
                }
            }
        };
    }

    /**
     * Creates default DOM utilities
     */
    createDefaultDomUtils() {
        return {
            querySelector: (selector) => document.querySelector(selector),
            querySelectorAll: (selector) => document.querySelectorAll(selector)
        };
    }
}

// ES6 export
export { AssessmentCompletionModal };

// Make available globally for browser usage
if (typeof window !== 'undefined') {
    window.AssessmentCompletionModal = AssessmentCompletionModal;
}
