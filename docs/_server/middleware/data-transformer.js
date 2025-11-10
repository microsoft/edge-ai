/**
 * Data Transformer Middleware
 * Transforms different data formats to match expected schema structures
 */

/**
 * Transform simple API format to full schema format
 * @param {Object} data - Input data in simple format
 * @returns {Object} Transformed data in full schema format
 */
function transformSimpleApiFormat(data) {
  // NEW: Handle frontend skill-assessment incomplete format
  // This catches payloads from the frontend that are missing required fields
  if (data.type === 'self-assessment' &&
      data.metadata &&
      !data.metadata.version) {
    console.log('[DataTransformer] Detected incomplete self-assessment format from frontend, transforming...');

    // Extract what we have
    const existingMetadata = data.metadata || {};
    const existingQuestions = data.assessment?.questions || [];
    const existingResults = data.assessment?.results || {};

    // If questions are incomplete, extract responses
    const responses = {};
    existingQuestions.forEach((q, index) => {
      const questionId = q.id || `question_${index + 1}`;
      responses[questionId] = q.response;
    });

    // Transform using existing logic
    return transformSelfAssessmentData({
      assessmentId: existingMetadata.assessmentId,
      assessmentTitle: existingMetadata.assessmentTitle || existingMetadata.title,
      responses: responses,
      timestamp: data.timestamp,
      sessionId: existingMetadata.sessionId,
      userId: existingMetadata.userId,
      pageUrl: existingMetadata.pageUrl,
      coachMode: existingMetadata.coachMode
    });
  }

  // Handle the simple format: { type: "self-assessment", data: {...} }
  if (data.type && data.data && typeof data.data === 'object') {
    const { type, data: payload } = data;

    switch (type) {
      case 'self-assessment':
        return transformSelfAssessmentData(payload);
      case 'kata':
      case 'kata-progress':
        return transformKataProgressData(payload);
      case 'lab':
      case 'lab-progress':
        return transformLabProgressData(payload);
      case 'path':
      case 'path-progress':
        // Path progress uses same structure as kata/lab
        return payload;
      default:
        throw new Error(`Unsupported progress type: ${type}`);
    }
  }

  // Handle kata progress UI format: { kataId: "...", progress: {...}, timestamp: "..." }
  if (data.kataId && data.progress && typeof data.progress === 'object') {
    return transformKataProgressData(data);
  }

  // If it's already in full format, strip frontend-specific fields and return
  const cleanData = { ...data };

  // Remove fields added by frontend/SyncManager that aren't part of the schema
  delete cleanData.type; // Type field is metadata, not part of file schema
  delete cleanData.updateSource;
  delete cleanData.serverTimestamp;

  // Remove duplicate/incorrect title field - schema uses kataTitle/labTitle instead
  if (cleanData.metadata && cleanData.metadata.title) {
    delete cleanData.metadata.title;
  }

  return cleanData;
}

/**
 * Transform simple self-assessment data to full schema format
 * @param {Object} payload - Simple self-assessment data
 * @returns {Object} Full schema format
 */
function transformSelfAssessmentData(payload) {
  const now = new Date().toISOString();
  const assessmentId = payload.assessmentId || 'skill-assessment';

  // Ensure assessmentId matches the expected pattern
  const formattedAssessmentId = assessmentId.endsWith('-assessment')
    ? assessmentId
    : `${assessmentId}-assessment`;

  return {
    metadata: {
      version: '1.0.0',
      assessmentId: formattedAssessmentId,
      assessmentTitle: payload.assessmentTitle || 'Skill Assessment',
      assessmentType: 'skill-assessment',
      source: 'ui',
      fileType: 'self-assessment',
      sessionId: payload.sessionId || `assessment-session-${Date.now()}`,
      userId: payload.userId || 'anonymous',
  pageUrl: payload.pageUrl || '/learning/skill-assessment.md',
      coachMode: payload.coachMode || 'self-directed',
      lastUpdated: now
    },
    timestamp: payload.timestamp || now,
    assessment: {
      questions: transformQuestions(payload.responses || {}),
      results: calculateResults(payload.responses || {}),
      completionData: {
        isComplete: payload.completed || false,
        completedAt: payload.completed ? (payload.timestamp || now) : null,
        duration: payload.duration || 0,
        questionsAnswered: Object.keys(payload.responses || {}).length,
        totalQuestions: Object.keys(payload.responses || {}).length
      }
    }
  };
}

/**
 * Transform simple kata progress data to full schema format
 * @param {Object} payload - Simple kata progress data
 * @returns {Object} Full schema format
 */
function transformKataProgressData(payload) {
  const now = new Date().toISOString();
  const kataId = payload.kataId || 'unknown-kata';

  // Extract progress data from UI format
  const progressData = payload.progress || {};
  const checkboxStates = progressData.checkboxStates || {};
  const completedTasks = progressData.completed || 0;
  const totalTasks = progressData.total || 0;
  const completionPercentage = progressData.percentage || 0;

  return {
    metadata: {
      version: '1.0.0',
      kataId: kataId,
      kataTitle: payload.kataTitle || 'Unknown Kata',
      source: 'ui',
      fileType: 'kata-progress',
      sessionId: payload.sessionId || `kata-session-${Date.now()}`,
      userId: payload.userId || 'anonymous',
      lastUpdated: now
    },
    timestamp: payload.timestamp || now,
    progress: {
      checkboxStates: checkboxStates,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      completionPercentage: completionPercentage,
      currentStep: payload.currentStep || Object.keys(checkboxStates).find(key => !checkboxStates[key]) || null
    }
  };
}

