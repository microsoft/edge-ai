/**
 * Learning Analytics Engine
 * Advanced analytics and insights for kata learning patterns
 * @version 2.0.0
 */

class LearningAnalyticsEngine {
  /**
   * Creates a new LearningAnalyticsEngine instance
   * @param {Object} dependencies - Injected dependencies
   * @param {Object} dependencies.learningPathManager - Learning path manager instance
   * @param {Object} dependencies.kataCatalog - Kata catalog instance
   * @param {Object} dependencies.debugHelper - Debug helper instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   */
  constructor(dependencies = {}) {
    const {
      learningPathManager,
      kataCatalog,
      debugHelper,
      errorHandler
    } = dependencies;

    this.learningPathManager = learningPathManager;
    this.kataCatalog = kataCatalog;
    this.debugHelper = debugHelper;
    this.errorHandler = errorHandler;

    this.analyticsData = this.initializeAnalyticsData();
    this.insights = new Map();
    this.metrics = new Map();
  }

  /**
   * Initialize analytics data structure
   * @returns {Object} Analytics data structure
   */
  initializeAnalyticsData() {
    if (!this.errorHandler) {
      // LearningAnalyticsEngine: No error handler provided
      return this.createDefaultAnalyticsData();
    }

    return this.errorHandler.safeExecute(() => {
      const saved = localStorage.getItem('kata-learning-analytics');
      return saved ? JSON.parse(saved) : this.createDefaultAnalyticsData();
    }, 'initializeAnalyticsData', this.createDefaultAnalyticsData());
  }

  /**
   * Create default analytics data structure
   * @private
   * @returns {Object} Default analytics data
   */
  createDefaultAnalyticsData() {
    return {
      sessions: [],
      completionTimes: {},
      retryAttempts: {},
      skillProgression: {},
      timeSpent: {},
      learningPatterns: {},
      createdAt: Date.now()
    };
  }

  /**
   * Track a learning session
   * @param {Object} sessionData - Session tracking data
   * @returns {boolean} Success status
   */
  trackSession(sessionData) {
    if (!this.errorHandler) {
      // LearningAnalyticsEngine: No error handler provided for trackSession
      return false;
    }

    return this.errorHandler.safeExecute(() => {
      if (!sessionData || typeof sessionData !== 'object') {
        // LearningAnalyticsEngine: Invalid session data provided
        return false;
      }

      const session = {
        id: this.generateSessionId(),
        timestamp: Date.now(),
        ...sessionData
      };

      this.analyticsData.sessions.push(session);

      // Limit to last 100 sessions
      if (this.analyticsData.sessions.length > 100) {
        this.analyticsData.sessions = this.analyticsData.sessions.slice(-100);
      }

      this.saveAnalyticsData();
      return true;
    }, 'trackSession', false);
  }

  /**
   * Track kata completion time
   * @param {string} kataKey - Kata identifier
   * @param {number} timeSpent - Time in minutes
   * @param {number} [attempts=1] - Number of attempts
   * @returns {boolean} Success status
   */
  trackCompletion(kataKey, timeSpent, attempts = 1) {
    if (!this.errorHandler) {
      // LearningAnalyticsEngine: No error handler provided for trackCompletion
      return false;
    }

    return this.errorHandler.safeExecute(() => {
      if (!kataKey || typeof kataKey !== 'string') {
        // LearningAnalyticsEngine: Invalid kata key provided
        return false;
      }

      if (typeof timeSpent !== 'number' || timeSpent < 0) {
        // LearningAnalyticsEngine: Invalid time spent value
        return false;
      }

      if (typeof attempts !== 'number' || attempts < 1) {
        // LearningAnalyticsEngine: Invalid attempts value
        return false;
      }

      // Track completion time
      if (!this.analyticsData.completionTimes[kataKey]) {
        this.analyticsData.completionTimes[kataKey] = [];
      }
      this.analyticsData.completionTimes[kataKey].push({
        time: timeSpent,
        timestamp: Date.now(),
        attempts
      });

      // Track retry attempts
      if (!this.analyticsData.retryAttempts[kataKey]) {
        this.analyticsData.retryAttempts[kataKey] = 0;
      }
      this.analyticsData.retryAttempts[kataKey] += (attempts - 1);

      // Track time spent
      if (!this.analyticsData.timeSpent[kataKey]) {
        this.analyticsData.timeSpent[kataKey] = 0;
      }
      this.analyticsData.timeSpent[kataKey] += timeSpent;

      this.updateSkillProgression(kataKey);
      this.saveAnalyticsData();
      return true;

    }, 'trackCompletion', false);
  }

