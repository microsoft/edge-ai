/**
 * Test Data Fixtures for Path Relationships
 * Provides test data for path dependencies, relationships, and auto-selection scenarios
 *
 * @module PathRelationshipsData
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * Comprehensive path relationship data for auto-selection testing
 */
export const PATH_RELATIONSHIPS = {
  'foundation-ai-first-engineering': {
    id: 'foundation-ai-first-engineering',
    title: 'Foundation Builder - AI Engineering',
    level: 'Beginner',
    autoSelectItems: [
      'ai-assisted-engineering/01-ai-development-fundamentals',
      'prompt-engineering/01-prompt-engineering-basics',
      'ai-assisted-engineering/02-ai-code-review-techniques',
      'prompt-engineering/02-advanced-prompt-patterns',
      'ai-assisted-engineering/03-ai-assisted-testing'
    ],
    prerequisites: [],
    dependencies: [],
    conflicts: ['expert-enterprise-integration'], // Beginner conflicts with expert
    relatedPaths: ['intermediate-infrastructure-architect', 'intermediate-devops-excellence'],
    category: 'foundation',
    estimatedTotalTime: 210, // Sum of individual kata times
    priority: 1
  },

  'intermediate-infrastructure-architect': {
    id: 'intermediate-infrastructure-architect',
    title: 'Intermediate - Infrastructure Architect',
    level: 'Intermediate',
    autoSelectItems: [
      'project-planning/01-basic-prompt-usage',
      'project-planning/02-comprehensive-two-scenario',
      'project-planning/03-advanced-strategic-planning'
    ],
    prerequisites: [],
    dependencies: [],
    conflicts: [],
    relatedPaths: ['foundation-ai-first-engineering', 'intermediate-devops-excellence'],
    category: 'intermediate',
    estimatedTotalTime: 135,
    priority: 2
  },

  'intermediate-devops-excellence': {
    id: 'intermediate-devops-excellence',
    title: 'Intermediate - DevOps Excellence',
    level: 'Intermediate',
    autoSelectItems: [
      'edge-deployment/01-edge-computing-fundamentals',
      'edge-deployment/02-container-deployment-basics',
      'training-labs/iot-edge/01-basic-setup',
      'system-troubleshooting/01-monitoring-basics',
      'system-troubleshooting/02-edge-troubleshooting'
    ],
    prerequisites: [],
    dependencies: [],
    conflicts: [],
    relatedPaths: ['foundation-ai-first-engineering'],
    category: 'intermediate',
    estimatedTotalTime: 180,
    priority: 3
  },

  'expert-enterprise-integration': {
    id: 'expert-enterprise-integration',
    title: 'Expert - Enterprise Integration',
    level: 'Advanced',
    autoSelectItems: [
      'ai-assisted-engineering/04-ai-system-architecture',
      'adr-creation/01-ai-decision-documentation',
      'task-planning/02-ai-driven-planning',
      'system-integration/03-enterprise-ai-patterns'
    ],
    prerequisites: ['intermediate-infrastructure-architect', 'intermediate-devops-excellence'],
    dependencies: [
      'ai-assisted-engineering/01-ai-development-fundamentals',
      'prompt-engineering/02-advanced-prompt-patterns',
      'system-integration/01-api-integration-patterns'
    ],
    conflicts: ['foundation-ai-first-engineering'], // Expert conflicts with beginner
    relatedPaths: ['expert-data-analytics-integration'],
    category: 'expert',
    estimatedTotalTime: 300,
    priority: 4
  },

  'expert-data-analytics-integration': {
    id: 'expert-data-analytics-integration',
    title: 'Expert - Data Analytics Integration',
    level: 'Advanced',
    autoSelectItems: [
      'full-stack/01-end-to-end-ai-integration',
      'full-stack/02-production-deployment',
      'full-stack/03-monitoring-and-observability'
    ],
    prerequisites: ['expert-enterprise-integration'],
    dependencies: [
      'ai-assisted-engineering/04-ai-system-architecture',
      'system-integration/02-microservices-architecture'
    ],
    conflicts: [],
    relatedPaths: ['expert-enterprise-integration'],
    category: 'expert',
    estimatedTotalTime: 400,
    priority: 5
  }
};

/**
 * Path dependency graph for testing complex scenarios
 */
