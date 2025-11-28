/**
 * Skill Assessment Plugin
 * Provides comprehensive skill assessment progress tracking with localStorage persistence,
 * progress calculations, and event handling for learning documentation.
 */

// Simple class implementation that focuses on minimal functionality for TDD GREEN phase
class SkillAssessmentPlugin {
  constructor(config = {}) {
    // Default configuration
    this.config = {
      container: '#skill-assessment-container',
      autoSave: true,
      trackTime: true,
      storageKey: 'skill-assessment-progress',
      difficultyWeights: {
        beginner: 1,
        intermediate: 2,
        advanced: 3
      },
      ...config
    };

    this.questions = [];
    this.answers = {};
    this.startTime = null;
    this.initialized = false;
    this.performanceData = {
      initTime: 0,
      renderTime: 0,
      interactionCount: 0
    };
  }

  // Initialize the plugin - minimal implementation for GREEN phase
  init() {
    const startTime = performance.now();
    try {
      this.startTime = Date.now();
      this.loadProgress();
      this.findQuestions();
      this.bindEvents();
      this.createAriaLiveRegion();
      this.renderProgress();
      this.initialized = true;
      this.performanceData.initTime = performance.now() - startTime;
      this.emit('assessmentInitialized', {
        questionsFound: this.questions.length,
        previousProgress: Object.keys(this.answers).length
      });
    } catch (error) {
      console.error('Failed to initialize Skill Assessment Plugin:', error);
      throw error;
    }
  }

  // Find and parse assessment questions - minimal implementation
  findQuestions() {
    const container = document.querySelector(this.config.container);
    if (!container) {
      console.warn(`Assessment container not found: ${this.config.container}`);
      this.questions = [];
      return;
    }
    const questionElements = container.querySelectorAll('.assessment-question');
    this.questions = [];
    questionElements.forEach(el => {
      const questionData = this.parseQuestionElement(el);
      if (questionData && this.validateQuestionData(questionData)) {
        this.questions.push(questionData);
      }
    });
  }

  // Parse question element - minimal implementation
  parseQuestionElement(element) {
    try {
      return {
        id: element.dataset.questionId,
        skill: element.dataset.skill,
        difficulty: element.dataset.difficulty,
        element: element,
        options: Array.from(element.querySelectorAll('.option')).map(opt => ({
          text: opt.textContent.trim(),
          correct: opt.dataset.correct === 'true',
          element: opt
        }))
      };
    } catch (error) {
      console.warn('Failed to parse question element:', error);
      return null;
    }
  }

  // Validate question data - minimal implementation
  validateQuestionData(questionData) {
    return questionData.id &&
           questionData.skill &&
           questionData.difficulty &&
           questionData.options &&
           questionData.options.length > 0;
  }