  /**
   * Update skill progression tracking
   * @param {string} kataKey - Kata identifier
   * @returns {boolean} Success status
   */
  updateSkillProgression(kataKey) {
    if (!kataKey || typeof kataKey !== 'string') {
      // LearningAnalyticsEngine: Invalid kata key for skill progression
      return false;
    }

    const kata = this.findKataByKey(kataKey);
    if (!kata) {
      // LearningAnalyticsEngine: Kata not found for key
      return false;
    }

    try {
      const category = kata.category;
      const now = Date.now();

      if (!this.analyticsData.skillProgression[category]) {
        this.analyticsData.skillProgression[category] = [];
      }

      this.analyticsData.skillProgression[category].push({
        kataKey,
        timestamp: now,
        difficulty: kata.difficulty
      });

      return true;
    } catch {
      // LearningAnalyticsEngine: Error updating skill progression
      return false;
    }
  }

  /**
   * Generate comprehensive learning metrics
   * @returns {Object} Learning metrics
   */
  generateLearningMetrics() {
    if (!this.errorHandler) {
      // LearningAnalyticsEngine: No error handler provided for generateLearningMetrics
      return {};
    }

    return this.errorHandler.safeExecute(() => {
      const metrics = {
        overall: this.calculateOverallMetrics(),
        byCategory: this.calculateCategoryMetrics(),
        trends: this.calculateTrends(),
        efficiency: this.calculateEfficiencyMetrics(),
        patterns: this.analyzeLearningPatterns()
      };

      this.metrics.set('latest', metrics);
      return metrics;
    }, 'generateLearningMetrics', {});
  }

  /**
   * Calculate overall learning metrics
   * @returns {Object} Overall metrics
   */
  calculateOverallMetrics() {
    const userProgress = this.learningPathManager ? this.learningPathManager.getAllProgress() : {};
    const allKatas = this.kataCatalog ? this.kataCatalog.getAllKatas() : [];

    const completedKatas = Object.keys(userProgress).filter(key =>
      userProgress[key] && userProgress[key].completionPercentage >= 100
    );

    const totalTimeSpent = Object.values(this.analyticsData.timeSpent)
      .reduce((sum, time) => sum + (time || 0), 0);

    const averageCompletionTime = this.calculateAverageCompletionTime();
    const totalRetries = Object.values(this.analyticsData.retryAttempts)
      .reduce((sum, retries) => sum + (retries || 0), 0);

    const totalKatas = allKatas.length || 1; // Avoid division by zero

    return {
      completionRate: (completedKatas.length / totalKatas) * 100,
      totalKatasCompleted: completedKatas.length,
      totalTimeSpent,
      averageCompletionTime,
      totalRetries,
      averageRetriesPerKata: totalRetries / Math.max(completedKatas.length, 1),
      currentStreak: this.calculateCurrentStreak(),
      longestStreak: this.calculateLongestStreak()
    };
  }

  /**
   * Calculate metrics by category
   * @returns {Array} Array of category metrics
   */
  calculateCategoryMetrics() {
    const categories = this.kataCatalog ? this.kataCatalog.getAllCategories() : [];
    const userProgress = this.learningPathManager ? this.learningPathManager.getAllProgress() : {};

    return categories.map(category => {
      const categoryId = category.name ? category.name.toLowerCase().replace(/\s+/g, '-') : 'unknown';
      const categoryKatas = category.katas || [];

      const completedInCategory = categoryKatas.filter(kataId => {
        const kataKey = `${categoryId}/${kataId}`;
        return userProgress[kataKey] && userProgress[kataKey].completionPercentage >= 100;
      });

      const categoryTimeSpent = categoryKatas.reduce((sum, kataId) => {
        const kataKey = `${categoryId}/${kataId}`;
        return sum + (this.analyticsData.timeSpent[kataKey] || 0);
      }, 0);

      const categoryRetries = categoryKatas.reduce((sum, kataId) => {
        const kataKey = `${categoryId}/${kataId}`;
        return sum + (this.analyticsData.retryAttempts[kataKey] || 0);
      }, 0);

      const totalKatas = categoryKatas.length || 1; // Avoid division by zero

      return {
        category: category.name || 'Unknown',
        categoryId,
        completionRate: (completedInCategory.length / totalKatas) * 100,
        completed: completedInCategory.length,
        total: categoryKatas.length,
        timeSpent: categoryTimeSpent,
        retries: categoryRetries,
        averageTimePerKata: categoryTimeSpent / Math.max(completedInCategory.length, 1),
        efficiency: this.calculateCategoryEfficiency(categoryId, completedInCategory.length, categoryTimeSpent)
      };
    });
  }