export const DEPENDENCY_GRAPH = {
  nodes: [
    { id: 'foundation-ai-first-engineering', level: 0, category: 'foundation' },
    { id: 'intermediate-infrastructure-architect', level: 1, category: 'intermediate' },
    { id: 'intermediate-devops-excellence', level: 1, category: 'intermediate' },
    { id: 'expert-enterprise-integration', level: 2, category: 'expert' },
    { id: 'expert-data-analytics-integration', level: 3, category: 'expert' }
  ],
  edges: [
    { from: 'foundation-ai-first-engineering', to: 'intermediate-infrastructure-architect', type: 'prerequisite' },
    { from: 'foundation-ai-first-engineering', to: 'intermediate-devops-excellence', type: 'prerequisite' },
    { from: 'intermediate-infrastructure-architect', to: 'expert-enterprise-integration', type: 'prerequisite' },
    { from: 'intermediate-devops-excellence', to: 'expert-enterprise-integration', type: 'prerequisite' },
    { from: 'expert-enterprise-integration', to: 'expert-data-analytics-integration', type: 'prerequisite' },
    { from: 'foundation-ai-first-engineering', to: 'intermediate-infrastructure-architect', type: 'related' },
    { from: 'foundation-ai-first-engineering', to: 'intermediate-devops-excellence', type: 'related' },
    { from: 'intermediate-infrastructure-architect', to: 'intermediate-devops-excellence', type: 'related' },
    { from: 'expert-enterprise-integration', to: 'expert-data-analytics-integration', type: 'related' }
  ]
};

/**
 * Auto-selection scenarios for comprehensive testing
 */
export const AUTO_SELECTION_SCENARIOS = {
  // Scenario 1: Single foundation path selection
  singleFoundation: {
    name: 'Single Foundation Path',
    input: {
      selectedPaths: ['foundation-ai-first-engineering'],
      currentProgress: {},
      userLevel: 'Beginner'
    },
    expected: {
      autoSelectedItems: [
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'prompt-engineering/01-prompt-engineering-basics',
        'ai-assisted-engineering/02-ai-code-review-techniques',
        'prompt-engineering/02-advanced-prompt-patterns',
        'ai-assisted-engineering/03-ai-assisted-testing'
      ],
      suggestedRelated: ['intermediate-infrastructure-architect', 'intermediate-devops-excellence'],
      conflicts: [],
      warnings: []
    }
  },

  // Scenario 2: Multiple compatible foundation paths
  multipleFoundation: {
    name: 'Multiple Compatible Foundation Paths',
    input: {
      selectedPaths: ['foundation-ai-first-engineering', 'intermediate-infrastructure-architect'],
      currentProgress: {},
      userLevel: 'Beginner'
    },
    expected: {
      autoSelectedItems: [
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'prompt-engineering/01-prompt-engineering-basics',
        'ai-assisted-engineering/02-ai-code-review-techniques',
        'prompt-engineering/02-advanced-prompt-patterns',
        'ai-assisted-engineering/03-ai-assisted-testing',
        'project-planning/01-basic-prompt-usage',
        'project-planning/02-comprehensive-two-scenario',
        'project-planning/03-advanced-strategic-planning'
      ],
      suggestedRelated: ['intermediate-devops-excellence'],
      conflicts: [],
      warnings: []
    }
  },

  // Scenario 3: Skill level path with prerequisites
  skillWithPrerequisites: {
    name: 'Intermediate Path with Prerequisites',
    input: {
      selectedPaths: ['intermediate-infrastructure-architect'],
      currentProgress: {
        'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true },
        'prompt-engineering/01-prompt-engineering-basics': { completed: true }
      },
      userLevel: 'Intermediate'
    },
    expected: {
      autoSelectedItems: [
        'prompt-engineering/02-advanced-prompt-patterns',
        'prompt-engineering/03-domain-specific-prompting',
        'ai-assisted-engineering/05-ai-prompt-optimization'
      ],
      suggestedRelated: ['intermediate-devops-excellence'],
      conflicts: [],
      warnings: []
    }
  },

  // Scenario 4: Missing prerequisites
  missingPrerequisites: {
    name: 'Missing Prerequisites',
    input: {
      selectedPaths: ['intermediate-infrastructure-architect'],
      currentProgress: {},
      userLevel: 'Beginner'
    },
    expected: {
      autoSelectedItems: [], // No items auto-selected due to missing prerequisites
      suggestedRelated: [],
      conflicts: [],
      warnings: [
        {
          type: 'missing_prerequisite',
          message: 'Path "intermediate-infrastructure-architect" requires prerequisite path "foundation-ai-first-engineering"',
          pathId: 'intermediate-infrastructure-architect',
          missingPrerequisite: 'foundation-ai-first-engineering'
        }
      ]
    }
  },

  // Scenario 5: Level conflicts
  levelConflicts: {
    name: 'Level Conflicts',
    input: {
      selectedPaths: ['foundation-ai-first-engineering', 'expert-enterprise-integration'],
      currentProgress: {},
      userLevel: 'Beginner'
    },
    expected: {
      autoSelectedItems: [
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'prompt-engineering/01-prompt-engineering-basics',
        'ai-assisted-engineering/02-ai-code-review-techniques',
        'prompt-engineering/02-advanced-prompt-patterns',
        'ai-assisted-engineering/03-ai-assisted-testing'
      ], // Only foundation items selected
      suggestedRelated: ['foundation-project-planning', 'foundation-edge-computing'],
      conflicts: [
        {
          type: 'level_conflict',
          message: 'Path "expert-enterprise-integration" (Advanced) conflicts with "foundation-ai-first-engineering" (Beginner)',
          conflictingPaths: ['foundation-ai-first-engineering', 'expert-enterprise-integration']
        }
      ],
      warnings: []
    }
  },

  // Scenario 6: Complex expert path
  expertPath: {
    name: 'Expert Path with Full Prerequisites',
    input: {
      selectedPaths: ['expert-enterprise-integration'],
      currentProgress: {
        'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true },
        'prompt-engineering/01-prompt-engineering-basics': { completed: true },
        'prompt-engineering/02-advanced-prompt-patterns': { completed: true },
        'system-integration/01-api-integration-patterns': { completed: true }
      },
      userLevel: 'Advanced'
    },
    expected: {
      autoSelectedItems: [
        'ai-assisted-engineering/04-ai-system-architecture',
        'adr-creation/01-ai-decision-documentation',
        'task-planning/02-ai-driven-planning',
        'system-integration/03-enterprise-ai-patterns'
      ],
      suggestedRelated: ['expert-data-analytics-integration'],
      conflicts: [],
      warnings: []
    }
  },

  // Scenario 7: Partial progress affecting selection
  partialProgress: {
    name: 'Partial Progress Affecting Selection',
    input: {
      selectedPaths: ['foundation-ai-first-engineering'],
      currentProgress: {
        'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true },
        'prompt-engineering/01-prompt-engineering-basics': { inProgress: true, progress: 0.6 }
      },
      userLevel: 'Beginner'
    },
    expected: {
      autoSelectedItems: [
        'ai-assisted-engineering/02-ai-code-review-techniques',
        'prompt-engineering/02-advanced-prompt-patterns',
        'ai-assisted-engineering/03-ai-assisted-testing'
      ], // Exclude completed and in-progress items
      suggestedRelated: ['intermediate-infrastructure-architect', 'intermediate-devops-excellence'],
      conflicts: [],
      warnings: []
    }
  }
};