  // Bind events - minimal implementation
  bindEvents() {
    this.questions.forEach(question => {
      question.options.forEach((option, index) => {
        // Add ARIA attributes for accessibility
        option.element.setAttribute('role', 'button');
        option.element.setAttribute('tabindex', '0');
        option.element.setAttribute('aria-describedby', `question-${question.id}`);

        option.element.addEventListener('click', (e) => {
          this.handleOptionClick(question.id, option.text, option.correct, question);
        });
        option.element.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            this.handleOptionClick(question.id, option.text, option.correct, question);
          } else if (e.key === 'ArrowDown' || e.key === 'ArrowRight') {
            e.preventDefault();
            this.focusNextOption(question, index);
          } else if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') {
            e.preventDefault();
            this.focusPreviousOption(question, index);
          }
        });
      });
    });
  }

  // Focus management for keyboard navigation
  focusNextOption(question, currentIndex) {
    const nextIndex = (currentIndex + 1) % question.options.length;
    question.options[nextIndex].element.focus();
  }

  focusPreviousOption(question, currentIndex) {
    const prevIndex = currentIndex === 0 ? question.options.length - 1 : currentIndex - 1;
    question.options[prevIndex].element.focus();
  }

  // Handle option clicks - minimal implementation
  handleOptionClick(questionId, answer, correct, question) {
    this.performanceData.interactionCount++;
    this.answerQuestion(questionId, answer, correct);
    this.provideFeedback(questionId, correct);
    if (this.onQuestionAnswered) {
      this.onQuestionAnswered({
        questionId: questionId,
        answer: answer,
        correct: correct,
        skill: question.skill,
        difficulty: question.difficulty
      });
    }
    this.manageFocus(questionId);
  }

  // Provide immediate feedback
  provideFeedback(questionId, correct) {
    const questionElement = document.querySelector(`[data-question-id="${questionId}"]`);
    if (!questionElement) return;

    // Remove existing feedback
    const existingFeedback = questionElement.querySelector('.answer-feedback');
    if (existingFeedback) {
      existingFeedback.remove();
    }

    // Create new feedback element
    const feedback = document.createElement('div');
    feedback.className = `answer-feedback ${correct ? 'correct' : 'incorrect'}`;
    feedback.textContent = correct ? 'Correct!' : 'Incorrect. Please try again.';
    questionElement.appendChild(feedback);
  }

  // Answer question - minimal implementation
  answerQuestion(questionId, answer, correct) {
    // Validate question exists
    const question = this.questions.find(q => q.id === questionId);
    if (!question) {
      console.warn(`Invalid question ID: ${questionId}`);
      return;
    }

    // Validate answer data
    if (!answer || typeof answer !== 'string' || answer.trim() === '') {
      console.warn(`Invalid answer data for question ${questionId}`);
      return;
    }

    // Prevent duplicate answers
    if (this.answers[questionId]) {
      return;
    }

    this.answers[questionId] = {
      answer: answer,
      correct: correct,
      timestamp: Date.now()
    };

    // Update DOM to show answered state
    this.updateQuestionDOM(questionId, correct);

    if (this.config.autoSave) {
      this.saveProgress();
    }
    this.renderProgress();
    this.announceProgress(questionId, correct);
    this.emit('assessmentProgressUpdated', {
      progress: this.getProgress(),
      skillProgress: this.getSkillProgress()
    });
    if (this.isComplete()) {
      this.handleCompletion();
    }
  }

  // Update question DOM when answered
  updateQuestionDOM(questionId, correct) {
    const questionElement = document.querySelector(`[data-question-id="${questionId}"]`);
    if (questionElement) {
      questionElement.classList.add('answered');
      questionElement.classList.add(correct ? 'correct' : 'incorrect');
    }
  }

  // Get progress - minimal implementation
  getProgress() {
    const totalQuestions = this.questions.length;
    const answeredQuestions = Object.keys(this.answers).length;
    const correctAnswers = Object.values(this.answers).filter(a => a.correct).length;
    return {
      totalQuestions,
      answeredQuestions,
      correctAnswers,
      percentage: totalQuestions > 0 ? Math.round((answeredQuestions / totalQuestions) * 100) : 0
    };
  }

  // Get skill progress - minimal implementation
  getSkillProgress() {
    const skillProgress = {};
    this.questions.forEach(question => {
      if (!skillProgress[question.skill]) {
        skillProgress[question.skill] = { total: 0, correct: 0 };
      }
      skillProgress[question.skill].total++;
      const answer = this.answers[question.id];
      if (answer && answer.correct) {
        skillProgress[question.skill].correct++;
      }
    });
    return skillProgress;
  }

  // Calculate weighted score - minimal implementation
  calculateWeightedScore() {
    let totalPoints = 0;
    let earnedPoints = 0;
    this.questions.forEach(question => {
      const weight = this.config.difficultyWeights[question.difficulty] || 1;
      totalPoints += weight;
      const answer = this.answers[question.id];
      if (answer && answer.correct) {
        earnedPoints += weight;
      }
    });
    return {
      totalPoints,
      earnedPoints,
      weightedScore: totalPoints > 0 ? Math.round((earnedPoints / totalPoints) * 100) : 0
    };
  }

  // Get time spent - minimal implementation
  getTimeSpent() {
    if (!this.startTime) return 0;
    return Date.now() - this.startTime;
  }

  // Get start time - minimal implementation
  getStartTime() {
    return this.startTime || 0;
  }

  // Check completion - minimal implementation
  isComplete() {
    return Object.keys(this.answers).length === this.questions.length;
  }

  // Handle completion - minimal implementation
  handleCompletion() {
    const finalScore = this.calculateWeightedScore();
    const timeSpent = this.getTimeSpent();
    const skillBreakdown = this.getSkillProgress();
    this.emit('assessmentCompleted', {
      finalScore,
      timeSpent,
      skillBreakdown
    });
  }

  // Get final score - for test compatibility
  getFinalScore() {
    const skillProgress = this.getSkillProgress();
    const skillBreakdown = {};

    // Convert skill progress to expected format
    Object.entries(skillProgress).forEach(([skill, progress]) => {
      skillBreakdown[skill] = {
        accuracy: progress.total > 0 ? progress.correct / progress.total : 0
      };
    });

    const overallProgress = this.getProgress();
    return {
      accuracy: overallProgress.totalQuestions > 0 ?
        overallProgress.correctAnswers / overallProgress.totalQuestions : 0,
      skillBreakdown
    };
  }

  // Navigation methods for test compatibility
  canNavigateToQuestion(questionId) {
    return this.questions.some(q => q.id === questionId);
  }

  goToQuestion(questionId) {
    const question = this.questions.find(q => q.id === questionId);
    if (question && question.element) {
      question.element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      const firstOption = question.element.querySelector('.option');
      if (firstOption) {
        firstOption.focus();
      }
      return true;
    }
    return false;
  }

  goToNextQuestion() {
    const answeredIds = Object.keys(this.answers);
    const nextQuestion = this.questions.find(q => !answeredIds.includes(q.id));
    if (nextQuestion) {
      return this.goToQuestion(nextQuestion.id);
    }
    return false;
  }

  goToPreviousQuestion() {
    // Find the last answered question
    const answeredQuestions = this.questions.filter(q => this.answers[q.id]);
    if (answeredQuestions.length > 0) {
      const lastAnswered = answeredQuestions[answeredQuestions.length - 1];
      return this.goToQuestion(lastAnswered.id);
    }
    return false;
  }

  // Sync progress - placeholder for test compatibility
  syncProgress() {
    // In a real implementation, this would sync with a server
    return Promise.resolve({ status: 'synced', timestamp: Date.now() });
  }

  // Render progress - minimal implementation
  renderProgress() {
    const renderStart = performance.now();
    this.updateProgressIndicator();
    this.updateSkillBreakdown();
    this.performanceData.renderTime = performance.now() - renderStart;
  }

  // Update progress display - minimal implementation (alias for renderProgress)
  updateProgressDisplay() {
    this.renderProgress();
  }

  // Update progress indicator - minimal implementation
  updateProgressIndicator() {
    const progressIndicator = document.querySelector('.progress-indicator');
    if (!progressIndicator) return;

    const progress = this.getProgress();

    // Add responsive class based on screen size
    if (window.innerWidth <= 768) {
      progressIndicator.classList.add('mobile-layout');
    } else {
      progressIndicator.classList.remove('mobile-layout');
    }

    progressIndicator.innerHTML = `
      <div class="progress-bar">
        <div class="progress-fill" style="width: ${progress.percentage}%"></div>
      </div>
      <div class="progress-text">
        ${progress.percentage}% Complete (${progress.answeredQuestions} of ${progress.totalQuestions})
      </div>
    `;
  }

  // Update skill breakdown - minimal implementation
  updateSkillBreakdown() {
    const skillBreakdown = document.querySelector('.skill-breakdown');
    if (!skillBreakdown) return;
    const skillProgress = this.getSkillProgress();
    let html = '<div class="skill-progress-list">';
    Object.entries(skillProgress).forEach(([skill, progress]) => {
      html += `
        <div class="skill-item">
          <span class="skill-name">${skill}</span>
          <span class="skill-score">${progress.correct}/${progress.total}</span>
        </div>
      `;
    });
    html += '</div>';
    skillBreakdown.innerHTML = html;
  }

  // Desktop-only layout - no responsive changes needed

  // Create aria-live region for screen reader announcements
  createAriaLiveRegion() {
    if (!document.querySelector('[aria-live]')) {
      const ariaLive = document.createElement('div');
      ariaLive.setAttribute('aria-live', 'polite');
      ariaLive.setAttribute('aria-atomic', 'true');
      ariaLive.style.position = 'absolute';
      ariaLive.style.left = '-10000px';
      ariaLive.style.width = '1px';
      ariaLive.style.height = '1px';
      ariaLive.style.overflow = 'hidden';
      document.body.appendChild(ariaLive);
    }
  }

  // Announce progress - minimal implementation
  announceProgress(questionId, correct) {
    const ariaLive = document.querySelector('[aria-live]');
    if (ariaLive) {
      const progress = this.getProgress();
      const result = correct ? 'correctly' : 'incorrectly';
      ariaLive.textContent = `Question ${questionId} answered ${result}. Progress: ${progress.percentage}% complete.`;
    }
  }

  // Manage focus - minimal implementation
  manageFocus(currentQuestionId) {
    // Find next unanswered question
    const nextQuestion = this.questions.find(q =>
      parseInt(q.id) > parseInt(currentQuestionId) && !this.answers[q.id]
    );

    if (nextQuestion) {
      const firstOption = nextQuestion.element.querySelector('.option');
      if (firstOption) {
        // Use requestAnimationFrame for better test compatibility
        requestAnimationFrame(() => {
          firstOption.focus();
          firstOption.scrollIntoView({ behavior: 'smooth', block: 'center' });
        });
      }
    } else if (this.isComplete()) {
      // Assessment is complete, focus on completion message or summary
      const completionElement = document.querySelector('.assessment-completion');
      if (completionElement) {
        requestAnimationFrame(() => {
          completionElement.focus();
          completionElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        });
      }
    }
  }

  // Save progress - minimal implementation
  saveProgress() {
    if (!this.config.autoSave) return;
    try {
      const progressData = {
        answers: this.answers,
        startTime: this.startTime,
        timestamp: Date.now()
      };
      localStorage.setItem(this.config.storageKey, JSON.stringify(progressData));
    } catch (error) {
      console.warn('Failed to save progress to localStorage:', error);
    }
  }

  // Load progress - minimal implementation
  loadProgress() {
    try {
      const savedData = localStorage.getItem(this.config.storageKey);
      if (savedData) {
        const progressData = JSON.parse(savedData);
        this.answers = progressData.answers || {};
        this.startTime = progressData.startTime || Date.now();
      }
    } catch (error) {
      console.warn('Failed to load progress from localStorage:', error);
      this.answers = {};
      this.startTime = Date.now();
    }
  }

  // Emit custom events - minimal implementation
  emit(eventName, detail) {
    const event = new CustomEvent(eventName, { detail });
    document.dispatchEvent(event);
  }
}

// Expose globally to both window and globalThis
// Ensure the class constructor is properly exported
if (typeof window !== 'undefined') {
  window.SkillAssessmentPlugin = SkillAssessmentPlugin;
}
if (typeof globalThis !== 'undefined') {
  globalThis.SkillAssessmentPlugin = SkillAssessmentPlugin;
}
