/**
 * Test Data Fixtures for Progress Annotations
 * Provides standardized test data for progress tracking and annotation components
 *
 * @module ProgressData
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * Sample progress annotation data for different states
 */
export const SAMPLE_PROGRESS_STATES = {
  onYourPath: {
    kataId: 'ai-assisted-engineering/01-ai-development-fundamentals',
    state: 'on-your-path',
    selected: true,
    selectedAt: '2025-08-17T08:00:00Z',
    fromAssessment: true,
    completed: false,
    progress: 0,
    pathId: 'foundation-ai-first-engineering',
    priority: 1
  },

  inProgress: {
    kataId: 'prompt-engineering/01-prompt-engineering-basics',
    state: 'in-progress',
    selected: true,
    selectedAt: '2025-08-16T10:00:00Z',
    fromAssessment: true,
    completed: false,
    progress: 0.4,
    startedAt: '2025-08-17T09:15:00Z',
    timeSpent: 25,
    pathId: 'foundation-ai-first-engineering',
    priority: 1
  },

  completed: {
    kataId: 'project-planning/01-basic-prompt-usage',
    state: 'completed',
    selected: true,
    selectedAt: '2025-08-15T14:00:00Z',
    fromAssessment: true,
    completed: true,
    progress: 1.0,
    completedAt: '2025-08-16T16:30:00Z',
    timeSpent: 35,
    score: 92,
    pathId: 'intermediate-infrastructure-architect',
    priority: 2
  },

  notSelected: {
    kataId: 'adr-creation/01-ai-decision-documentation',
    state: 'not-selected',
    selected: false,
    completed: false,
    progress: 0,
    pathId: null,
    priority: null
  },

  selectedButNotStarted: {
    kataId: 'ai-assisted-engineering/02-ai-code-review-techniques',
    state: 'selected-not-started',
    selected: true,
    selectedAt: '2025-08-17T08:00:00Z',
    fromAssessment: true,
    completed: false,
    progress: 0,
    pathId: 'foundation-ai-first-engineering',
    priority: 1
  }
};

/**
 * Sample annotation configurations for different progress states
 */
export const ANNOTATION_CONFIGS = {
  onYourPath: {
    badgeText: 'On Your Path',
    badgeClass: 'progress-badge on-your-path',
    iconClass: 'icon-path',
    textColor: 'text-path',
    description: 'This item is part of your selected learning path',
    showProgress: false,
    showEstimatedTime: true
  },

  inProgress: {
    badgeText: 'In Progress',
    badgeClass: 'progress-badge in-progress',
    iconClass: 'icon-progress',
    textColor: 'text-progress',
    description: 'You have started working on this item',
    showProgress: true,
    showEstimatedTime: true,
    progressPercentage: 40
  },

  completed: {
    badgeText: 'Completed',
    badgeClass: 'progress-badge completed',
    iconClass: 'icon-completed',
    textColor: 'text-completed',
    description: 'You have completed this item',
    showProgress: false,
    showEstimatedTime: false,
    showScore: true,
    score: 92
  },

  notSelected: {
    badgeText: null,
    badgeClass: null,
    iconClass: null,
    textColor: 'text-default',
    description: null,
    showProgress: false,
    showEstimatedTime: true
  },

  selectedButNotStarted: {
    badgeText: 'Ready to Start',
    badgeClass: 'progress-badge ready-to-start',
    iconClass: 'icon-ready',
    textColor: 'text-ready',
    description: 'This item is selected and ready to begin',
    showProgress: false,
    showEstimatedTime: true
  }
};

/**
 * Sample markdown elements with different progress states
 */
