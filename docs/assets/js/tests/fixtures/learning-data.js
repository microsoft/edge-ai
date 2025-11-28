/**
 * Test Data Fixtures for Learning Progress System
 * Provides standardized test data for testing selection vs progress independence
 *
 * @module LearningData
 * @author Edge AI Team
 * @version 2.0.0
 */

/**
 * Test pathMappings fixture matching production structure
 * Maps learning path IDs to arrays of kata IDs
 */
export const testPathMappings = {
  'path-foundation-ai-engineering': [
    'ai-assisted-engineering-100',
    'ai-assisted-engineering-110',
    'ai-assisted-engineering-120'
  ],
  'path-intermediate-infrastructure-architect': [
    'project-planning-100',
    'project-planning-110',
    'adr-creation-100'
  ],
  'path-expert-ai-architecture': [
    'ai-assisted-engineering-200',
    'task-planning-100',
    'adr-creation-200'
  ]
};

/**
 * Test selections array with sample kata IDs
 * Represents user's selected learning paths (stored in selectedLearningPaths)
 */
export const testSelections = [
  'ai-assisted-engineering-100',
  'ai-assisted-engineering-110',
  'project-planning-100'
];

/**
 * Test kata completion data matching kata-* localStorage structure
 * Represents individual kata progress and completion
 */
export const testKataCompletion = {
  'kata-ai-assisted-engineering-100': {
    completionPercentage: 100,
    completedPhases: ['phase-1', 'phase-2', 'phase-3'],
    lastUpdated: 1730073600000,
    timeSpent: 45
  },
  'kata-ai-assisted-engineering-110': {
    completionPercentage: 50,
    completedPhases: ['phase-1', 'phase-2'],
    lastUpdated: 1730077200000,
    timeSpent: 20
  },
  'kata-project-planning-100': {
    completionPercentage: 75,
    completedPhases: ['phase-1', 'phase-2'],
    lastUpdated: 1730080800000,
    timeSpent: 30
  }
};

/**
 * Test data for selection/progress independence scenarios
 * Verifies that selection state doesn't affect progress calculation
 */
export const testSelectionProgressScenarios = {
  // Scenario 1: Kata selected but 0% complete
  selectedNoProgress: {
    selectedLearningPaths: ['ai-assisted-engineering-100'],
    kataCompletion: {}
  },

  // Scenario 2: Kata not selected but has progress
  unselectedWithProgress: {
    selectedLearningPaths: [],
    kataCompletion: {
      'kata-ai-assisted-engineering-110': {
        completionPercentage: 50,
        completedPhases: ['phase-1', 'phase-2'],
        lastUpdated: 1730077200000,
        timeSpent: 20
      }
    }
  },

  // Scenario 3: Kata selected AND complete
  selectedAndComplete: {
    selectedLearningPaths: ['ai-assisted-engineering-110'],
    kataCompletion: {
      'kata-ai-assisted-engineering-110': {
        completionPercentage: 100,
        completedPhases: ['phase-1', 'phase-2', 'phase-3', 'phase-4'],
        lastUpdated: 1730088000000,
        timeSpent: 60
      }
    }
  },

  // Scenario 4: Path selected (auto-selects katas) but no progress
  pathSelectedNoProgress: {
    selectedLearningPaths: [
      'ai-assisted-engineering-100',
      'ai-assisted-engineering-110',
      'ai-assisted-engineering-120'
    ],
    kataCompletion: {}
  }
};

/**
 * Test localStorage keys for selection and progress data
 * Standardized key patterns for testing storage operations
 */
export const testStorageKeys = {
  selections: 'selectedLearningPaths',
  kata: (kataId) => `kata-${kataId}`
};

/**
 * Helper function to create fresh test data
 * Returns deep clones to prevent test pollution
 */
export function createTestData() {
  return {
    pathMappings: JSON.parse(JSON.stringify(testPathMappings)),
    selections: [...testSelections],
    kataCompletion: JSON.parse(JSON.stringify(testKataCompletion))
  };
}

/**
 * Helper function to clear all test data from localStorage
 * Use in beforeEach/afterEach hooks
 */
export function clearTestStorage() {
  localStorage.removeItem('selectedLearningPaths');

  // Clear all kata-* keys
  Object.keys(localStorage).forEach(key => {
    if (key.startsWith('kata-')) {
      localStorage.removeItem(key);
    }
  });
}

/**
 * Helper function to setup test localStorage with sample data
 * @param {Object} scenario - Scenario object with selectedLearningPaths and kataCompletion
 */
export function setupTestStorage(scenario) {
  clearTestStorage();

  if (scenario.selectedLearningPaths) {
    localStorage.setItem('selectedLearningPaths', JSON.stringify(scenario.selectedLearningPaths));
  }

  if (scenario.kataCompletion) {
    Object.entries(scenario.kataCompletion).forEach(([key, value]) => {
      localStorage.setItem(key, JSON.stringify(value));
    });
  }
}

/**
 * Helper function to setup test localStorage with default test data
 * @param {Object} options - Configuration options
 * @param {boolean} options.includeSelections - Include selection data
 * @param {boolean} options.includeKataCompletion - Include kata completion data
 */
export function setupTestStorageWithDefaults(options = {}) {
  const {
    includeSelections = true,
    includeKataCompletion = true
  } = options;

  clearTestStorage();

  if (includeSelections) {
    localStorage.setItem('selectedLearningPaths', JSON.stringify(testSelections));
  }

  if (includeKataCompletion) {
    Object.entries(testKataCompletion).forEach(([key, value]) => {
      localStorage.setItem(key, JSON.stringify(value));
    });
  }
}
