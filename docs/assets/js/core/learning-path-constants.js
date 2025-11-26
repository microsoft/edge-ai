/**
 * Central configuration for learning path system
 * Single source of truth for all path-related constants
 */
export const LEARNING_PATH_CONSTANTS = {
  // Standard skill levels (aligned with server schemas)
  SKILL_LEVELS: {
    BEGINNER: 'beginner',
    INTERMEDIATE: 'intermediate',
    ADVANCED: 'advanced',
    EXPERT: 'expert'
  },

  // Difficulty levels (alias for SKILL_LEVELS for path mapping)
  DIFFICULTY: {
    BEGINNER: 'beginner',
    INTERMEDIATE: 'intermediate',
    ADVANCED: 'advanced',
    EXPERT: 'expert'
  },

  // Mappings for legacy compatibility
  LEGACY_MAPPINGS: {
    // Old 3-level system (DIFFICULTY)
    'foundation': 'beginner',
    'intermediate': 'intermediate',
    'expert': 'expert',

    // Old 4-level system (SKILL_LEVELS)
    'novice': 'beginner',
    'competent': 'intermediate',
    'proficient': 'advanced',

    // Old path names
    'foundation-builder': 'beginner',
    'skill-developer': 'intermediate',
    'expert-practitioner': 'expert'
  },

  // Default learning paths by level
  DEFAULT_PATHS: {
    beginner: ['foundation-ai-first-engineering'],
    intermediate: ['intermediate-devops-excellence', 'intermediate-infrastructure-architect'],
    advanced: ['expert-data-analytics-integration'],
    expert: ['expert-enterprise-integration']
  },

  // Score thresholds for level determination (1-5 scale)
  SCORE_THRESHOLDS: {
    beginner: { min: 1.0, max: 2.0 },
    intermediate: { min: 2.0, max: 3.5 },
    advanced: { min: 3.5, max: 4.5 },
    expert: { min: 4.5, max: 5.0 }
  },

  // Recommendation rules for path type determination
  RECOMMENDATION_RULES: {
    foundation: {
      minNovice: 3,
      minNoviceAndCompetent: 5
    },
    intermediate: {
      minProficient: 2,
      minCompetent: 4
    }
  }
};

// Freeze to prevent modifications
Object.freeze(LEARNING_PATH_CONSTANTS.SKILL_LEVELS);
Object.freeze(LEARNING_PATH_CONSTANTS.DIFFICULTY);
Object.freeze(LEARNING_PATH_CONSTANTS.LEGACY_MAPPINGS);
Object.freeze(LEARNING_PATH_CONSTANTS.DEFAULT_PATHS);
Object.freeze(LEARNING_PATH_CONSTANTS.SCORE_THRESHOLDS);
Object.freeze(LEARNING_PATH_CONSTANTS.RECOMMENDATION_RULES);
Object.freeze(LEARNING_PATH_CONSTANTS);