/**
 * Conflict resolution test data
 */
export const CONFLICT_SCENARIOS = {
  levelConflicts: [
    {
      paths: ['foundation-ai-first-engineering', 'expert-enterprise-integration'],
      expectedResolution: 'foundation-ai-first-engineering', // Keep the foundation level
      reason: 'Beginner path takes precedence over expert when user level is Beginner'
    },
    {
      paths: ['intermediate-infrastructure-architect', 'expert-data-analytics-integration'],
      expectedResolution: 'intermediate-infrastructure-architect',
      reason: 'Intermediate path preferred for users without prerequisites'
    }
  ],

  prerequisiteConflicts: [
    {
      paths: ['intermediate-infrastructure-architect'],
      missingPrerequisites: ['foundation-ai-first-engineering'],
      expectedResolution: 'suggest_prerequisite',
      reason: 'Should suggest adding prerequisite path instead of selecting conflicting path'
    },
    {
      paths: ['expert-data-analytics-integration'],
      missingPrerequisites: ['expert-enterprise-integration', 'intermediate-devops-excellence'],
      expectedResolution: 'suggest_prerequisite',
      reason: 'Should suggest multiple missing prerequisites'
    }
  ]
};

/**
 * Performance test data for large-scale scenarios
 */
export const PERFORMANCE_TEST_DATA = {
  largePath: {
    id: 'performance-test-path',
    title: 'Performance Test Path',
    level: 'Advanced',
    category: 'Performance',
    autoSelectItems: Array.from({ length: 100 }, (_, i) => `performance/kata-${i.toString().padStart(3, '0')}`),
    prerequisites: [],
    dependencies: [],
    conflicts: [],
    relatedPaths: Array.from({ length: 20 }, (_, i) => `related-path-${i}`)
  },

  manyPaths: Array.from({ length: 50 }, (_, i) => ({
    id: `path-${i}`,
    title: `Test Path ${i}`,
    level: 'Beginner',
    category: 'Test',
    autoSelectItems: Array.from({ length: 10 }, (_, j) => `path-${i}/kata-${j}`),
    prerequisites: i > 0 ? [`path-${i - 1}`] : [],
    dependencies: [],
    conflicts: [],
    relatedPaths: []
  }))
};