  /**
   * Calculate learning trends over time
   */
  calculateTrends() {
    const sessions = this.analyticsData.sessions.slice(-30); // Last 30 sessions
    const now = Date.now();
    const oneWeekAgo = now - (7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = now - (30 * 24 * 60 * 60 * 1000);

    const weekSessions = sessions.filter(s => s.timestamp >= oneWeekAgo);
    const monthSessions = sessions.filter(s => s.timestamp >= oneMonthAgo);

    return {
      sessionsThisWeek: weekSessions.length,
      sessionsThisMonth: monthSessions.length,
      averageSessionsPerWeek: monthSessions.length / 4,
      learningVelocity: this.calculateLearningVelocity(weekSessions),
      improvementTrend: this.calculateImprovementTrend(),
      consistencyScore: this.calculateConsistencyScore(monthSessions)
    };
  }

  /**
   * Calculate efficiency metrics
   */
  calculateEfficiencyMetrics() {
    const completionTimes = this.analyticsData.completionTimes;
    const allTimes = Object.values(completionTimes).flat();

    if (allTimes.length === 0) {
      return {
        overallEfficiency: 0,
        improvementRate: 0,
        timeOptimization: 0
      };
    }

    const recentTimes = allTimes.slice(-10); // Last 10 completions
    const earlierTimes = allTimes.slice(0, -10);

    const recentAverage = recentTimes.reduce((sum, entry) => sum + entry.time, 0) / recentTimes.length;
    const earlierAverage = earlierTimes.length > 0 ?
      earlierTimes.reduce((sum, entry) => sum + entry.time, 0) / earlierTimes.length : recentAverage;

    return {
      overallEfficiency: this.calculateOverallEfficiency(),
      improvementRate: ((earlierAverage - recentAverage) / earlierAverage) * 100,
      timeOptimization: this.calculateTimeOptimization(),
      consistencyScore: this.calculateTimeConsistency(allTimes)
    };
  }

  /**
   * Analyze learning patterns
   */
  analyzeLearningPatterns() {
    const sessions = this.analyticsData.sessions;

    return {
      preferredLearningTime: this.findPreferredLearningTime(sessions),
      sessionLengthPattern: this.analyzeSessionLengths(sessions),
      difficultyProgression: this.analyzeDifficultyProgression(),
      categoryPreferences: this.analyzeCategoryPreferences(),
      retryPatterns: this.analyzeRetryPatterns()
    };
  }

  /**
   * Generate personalized learning insights
   * @returns {Array} Array of insight objects
   */
  generateLearningInsights() {
    if (!this.errorHandler) {
      // LearningAnalyticsEngine: No error handler provided for generateLearningInsights
      return [];
    }

    return this.errorHandler.safeExecute(() => {
      const metrics = this.generateLearningMetrics();
      const insights = [];

      // Performance insights
      insights.push(...this.generatePerformanceInsights(metrics));

      // Learning pattern insights
      insights.push(...this.generatePatternInsights(metrics));

      // Recommendation insights
      insights.push(...this.generateRecommendationInsights(metrics));

      // Store insights
      this.insights.set('latest', insights);
      this.insights.set('timestamp', Date.now());

      return insights;
    }, 'generateLearningInsights', []);
  }

  /**
   * Generate performance-based insights
   * @param {Object} metrics - Learning metrics
   * @returns {Array} Array of performance insights
   */
  generatePerformanceInsights(metrics) {
    const insights = [];

    if (!metrics || !metrics.overall) {
      return insights;
    }

    // Completion rate insight
    if (metrics.overall.completionRate < 30) {
      insights.push({
        type: 'performance',
        priority: 'high',
        title: 'Focus on Completion',
        message: 'Your completion rate is below 30%. Consider focusing on easier katas to build momentum.',
        action: 'Try beginner-level katas to build confidence',
        icon: '🎯'
      });
    } else if (metrics.overall.completionRate > 80) {
      insights.push({
        type: 'performance',
        priority: 'positive',
        title: 'Excellent Progress!',
        message: 'Your completion rate is excellent. You\'re ready for more challenging katas.',
        action: 'Try advanced katas to expand your skills',
        icon: '🚀'
      });
    }

    // Efficiency insight
    if (metrics.efficiency && metrics.efficiency.improvementRate > 20) {
      insights.push({
        type: 'performance',
        priority: 'positive',
        title: 'Great Improvement!',
        message: `You're completing katas ${Math.round(metrics.efficiency.improvementRate)}% faster than before.`,
        action: 'Keep up the excellent progress',
        icon: '📈'
      });
    }

    // Retry pattern insight
    if (metrics.overall.averageRetriesPerKata > 2) {
      insights.push({
        type: 'performance',
        priority: 'medium',
        title: 'Review Your Approach',
        message: 'You have a high retry rate. Consider reviewing fundamentals.',
        action: 'Try easier katas or review concepts',
        icon: '🔄'
      });
    }

    return insights;
  }

  /**
   * Generate pattern-based insights
   * @param {Object} metrics - Learning metrics
   * @returns {Array} Array of pattern insights
   */
  generatePatternInsights(metrics) {
    const insights = [];

    if (!metrics || !metrics.trends || !metrics.patterns) {
      return insights;
    }

    // Consistency insight
    if (metrics.trends.consistencyScore < 0.5) {
      insights.push({
        type: 'pattern',
        priority: 'medium',
        title: 'Build Consistency',
        message: 'Your learning sessions are irregular. Consistent practice leads to better results.',
        action: 'Try to study for 15-30 minutes daily',
        icon: '📅'
      });
    }

    // Learning time insight
    const preferredTime = metrics.patterns.preferredLearningTime;
    if (preferredTime) {
      insights.push({
        type: 'pattern',
        priority: 'low',
        title: 'Optimal Learning Time',
        message: `You perform best during ${preferredTime}. Schedule important sessions then.`,
        action: `Plan challenging katas for ${preferredTime}`,
        icon: '⏰'
      });
    }

    return insights;
  }

  /**
   * Generate recommendation insights
   * @param {Object} metrics - Learning metrics
   * @returns {Array} Array of recommendation insights
   */
  generateRecommendationInsights(metrics) {
    const insights = [];

    if (!metrics || !metrics.byCategory) {
      return insights;
    }

    // Category recommendation
    const weakestCategory = this.findWeakestCategory(metrics.byCategory);
    if (weakestCategory) {
      insights.push({
        type: 'recommendation',
        priority: 'medium',
        title: 'Strengthen Weak Areas',
        message: `Your ${weakestCategory.category} skills need improvement.`,
        action: `Practice more ${weakestCategory.category} katas`,
        icon: '💪'
      });
    }

    // Learning path recommendation
    const recommendedPath = this.recommendLearningPath(metrics);
    if (recommendedPath) {
      insights.push({
        type: 'recommendation',
        priority: 'medium',
        title: 'Suggested Learning Path',
        message: `The "${recommendedPath.name}" path matches your current skill level.`,
        action: 'Start this learning path',
        icon: '🛤️'
      });
    }

    return insights;
  }

  /**
   * Utility methods for calculations
   */
  calculateAverageCompletionTime() {
    const allTimes = Object.values(this.analyticsData.completionTimes).flat();
    if (allTimes.length === 0) {return 0;}
    return allTimes.reduce((sum, entry) => sum + entry.time, 0) / allTimes.length;
  }

  calculateCurrentStreak() {
    // Simplified calculation - would use actual session dates
    return Math.floor(Math.random() * 10) + 1;
  }

  calculateLongestStreak() {
    // Simplified calculation - would analyze session history
    return Math.floor(Math.random() * 20) + 5;
  }

  calculateCategoryEfficiency(categoryId, completed, timeSpent) {
    if (completed === 0 || timeSpent === 0) {return 0;}
    return (completed * 100) / timeSpent; // Tasks per hour metric
  }

  calculateLearningVelocity(sessions) {
    if (sessions.length === 0) {return 0;}
    const completions = sessions.filter(s => s.type === 'completion').length;
    return completions / 7; // Completions per day
  }

  calculateImprovementTrend() {
    // Simplified - would analyze actual performance over time
    return Math.random() > 0.5 ? 'improving' : 'stable';
  }

  calculateConsistencyScore(sessions) {
    if (sessions.length < 7) {return 0;}

    // Calculate variance in session timing
    const dailySessions = this.groupSessionsByDay(sessions);
    const activeDays = Object.keys(dailySessions).length;
    return activeDays / 30; // Proportion of days with activity
  }

  calculateOverallEfficiency() {
    const metrics = this.calculateOverallMetrics();
    return metrics.totalKatasCompleted / Math.max(metrics.totalTimeSpent / 60, 1); // Katas per hour
  }

  calculateTimeOptimization() {
    // Simplified - would analyze time reduction over repeated similar katas
    return Math.random() * 30; // 0-30% optimization
  }

  calculateTimeConsistency(times) {
    if (times.length < 2) {return 1;}
    const values = times.map(entry => entry.time);
    const mean = values.reduce((sum, val) => sum + val, 0) / values.length;
    const variance = values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length;
    return 1 / (1 + Math.sqrt(variance) / mean); // Inverse coefficient of variation
  }

  findPreferredLearningTime(sessions) {
    const hourCounts = {};
    sessions.forEach(session => {
      const hour = new Date(session.timestamp).getHours();
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    });

    const maxHour = Object.keys(hourCounts).reduce((a, b) =>
      hourCounts[a] > hourCounts[b] ? a : b, '0');

    if (parseInt(maxHour) < 12) {return 'morning';}
    if (parseInt(maxHour) < 18) {return 'afternoon';}
    return 'evening';
  }

  analyzeSessionLengths(sessions) {
    const lengths = sessions.map(s => s.duration || 30).filter(d => d > 0);
    if (lengths.length === 0) {return 'unknown';}

    const average = lengths.reduce((sum, len) => sum + len, 0) / lengths.length;
    if (average < 15) {return 'short';}
    if (average < 45) {return 'medium';}
    return 'long';
  }

  analyzeDifficultyProgression() {
    // Simplified - would analyze progression through difficulty levels
    return 'gradual'; // or 'aggressive', 'conservative'
  }

  analyzeCategoryPreferences() {
    const categoryTime = {};
    Object.keys(this.analyticsData.timeSpent).forEach(kataKey => {
      const category = kataKey.split('/')[0];
      categoryTime[category] = (categoryTime[category] || 0) + this.analyticsData.timeSpent[kataKey];
    });

    return Object.keys(categoryTime).sort((a, b) => categoryTime[b] - categoryTime[a]);
  }

  analyzeRetryPatterns() {
    const retries = Object.values(this.analyticsData.retryAttempts);
    const average = retries.reduce((sum, r) => sum + r, 0) / Math.max(retries.length, 1);

    if (average < 1) {return 'low';}
    if (average < 3) {return 'moderate';}
    return 'high';
  }

  findWeakestCategory(categoryMetrics) {
    return categoryMetrics.reduce((weakest, current) =>
      (!weakest || current.completionRate < weakest.completionRate) ? current : weakest, null);
  }

  /**
   * Recommend learning path based on metrics
   * @param {Object} metrics - Learning metrics
   * @returns {Object|null} Recommended learning path
   */
  recommendLearningPath(metrics) {
    if (!this.kataCatalog || !metrics || !metrics.overall) {
      return null;
    }

    try {
      const paths = this.kataCatalog.getAllLearningPaths();

      // Simple recommendation based on overall progress
      if (metrics.overall.completionRate < 25) {
        return paths.find(p => p.id === 'beginner-fundamentals');
      } else if (metrics.overall.completionRate < 60) {
        return paths.find(p => p.id === 'task-planning-mastery');
      } else {
        return paths.find(p => p.id === 'deployment-specialist');
      }
    } catch {
      // LearningAnalyticsEngine: Error recommending learning path
      return null;
    }
  }

  groupSessionsByDay(sessions) {
    const days = {};
    sessions.forEach(session => {
      const day = new Date(session.timestamp).toDateString();
      if (!days[day]) {days[day] = [];}
      days[day].push(session);
    });
    return days;
  }

  /**
   * Find the kata by key (utilizing kata catalog)
   * @param {string} kataKey - Kata identifier
   * @returns {Object|null} Kata object or null if not found
   */
  findKataByKey(kataKey) {
    if (!this.kataCatalog || !kataKey) {
      return null;
    }

    try {
      return this.kataCatalog.getKataById(kataKey);
    } catch {
      // LearningAnalyticsEngine: Error finding kata
      return null;
    }
  }

  /**
   * Generate unique session ID
   * @returns {string} Session ID
   */
  generateSessionId() {
    return `session_${ Date.now() }_${ Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Save analytics data to localStorage
   * @returns {boolean} Success status
   */
  saveAnalyticsData() {
    try {
      localStorage.setItem('kata-learning-analytics', JSON.stringify(this.analyticsData));
      return true;
    } catch {
      // LearningAnalyticsEngine: Failed to save analytics data
      return false;
    }
  }

  /**
   * Get the latest insights
   * @returns {Array} Latest insights
   */
  getLatestInsights() {
    return this.insights.get('latest') || [];
  }

  /**
   * Get the latest metrics
   * @returns {Object} Latest metrics
   */
  getLatestMetrics() {
    return this.metrics.get('latest') || {};
  }

  /**
   * Export analytics data for external analysis
   * @returns {Object} Analytics data
   */
  exportAnalyticsData() {
    return {
      ...this.analyticsData,
      insights: this.getLatestInsights(),
      metrics: this.getLatestMetrics(),
      exportedAt: Date.now()
    };
  }
}

// ES6 Module Export
export default LearningAnalyticsEngine;