/**
 * Transform simple lab progress data to full schema format
 * @param {Object} payload - Simple lab progress data
 * @returns {Object} Full schema format
 */
function transformLabProgressData(payload) {
  const now = new Date().toISOString();
  const labId = payload.labId || 'unknown-lab';

  return {
    metadata: {
      version: '1.0.0',
      labId: labId,
      labTitle: payload.labTitle || 'Unknown Lab',
      source: 'ui',
      fileType: 'lab-progress',
      sessionId: payload.sessionId || `lab-session-${Date.now()}`,
      userId: payload.userId || 'anonymous',
      lastUpdated: now
    },
    timestamp: payload.timestamp || now,
    progress: {
      currentStep: payload.currentStep || 0,
      totalSteps: payload.totalSteps || 0,
      completed: payload.completed || false,
      completedAt: payload.completed ? (payload.timestamp || now) : null
    }
  };
}

/**
 * Transform simple responses to full question format
 * @param {Object} responses - Simple responses object
 * @returns {Array} Array of question objects
 */
function transformQuestions(responses) {
  const now = new Date().toISOString();
  const categories = ['ai-assisted-engineering', 'prompt-engineering', 'edge-deployment', 'system-troubleshooting'];

  return Object.entries(responses).map(([questionId, response], index) => {
    const category = categories[index % categories.length];
    const responseValue = typeof response === 'string' ? convertResponseToNumber(response) : response;

    return {
      id: questionId,
      question: `Question ${questionId}`,
      category,
      response: responseValue,
      responseText: getResponseText(responseValue),
      timestamp: now
    };
  });
}

/**
 * Convert text response to numeric value
 * @param {string} response - Text response
 * @returns {number} Numeric value (1-5)
 */
function convertResponseToNumber(response) {
  const lowerResponse = response.toLowerCase();
  if (lowerResponse.includes('beginner') || lowerResponse.includes('novice')) {return 1;}
  if (lowerResponse.includes('basic') || lowerResponse.includes('learning')) {return 2;}
  if (lowerResponse.includes('intermediate') || lowerResponse.includes('competent')) {return 3;}
  if (lowerResponse.includes('advanced') || lowerResponse.includes('skilled')) {return 4;}
  if (lowerResponse.includes('expert') || lowerResponse.includes('master')) {return 5;}

  // Try to parse as number
  const numValue = parseInt(response);
  return isNaN(numValue) ? 3 : Math.max(1, Math.min(5, numValue));
}

/**
 * Get response text for numeric value
 * @param {number} value - Numeric value (1-5)
 * @returns {string} Response text
 */
function getResponseText(value) {
  switch (value) {
    case 1: return 'Beginner - Just getting started';
    case 2: return 'Basic - Some experience';
    case 3: return 'Intermediate - Comfortable with basics';
    case 4: return 'Advanced - Skilled and confident';
    case 5: return 'Expert - Deep expertise';
    default: return 'Intermediate - Comfortable with basics';
  }
}

/**
 * Calculate assessment results from responses
 * @param {Object} responses - Simple responses object
 * @returns {Object} Results object
 */
function calculateResults(responses) {
  const questions = transformQuestions(responses);
  const categories = ['ai-assisted-engineering', 'prompt-engineering', 'edge-deployment', 'system-troubleshooting'];

  // Calculate category scores
  const categoryScores = {};
  categories.forEach(category => {
    const categoryQuestions = questions.filter(q => q.category === category);
    const totalScore = categoryQuestions.reduce((sum, q) => sum + q.response, 0);
    const avgScore = categoryQuestions.length > 0 ? totalScore / categoryQuestions.length : 3;

    categoryScores[category] = {
      score: Math.round(avgScore * 100) / 100,
      level: avgScore >= 4 ? 'advanced' : avgScore >= 3 ? 'intermediate' : 'beginner',
      questionsCount: categoryQuestions.length,
      totalPoints: totalScore,
      maxPoints: categoryQuestions.length * 5
    };
  });

  // Calculate overall score
  const allScores = Object.values(categoryScores).map(cat => cat.score);
  const overallScore = allScores.reduce((sum, score) => sum + score, 0) / allScores.length;

  return {
    categoryScores,
    overallScore: Math.round(overallScore * 100) / 100,
    overallLevel: overallScore >= 4 ? 'advanced' : overallScore >= 3 ? 'intermediate' : 'beginner',
    strengthCategories: categories.filter(cat => categoryScores[cat].level === 'advanced'),
    growthCategories: categories.filter(cat => categoryScores[cat].level === 'beginner'),
    recommendedPath: overallScore >= 4 ? 'expert' : overallScore >= 3 ? 'intermediate' : 'foundation'
  };
}

/**
 * Express middleware to transform data format
 * @param {Object} options - Transformation options
 * @returns {Function} Express middleware function
 */
function dataTransformer(options = {}) {
  const { autoTransform = true } = options;

  return (req, res, next) => {
    if (autoTransform && req.body) {
      try {
        req.body = transformSimpleApiFormat(req.body);
      } catch (error) {
        return res.status(400).json({
          success: false,
          error: 'Data transformation failed',
          details: error.message
        });
      }
    }

    next();
  };
}

export {
  transformSimpleApiFormat,
  transformSelfAssessmentData,
  transformKataProgressData,
  transformLabProgressData,
  dataTransformer
};