/**
 * Helper functions for test data manipulation
 */

/**
 * Get all kata IDs from path relationships
 * @returns {Array} Array of all kata IDs
 */
export function getAllKataIdsFromPaths() {
  const allIds = [];
  Object.values(PATH_RELATIONSHIPS).forEach(path => {
    allIds.push(...path.autoSelectItems);
  });
  return [...new Set(allIds)]; // Remove duplicates
}

/**
 * Get paths by category
 * @param {string} category - Category to filter by (foundation, skill, expert)
 * @returns {Array} Array of path objects
 */
export function getPathsByCategory(category) {
  return Object.values(PATH_RELATIONSHIPS).filter(path => path.category === category);
}

/**
 * Get paths by level
 * @param {string} level - Level to filter by (Beginner, Intermediate, Advanced)
 * @returns {Array} Array of path objects
 */
export function getPathsByLevel(level) {
  return Object.values(PATH_RELATIONSHIPS).filter(path => path.level === level);
}

/**
 * Create custom conflict scenario
 * @param {Array} pathIds - Array of path IDs that conflict
 * @param {string} type - Type of conflict (level, prerequisite, custom)
 * @returns {Object} Conflict scenario object
 */
export function createConflictScenario(pathIds, type = 'custom') {
  return {
    name: `Custom ${type} conflict`,
    input: {
      selectedPaths: pathIds,
      currentProgress: {},
      userLevel: 'Beginner'
    },
    expectedConflict: {
      type,
      conflictingPaths: pathIds
    }
  };
}

/**
 * Generate test data for specific scenario
 * @param {string} scenarioName - Name of the scenario from AUTO_SELECTION_SCENARIOS
 * @param {Object} overrides - Custom overrides for the scenario
 * @returns {Object} Test scenario data
 */
export function generateScenarioData(scenarioName, overrides = {}) {
  const baseScenario = AUTO_SELECTION_SCENARIOS[scenarioName];
  if (!baseScenario) {
    throw new Error(`Unknown scenario: ${scenarioName}`);
  }

  return {
    ...baseScenario,
    input: { ...baseScenario.input, ...overrides.input },
    expected: { ...baseScenario.expected, ...overrides.expected }
  };
}

/**
 * Create a test scenario with specified parameters
 * @param {string} name - Scenario name
 * @param {Array<string>} selectedPaths - Selected path IDs
 * @param {Object} currentProgress - Progress data
 * @param {string} userLevel - User level
 * @param {Object} expected - Expected results
 * @returns {Object} Test scenario
 */
export function createTestScenario(name, selectedPaths, currentProgress = {}, userLevel = 'Beginner', expected = {}) {
  return {
    name,
    input: {
      selectedPaths,
      currentProgress,
      userLevel
    },
    expected: {
      autoSelectedItems: [],
      suggestedRelated: [],
      conflicts: [],
      warnings: [],
      ...expected
    }
  };
}

/**
 * Create mock dependencies for testing
 * @param {Object} overrides - Override default mocks
 * @returns {Object} Mock dependencies
 */
export function mockDependencies(overrides = {}) {
  return {
    learningPathManager: {
      getKataProgress: () => ({}),
      getUserLevel: () => 'Beginner',
      updatePathSelections: () => {},
      getAllPaths: () => Object.values(PATH_RELATIONSHIPS),
      getSelectedPaths: () => [],
      getConfig: () => ({ autoSelection: { enabled: true } }),
      ...overrides.learningPathManager
    },
    errorHandler: {
      safeExecute: (fn, context, fallback) => {
        try {
          return fn();
        } catch (_error) {
          return fallback;
        }
      },
      recordError: () => {},
      handleError: () => {},
      ...overrides.errorHandler
    },
    debugHelper: {
      log: () => {},
      warn: () => {},
      error: () => {},
      ...overrides.debugHelper
    },
    ...overrides
  };
}

/**
 * Create mock learning path manager
 * @param {Object} overrides - Override default implementation
 * @returns {Object} Mock learning path manager
 */
export function mockLearningPathManager(overrides = {}) {
  return {
    getKataProgress: () => ({}),
    getUserLevel: () => 'Beginner',
    updatePathSelections: () => {},
    getAllPaths: () => Object.values(PATH_RELATIONSHIPS),
    getSelectedPaths: () => [],
    getConfig: () => ({ autoSelection: { enabled: true } }),
    ...overrides
  };
}