export const SAMPLE_MARKDOWN_ELEMENTS = {
  basicKataCheckbox: {
    html: `
      <li class="task-list-item">
        <input type="checkbox" id="ai-dev-fundamentals" data-kata-id="ai-assisted-engineering/01-ai-development-fundamentals">
        <label for="ai-dev-fundamentals">
          <strong>AI Development Fundamentals</strong>
          <span class="kata-meta">45 min • Foundation</span>
        </label>
      </li>
    `,
    kataId: 'ai-assisted-engineering/01-ai-development-fundamentals',
    elementId: 'ai-dev-fundamentals'
  },

  complexKataCheckbox: {
    html: `
      <li class="task-list-item">
        <input type="checkbox" id="prompt-basics" data-kata-id="prompt-engineering/01-prompt-engineering-basics">
        <label for="prompt-basics">
          <strong>Prompt Engineering Basics</strong>
          <span class="kata-meta">60 min • Core Skill</span>
          <p class="kata-description">Learn fundamental prompt engineering techniques for effective AI interaction.</p>
        </label>
      </li>
    `,
    kataId: 'prompt-engineering/01-prompt-engineering-basics',
    elementId: 'prompt-basics'
  },

  nestedKataCheckbox: {
    html: `
      <li class="task-list-item">
        <input type="checkbox" id="nested-kata" data-kata-id="nested/kata/example">
        <label for="nested-kata">
          <strong>Nested Kata Example</strong>
          <div class="kata-details">
            <span class="kata-meta">30 min • Practice</span>
            <div class="kata-tags">
              <span class="tag">Advanced</span>
              <span class="tag">Architecture</span>
            </div>
          </div>
        </label>
      </li>
    `,
    kataId: 'nested/kata/example',
    elementId: 'nested-kata'
  }
};

/**
 * Sample annotation elements that should be created
 */
export const EXPECTED_ANNOTATION_ELEMENTS = {
  progressBadge: {
    tagName: 'span',
    className: 'progress-badge',
    position: 'after-label'
  },

  progressIcon: {
    tagName: 'i',
    className: 'progress-icon',
    position: 'before-text'
  },

  progressBar: {
    tagName: 'div',
    className: 'progress-bar-container',
    position: 'after-description',
    innerHTML: '<div class="progress-bar"><div class="progress-fill"></div></div>'
  },

  progressText: {
    tagName: 'span',
    className: 'progress-text',
    position: 'after-meta'
  },

  scoreDisplay: {
    tagName: 'span',
    className: 'score-display',
    position: 'after-meta'
  }
};

/**
 * Sample bulk progress data for performance testing
 */
export const BULK_PROGRESS_DATA = {
  largePath: Array.from({ length: 50 }, (_, _index) => ({
    kataId: `performance-test/kata-${_index + 1}`,
    state: _index < 10 ? 'completed' : _index < 25 ? 'in-progress' : 'on-your-path',
    selected: true,
    completed: _index < 10,
    progress: _index < 10 ? 1.0 : _index < 25 ? (_index - 9) / 15 : 0,
    pathId: 'performance-test-path'
  })),

  multiplePathsData: {
    'foundation-ai-first-engineering': Array.from({ length: 15 }, (_, _index) => ({
      kataId: `ai-engineering/kata-${_index + 1}`,
      state: _index < 5 ? 'completed' : _index < 10 ? 'in-progress' : 'on-your-path',
      pathId: 'foundation-ai-first-engineering'
    })),

    'expert-enterprise-integration': Array.from({ length: 20 }, (_, _index) => ({
      kataId: `ai-architecture/kata-${_index + 1}`,
      state: _index < 3 ? 'completed' : _index < 8 ? 'in-progress' : 'on-your-path',
      pathId: 'expert-enterprise-integration'
    }))
  }
};

/**
 * Sample accessibility data for testing
 */
export const ACCESSIBILITY_TEST_DATA = {
  ariaLabels: {
    onYourPath: 'This kata is on your selected learning path',
    inProgress: 'This kata is currently in progress, 40% complete',
    completed: 'This kata has been completed with a score of 92%',
    notSelected: 'This kata is available but not currently selected',
    selectedButNotStarted: 'This kata is selected and ready to start'
  },

  ariaDescriptions: {
    progressBar: 'Progress indicator showing completion percentage',
    badge: 'Status indicator for learning progress',
    icon: 'Visual indicator for progress state'
  },

  keyboardNavigation: {
    tabOrder: ['checkbox', 'badge', 'progress-bar'],
    focusManagement: true,
    escapeKeyHandling: true
  }
};

