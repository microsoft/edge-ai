/**
 * Test Data Fixtures for Learning Paths
 * Provides standardized test data for learning path components
 *
 * @module LearningPathData
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * Sample learning path data for testing
 */
export const SAMPLE_LEARNING_PATHS = {
  foundationAI: {
    id: 'foundation-ai-engineering',
    title: 'Foundation Builder - AI Engineering',
    level: 'Beginner',
    skills: ['AI-Assisted Engineering', 'Prompt Engineering'],
    items: [
      {
        id: 'ai-dev-fundamentals',
        kataId: 'ai-assisted-engineering/01-ai-development-fundamentals',
        title: 'AI Development Fundamentals',
        estimatedTime: 45,
        type: 'Foundation',
        prerequisites: []
      },
      {
        id: 'prompt-basics',
        kataId: 'prompt-engineering/01-prompt-engineering-basics',
        title: 'Prompt Engineering Basics',
        estimatedTime: 60,
        type: 'Core Skill',
        prerequisites: ['ai-dev-fundamentals']
      },
      {
        id: 'ai-code-review',
        kataId: 'ai-assisted-engineering/02-ai-code-review-techniques',
        title: 'AI Code Review Techniques',
        estimatedTime: 30,
        type: 'Application',
        prerequisites: ['ai-dev-fundamentals']
      }
    ]
  },

  expertAI: {
    id: 'expert-ai-architecture',
    title: 'Expert Practitioner - AI Architecture',
    level: 'Advanced',
    skills: ['AI-Assisted Engineering', 'ADR Creation', 'Task Planning'],
    items: [
      {
        id: 'ai-system-architecture',
        kataId: 'ai-assisted-engineering/04-ai-system-architecture',
        title: 'AI System Architecture',
        estimatedTime: 90,
        type: 'Architecture Foundation',
        prerequisites: []
      },
      {
        id: 'ai-decision-documentation',
        kataId: 'adr-creation/01-ai-decision-documentation',
        title: 'AI Decision Documentation',
        estimatedTime: 45,
        type: 'Decision Framework',
        prerequisites: ['ai-system-architecture']
      }
    ]
  }
};

/**
 * Sample progress data for testing
 */
export const SAMPLE_PROGRESS_DATA = {
  completed: {
    'ai-assisted-engineering/01-ai-development-fundamentals': {
      completed: true,
      completedAt: '2025-08-15T10:00:00Z',
      timeSpent: 45,
      score: 95
    },
    'prompt-engineering/01-prompt-engineering-basics': {
      completed: true,
      completedAt: '2025-08-16T14:30:00Z',
      timeSpent: 55,
      score: 88
    }
  },

  inProgress: {
    'ai-assisted-engineering/02-ai-code-review-techniques': {
      completed: false,
      startedAt: '2025-08-17T09:15:00Z',
      progress: 0.4,
      timeSpent: 15
    }
  },

  selected: {
    'project-planning/01-basic-prompt-usage': {
      selected: true,
      selectedAt: '2025-08-17T08:00:00Z',
      fromAssessment: true
    },
    'project-planning/02-comprehensive-two-scenario': {
      selected: true,
      selectedAt: '2025-08-17T08:00:00Z',
      fromAssessment: true
    }
  }
};

/**
 * Sample assessment recommendations for testing
 */
export const SAMPLE_ASSESSMENT_RECOMMENDATIONS = {
  beginner: {
    level: 'Beginner',
    role: 'Developer',
    interests: ['AI Development', 'Automation'],
    recommendations: [
      {
        pathId: 'foundation-ai-first-engineering',
        priority: 1,
        reason: 'Strong foundation in AI development needed'
      },
      {
        pathId: 'intermediate-infrastructure-architect',
        priority: 2,
        reason: 'Project organization skills complement technical skills'
      }
    ]
  },

  intermediate: {
    level: 'Intermediate',
    role: 'Senior Developer',
    interests: ['System Architecture', 'AI Integration'],
    recommendations: [
      {
        pathId: 'intermediate-devops-excellence',
        priority: 1,
        reason: 'Advanced DevOps skills for complex integrations'
      },
      {
        pathId: 'intermediate-infrastructure-architect',
        priority: 2,
        reason: 'System architecture expertise needed'
      }
    ]
  },

  expert: {
    level: 'Advanced',
    role: 'Architect',
    interests: ['AI Architecture', 'Technical Leadership'],
    recommendations: [
      {
        pathId: 'expert-enterprise-integration',
        priority: 1,
        reason: 'Leadership role requires comprehensive AI architecture skills'
      },
      {
        pathId: 'expert-data-analytics-integration',
        priority: 2,
        reason: 'Multi-disciplinary expertise for complex solutions'
      }
    ]
  }
};

