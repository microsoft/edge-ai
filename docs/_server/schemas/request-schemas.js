/**
 * Request Validation Schemas
 * Defines validation schemas for all API endpoints
 */

export const progressDataSchema = {
  type: 'object',
  required: ['metadata', 'timestamp'], // type is optional - can be detected from structure
  properties: {
    type: {
      type: 'string',
      enum: ['self-assessment', 'kata-progress', 'lab-progress']
    },
    metadata: {
      type: 'object',
      required: [], // title is optional - kata uses kataTitle, lab uses labId, etc.
      properties: {
        title: {
          type: 'string',
          minLength: 1,
          maxLength: 200,
          pattern: '^[a-zA-Z0-9\\s._()-]+$'
        },
        assessmentId: {
          type: 'string',
          pattern: '^[a-z0-9-]+$',
          minLength: 1,
          maxLength: 100
        },
        kataId: {
          type: 'string',
          pattern: '^[a-z0-9-]+$',
          minLength: 1,
          maxLength: 100
        },
        labId: {
          type: 'string',
          pattern: '^[a-z0-9-]+-[a-z0-9-]+$',
          minLength: 1,
          maxLength: 100
        },
        category: {
          type: 'string',
          enum: ['ai-assisted-engineering', 'prompt-engineering', 'edge-deployment', 'system-troubleshooting', 'task-planning', 'adr-creation'],
          description: 'Progress category for grouping and filtering'
        }
      },
      additionalProperties: false
    },
    assessment: {
      type: 'object',
      properties: {
        categories: {
          type: 'array',
          items: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            pattern: '^[a-zA-Z0-9\\s_-]+$'
          },
          maxItems: 50
        },
        completedTasks: {
          type: 'array',
          items: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            pattern: '^[a-zA-Z0-9\\s_.()-]+$'
          },
          maxItems: 200
        },
        questions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string', minLength: 1, maxLength: 100 },
              question: { type: 'string', minLength: 1, maxLength: 500 },
              category: { type: 'string', minLength: 1, maxLength: 100 },
              response: { type: 'integer', minimum: 1, maximum: 5 },
              responseText: { type: 'string', minLength: 1, maxLength: 100 },
              timestamp: { type: 'string', format: 'date-time' }
            },
            additionalProperties: false
          },
          maxItems: 100
        },
        results: {
          type: 'object',
          properties: {
            categoryScores: {
              type: 'object',
              additionalProperties: {
                type: 'object',
                properties: {
                  score: { type: 'number', minimum: 0, maximum: 5 },
                  level: { type: 'string', minLength: 1, maxLength: 50 },
                  questionsCount: { type: 'integer', minimum: 0, maximum: 100 },
                  totalPoints: { type: 'integer', minimum: 0, maximum: 500 },
                  maxPoints: { type: 'integer', minimum: 0, maximum: 500 }
                },
                additionalProperties: false
              }
            },
            overallScore: { type: 'number', minimum: 0, maximum: 5 },
            overallLevel: { type: 'string', minLength: 1, maxLength: 50 },
            strengthCategories: {
              type: 'array',
              items: { type: 'string', minLength: 1, maxLength: 100 },
              maxItems: 20
            },
            growthCategories: {
              type: 'array',
              items: { type: 'string', minLength: 1, maxLength: 100 },
              maxItems: 20
            },
            recommendedPath: { type: 'string', minLength: 1, maxLength: 100 }
          },
          additionalProperties: false
        }
      },
      additionalProperties: false
    },
    progress: {
      type: 'object',
      properties: {
        currentStep: {
          oneOf: [
            {
              type: 'integer',
              minimum: 0,
              maximum: 1000
            },
            {
              type: 'string',
              minLength: 1,
              maxLength: 200,
              pattern: '^[a-zA-Z0-9_-]+$'
            }
          ]
        },
        completedSteps: {
          type: 'array',
          items: {
            type: 'integer',
            minimum: 0,
            maximum: 1000
          },
          maxItems: 1000
        },
        checkboxStates: {
          type: 'object',
          patternProperties: {
            '^[a-zA-Z0-9_-]+$': {
              type: 'boolean'
            }
          },
          additionalProperties: false
        },
        // Lab-progress specific fields
        sessions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              sessionId: { type: 'string', minLength: 1, maxLength: 100 },
              startTime: { type: 'string', format: 'date-time' },
              endTime: { type: 'string', format: 'date-time' },
              duration: { type: 'integer', minimum: 0 },
              checkboxStates: {
                type: 'object',
                patternProperties: {
                  '^[a-zA-Z0-9_-]+$': {
                    type: 'boolean'
                  }
                },
                additionalProperties: false
              },
              sessionNotes: { type: 'string', maxLength: 1000 },
              blockers: {
                type: 'array',
                items: { type: 'string', maxLength: 200 },
                maxItems: 50
              },
              achievements: {
                type: 'array',
                items: { type: 'string', maxLength: 200 },
                maxItems: 50
              }
            },
            additionalProperties: false
          },
          maxItems: 100
        },
        overallProgress: {
          type: 'object',
          properties: {
            completedTasks: { type: 'integer', minimum: 0, maximum: 10000 },
            totalTasks: { type: 'integer', minimum: 0, maximum: 10000 },
            completionPercentage: { type: 'number', minimum: 0, maximum: 100 },
            currentPhase: { type: 'string', minLength: 1, maxLength: 100 },
            estimatedTimeRemaining: { type: 'integer', minimum: 0, maximum: 100000 }
          },
          additionalProperties: false
        }
      },
      additionalProperties: false
    },
    timestamp: {
      type: 'string',
      format: 'date-time'
    },
    updateSource: {
      type: 'string',
      description: 'Source of the update (from frontend SyncManager)'
    },
    serverTimestamp: {
      type: 'number',
      description: 'Server timestamp (from frontend SyncManager)'
    }
  },
  additionalProperties: false
};

export const parameterSchemas = {
  progressType: {
    type: 'string',
    enum: ['self-assessment', 'kata-progress', 'lab-progress', 'kata', 'path', 'lab']
  },
  progressId: {
    type: 'string',
    pattern: '^[a-zA-Z0-9_-]+$',
    minLength: 1,
    maxLength: 100
  },
  genericId: {
    type: 'string',
    pattern: '^[a-zA-Z0-9_-]+$',
    minLength: 1,
    maxLength: 100
  }
};

export const querySchemas = {
  limit: {
    type: 'string',
    pattern: '^[0-9]+$'
  },
  type: {
    type: 'string',
    enum: ['self-assessment', 'kata-progress', 'lab-progress', 'kata', 'path', 'lab']
  },
  history: {
    type: 'string',
    pattern: '^[0-9]+$'
  },
  heartbeat: {
    type: 'string',
    pattern: '^(true|false)$'
  }
};

// Dangerous patterns that should be rejected
export const securityPatterns = {
  scriptTags: /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
  htmlTags: /<[^>]*>/g,
  sqlInjection: /['";]|--|\*\/|\/\*/gi,
  commandInjection: /[;&|`$()\\]/g,
  pathTraversal: /\.\.[/\\]/g,
  nullBytes: new RegExp(String.fromCharCode(0), 'g'),
  controlChars: new RegExp(`[${String.fromCharCode(0)}-${String.fromCharCode(31)}${String.fromCharCode(127)}-${String.fromCharCode(159)}]`, 'g')
};

// Maximum lengths for different field types
export const fieldLimits = {
  shortString: 100,
  mediumString: 500,
  longString: 2000,
  array: 100,
  largeArray: 1000
};