/**
 * Sample error scenarios for annotation testing
 */
export const ANNOTATION_ERROR_SCENARIOS = {
  missingKataId: {
    html: `
      <li class="task-list-item">
        <input type="checkbox" id="missing-kata-id">
        <label for="missing-kata-id">Missing Kata ID</label>
      </li>
    `,
    expectedBehavior: 'graceful-degradation'
  },

  invalidProgressData: {
    progressData: {
      kataId: 'invalid/kata',
      state: 'invalid-state',
      progress: 'not-a-number',
      score: 'invalid-score'
    },
    expectedBehavior: 'default-state'
  },

  missingElements: {
    html: `<div class="empty-container"></div>`,
    expectedBehavior: 'no-annotations'
  },

  malformedMarkdown: {
    html: `
      <li class="task-list-item">
        <input type="checkbox" data-kata-id="malformed/kata">
        <!-- Missing label -->
      </li>
    `,
    expectedBehavior: 'defensive-handling'
  }
};

/**
 * Helper function to create mock progress data
 * @param {string} state - Progress state ('on-your-path', 'in-progress', 'completed', etc.)
 * @param {Object} overrides - Custom data to override defaults
 * @returns {Object} Mock progress data
 */
export function createMockProgressData(state, overrides = {}) {
  const baseData = SAMPLE_PROGRESS_STATES[state] || SAMPLE_PROGRESS_STATES.notSelected;
  return { ...baseData, ...overrides };
}

/**
 * Helper function to create mock annotation config
 * @param {string} state - Progress state for annotation config
 * @param {Object} overrides - Custom config to override defaults
 * @returns {Object} Mock annotation config
 */
export function createMockAnnotationConfig(state, overrides = {}) {
  const baseConfig = ANNOTATION_CONFIGS[state] || ANNOTATION_CONFIGS.notSelected;

  // Map state names to actual CSS state classes
  const stateMap = {
    'onYourPath': 'on-your-path',
    'inProgress': 'in-progress',
    'completed': 'completed',
    'notSelected': 'not-selected'
  };

  return {
    ...baseConfig,
    state: stateMap[state] || 'not-selected',
    text: baseConfig.badgeText,
    ariaLabel: baseConfig.description,
    ...overrides
  };
}

/**
 * Helper function to create test DOM element
 * @param {string} elementType - Type of element ('basicKataCheckbox', 'complexKataCheckbox', etc.)
 * @param {Object} modifications - HTML modifications to apply
 * @returns {Object} Test DOM element data
 */
export function createTestElement(elementType, modifications = {}) {
  const baseElement = SAMPLE_MARKDOWN_ELEMENTS[elementType] || SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox;

  let html = baseElement.html;
  if (modifications.html) {
    html = modifications.html;
  }

  return {
    ...baseElement,
    ...modifications,
    html
  };
}

/**
 * Get expected annotation elements for a given state
 * @param {string} state - Progress state
 * @returns {Array} Array of expected annotation elements
 */
export function getExpectedAnnotations(state) {
  const config = ANNOTATION_CONFIGS[state];
  const annotations = [];

  if (config.badgeText) {
    annotations.push({
      ...EXPECTED_ANNOTATION_ELEMENTS.progressBadge,
      textContent: config.badgeText,
      className: config.badgeClass
    });
  }

  if (config.iconClass) {
    annotations.push({
      ...EXPECTED_ANNOTATION_ELEMENTS.progressIcon,
      className: `progress-icon ${config.iconClass}`
    });
  }

  if (config.showProgress && config.progressPercentage) {
    annotations.push({
      ...EXPECTED_ANNOTATION_ELEMENTS.progressBar,
      dataset: { progress: config.progressPercentage }
    });
  }

  if (config.showScore && config.score) {
    annotations.push({
      ...EXPECTED_ANNOTATION_ELEMENTS.scoreDisplay,
      textContent: `Score: ${config.score}%`
    });
  }

  return annotations;
}