/**
 * Sample path relationship data for auto-selection testing
 */
export const SAMPLE_PATH_RELATIONSHIPS = {
  'foundation-ai-engineering': {
    autoSelectItems: [
      'ai-assisted-engineering/01-ai-development-fundamentals',
      'prompt-engineering/01-prompt-engineering-basics',
      'ai-assisted-engineering/02-ai-code-review-techniques'
    ],
    dependencies: [],
    conflicts: [],
    relatedPaths: ['intermediate-infrastructure-architect']
  },

  'intermediate-infrastructure-architect': {
    autoSelectItems: [
      'project-planning/01-basic-prompt-usage',
      'project-planning/02-comprehensive-two-scenario'
    ],
    dependencies: [],
    conflicts: [],
    relatedPaths: ['foundation-ai-engineering']
  },

  'expert-ai-architecture': {
    autoSelectItems: [
      'ai-assisted-engineering/04-ai-system-architecture',
      'adr-creation/01-ai-decision-documentation',
      'task-planning/02-ai-driven-planning'
    ],
    dependencies: ['foundation-ai-engineering'],
    conflicts: [],
    relatedPaths: ['expert-full-stack-integration']
  }
};

/**
 * Sample state data for testing
 */
export const SAMPLE_STATE_DATA = {
  initial: {
    selectedPaths: [],
    completedKatas: [],
    inProgressKatas: [],
    assessmentCompleted: false
  },

  withSelections: {
    selectedPaths: ['foundation-ai-engineering'],
    completedKatas: ['ai-assisted-engineering/01-ai-development-fundamentals'],
    inProgressKatas: ['prompt-engineering/01-prompt-engineering-basics'],
    assessmentCompleted: true
  },

  multiPath: {
    selectedPaths: ['foundation-ai-first-engineering', 'intermediate-infrastructure-architect'],
    completedKatas: [
      'ai-assisted-engineering/01-ai-development-fundamentals',
      'project-planning/01-basic-prompt-usage'
    ],
    inProgressKatas: [
      'prompt-engineering/01-prompt-engineering-basics',
      'edge-deployment/01-edge-computing-fundamentals'
    ],
    assessmentCompleted: true
  }
};

/**
 * Sample error scenarios for testing
 */
export const SAMPLE_ERROR_SCENARIOS = {
  missingKataId: {
    html: `
      <div class="learning-paths-container">
        <ul class="task-list">
          <li class="task-list-item">
            <input type="checkbox" id="missing-kata-id">
            <label for="missing-kata-id">Missing Kata ID</label>
          </li>
        </ul>
      </div>
    `
  },

  invalidKataId: {
    html: `
      <div class="learning-paths-container">
        <ul class="task-list">
          <li class="task-list-item">
            <input type="checkbox" id="invalid-kata" data-kata-id="invalid/kata/path">
            <label for="invalid-kata">Invalid Kata</label>
          </li>
        </ul>
      </div>
    `
  },

  malformedStructure: {
    html: `
      <div class="learning-paths-container">
        <input type="checkbox" id="orphan-checkbox" data-kata-id="orphan/kata">
        <label>Orphan Label</label>
      </div>
    `
  }
};

/**
 * Helper function to create test data with custom overrides
 * @param {string} baseDataKey - Key from SAMPLE_* constants
 * @param {Object} overrides - Custom data to override defaults
 * @returns {Object} Merged test data
 */
export function createTestData(baseDataKey, overrides = {}) {
  const baseData = {
    learningPaths: SAMPLE_LEARNING_PATHS,
    progressData: SAMPLE_PROGRESS_DATA,
    assessmentRecommendations: SAMPLE_ASSESSMENT_RECOMMENDATIONS,
    pathRelationships: SAMPLE_PATH_RELATIONSHIPS,
    stateData: SAMPLE_STATE_DATA,
    errorScenarios: SAMPLE_ERROR_SCENARIOS
  };

  const selectedBase = baseData[baseDataKey] || {};
  return { ...selectedBase, ...overrides };
}

/**
 * Get all kata IDs from learning paths for testing
 * @returns {Array} Array of all kata IDs
 */
export function getAllKataIds() {
  const allIds = [];
  Object.values(SAMPLE_LEARNING_PATHS).forEach(path => {
    path.items.forEach(item => {
      allIds.push(item.kataId);
    });
  });
  return allIds;
}

/**
 * Get kata IDs for a specific path
 * @param {string} pathId - Learning path ID
 * @returns {Array} Array of kata IDs for the path
 */
export function getKataIdsForPath(pathId) {
  const path = SAMPLE_LEARNING_PATHS[pathId];
  return path ? path.items.map(item => item.kataId) : [];
}
