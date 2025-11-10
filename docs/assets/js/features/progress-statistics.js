/**
 * @fileoverview Progress Statistics - GREEN Phase Implementation
 * Minimal implementation to make tests pass (TDD GREEN phase)
 */

/* eslint-disable no-console */

export class ProgressStatistics {
  constructor() {
    this.progressData = this.loadProgressData();
  }

  /**
   * Load progress data from localStorage with error handling
   */
  loadProgressData() {
    try {
      if (!localStorage) {
        return {};
      }

      const data = localStorage.getItem('learning-progress');
      if (!data) {
        return {};
      }

      return JSON.parse(data);
    } catch (_error) {
      console.warn('Failed to load progress data:', _error);
      return {};
    }
  }

  /**
   * Calculate overall completion percentage across all learning paths
   */
  calculateOverallCompletion() {
    try {
      const allItems = this.getAllProgressItems();
      if (allItems.length === 0) {
        return 0;
      }

      const completedItems = allItems.filter(item => item.completed);
      return Math.round((completedItems.length / allItems.length) * 100 * 100) / 100; // Round to 2 decimals
    } catch (_error) {
      console.warn('Failed to calculate overall completion:', _error);
      return 0;
    }
  }

  /**
   * Calculate completion percentage for a specific learning path
   */
  calculatePathCompletion(pathName) {
    try {
      const pathData = this.progressData[pathName] || {};
      const items = Object.values(pathData);

      if (items.length === 0) {
        return { percentage: 0, completed: 0, total: 0 };
      }

      const completedItems = items.filter(item => item.completed);
      const percentage = Math.round((completedItems.length / items.length) * 100 * 100) / 100;

      return {
        percentage,
        completed: completedItems.length,
        total: items.length
      };
    } catch (_error) {
      console.warn('Failed to calculate path completion:', _error);
      return { percentage: 0, completed: 0, total: 0 };
    }
  }

  /**
   * Estimate time to completion based on current pace
   */
  estimateTimeToCompletion(pathName) {
    try {
      const pathData = this.progressData[pathName] || {};
      const items = Object.values(pathData);

      if (items.length === 0) {
        return { estimatedDays: 0, confidence: 0 };
      }

      // Calculate completion rate based on recent activity
      const now = Date.now();
      const recentActivity = items.filter(item =>
        item.timestamp && (now - item.timestamp) <= 7 * 24 * 60 * 60 * 1000 // Last 7 days
      );

      if (recentActivity.length === 0) {
        return { estimatedDays: 0, confidence: 25 }; // Low confidence for no recent activity
      }

      const completedInPeriod = recentActivity.filter(item => item.completed).length;
      const remainingItems = items.filter(item => !item.completed).length;

      if (completedInPeriod === 0) {
        return { estimatedDays: 999, confidence: 10 }; // Very low confidence
      }

      const dailyRate = completedInPeriod / 7; // Items per day
      const estimatedDays = Math.ceil(remainingItems / dailyRate);

      // Confidence based on recent activity and data quality
      const confidence = Math.min(95, 50 + (recentActivity.length * 5));

      return { estimatedDays, confidence };
    } catch (_error) {
      console.warn('Failed to estimate completion time:', _error);
      return { estimatedDays: 0, confidence: 0 };
    }
  }

  /**
   * Calculate current learning streak (consecutive days with progress)
   */
  calculateLearningStreak() {
    try {
      const allItems = this.getAllProgressItems();

      if (allItems.length === 0) {
        return { currentStreak: 0, longestStreak: 0 };
      }

      // Get all completion timestamps and group by day
      const completionDays = new Set();
      allItems.forEach(item => {
        if (item.completed && item.timestamp) {
          // Convert timestamp to day (YYYY-MM-DD format) in local timezone
          const date = new Date(item.timestamp);
          const dayKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
          completionDays.add(dayKey);
        }
      });

      if (completionDays.size === 0) {
        return { currentStreak: 0, longestStreak: 0 };
      }

      // Convert to sorted array (most recent first)
      const sortedDays = Array.from(completionDays).sort((a, b) => {
        return new Date(b).getTime() - new Date(a).getTime();
      });

      let currentStreak = 0;
      let longestStreak = 0;
      let tempStreak = 0;

      // Count consecutive days starting from the most recent
      for (let i = 0; i < sortedDays.length; i++) {
        if (i === 0) {
          // First day (most recent)
          tempStreak = 1;
          currentStreak = 1;
        } else {
          // Check if this day is consecutive to the previous day
          const currentDay = new Date(sortedDays[i]);
          const previousDay = new Date(sortedDays[i - 1]);

          // Calculate difference in days
          const timeDiff = previousDay.getTime() - currentDay.getTime();
          const daysDiff = Math.round(timeDiff / (1000 * 60 * 60 * 24));

          if (daysDiff === 1) {
            // Consecutive day
            tempStreak++;
            if (currentStreak > 0) {
              // We're still building the current streak from the most recent day
              currentStreak = tempStreak;
            }
          } else {
            // Gap found - streak is broken
            longestStreak = Math.max(longestStreak, tempStreak);

            // If this is the first gap after the most recent day, current streak is tempStreak
            if (i === 1) {
              currentStreak = tempStreak; // The consecutive days before this gap
            } else if (currentStreak > 0) {
              // Current streak was already set, don't change it
            }

            tempStreak = 1;
          }
        }
      }

      // Update longest streak with the final temp streak
      longestStreak = Math.max(longestStreak, tempStreak);

      return { currentStreak, longestStreak };
    } catch (_error) {
      console.warn('Failed to calculate learning streak:', _error);
      return { currentStreak: 0, longestStreak: 0 };
    }
  }

  /**
   * Get recent progress activity
   */
  getRecentActivity(days = 7) {
    try {
      const _allItems = this.getAllProgressItems();
      const cutoffTime = Date.now() - (days * 24 * 60 * 60 * 1000);

      const recentActivity = [];

      Object.entries(this.progressData).forEach(([pathName, pathData]) => {
        Object.entries(pathData).forEach(([itemName, itemData]) => {
          if (itemData.timestamp && itemData.timestamp > cutoffTime) {
            recentActivity.push({
              date: new Date(itemData.timestamp).toISOString(),
              completions: itemData.completed ? 1 : 0,
              path: pathName,
              item: itemName
            });
          }
        });
      });

      // Sort by most recent first
      return recentActivity.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    } catch (_error) {
      console.warn('Failed to get recent activity:', _error);
      return [];
    }
  }

  /**
   * Calculate daily completion velocity
   */
  calculateCompletionVelocity(days = 7) {
    try {
      const recentActivity = this.getRecentActivity(days);
      const completions = recentActivity.filter(activity => activity.completions > 0);

      const itemsPerDay = completions.length / days;

      // Simple trend calculation - compare first half vs second half of period
      const midPoint = Math.floor(days / 2);
      const recentHalf = completions.filter(activity => {
        const activityDate = new Date(activity.date);
        const midDate = new Date(Date.now() - (midPoint * 24 * 60 * 60 * 1000));
        return activityDate >= midDate;
      });

      const olderHalf = completions.filter(activity => {
        const activityDate = new Date(activity.date);
        const midDate = new Date(Date.now() - (midPoint * 24 * 60 * 60 * 1000));
        return activityDate < midDate;
      });

      let trend = 'stable';
      if (recentHalf.length > olderHalf.length) {
        trend = 'increasing';
      } else if (recentHalf.length < olderHalf.length) {
        trend = 'decreasing';
      }

      return { itemsPerDay, trend };
    } catch (_error) {
      console.warn('Failed to calculate completion velocity:', _error);
      return { itemsPerDay: 0, trend: 'stable' };
    }
  }

  /**
   * Identify learning patterns
   */
  identifyLearningPatterns() {
    try {
      const allItems = this.getAllProgressItems();
      const completedItems = allItems.filter(item => item.completed && item.timestamp);

      if (completedItems.length === 0) {
        return {
          preferredTimeOfDay: 'unknown',
          averageSessionLength: 0,
          mostProductiveDays: []
        };
      }

      // Analyze time of day patterns
      const hourCounts = {};
      completedItems.forEach(item => {
        const hour = new Date(item.timestamp).getHours();
        hourCounts[hour] = (hourCounts[hour] || 0) + 1;
      });

      let preferredHour = 0;
      let maxCount = 0;
      Object.entries(hourCounts).forEach(([hour, count]) => {
        if (count > maxCount) {
          maxCount = count;
          preferredHour = parseInt(hour);
        }
      });

      const preferredTimeOfDay = this.formatTimeOfDay(preferredHour);

      // Analyze day patterns
      const dayCounts = {};
      completedItems.forEach(item => {
        const day = new Date(item.timestamp).toDateString();
        dayCounts[day] = (dayCounts[day] || 0) + 1;
      });

      const mostProductiveDays = Object.entries(dayCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 3)
        .map(([day]) => day);

      return {
        preferredTimeOfDay,
        averageSessionLength: 30, // Default estimate in minutes
        mostProductiveDays
      };
    } catch (_error) {
      console.warn('Failed to identify learning patterns:', _error);
      return {
        preferredTimeOfDay: 'unknown',
        averageSessionLength: 0,
        mostProductiveDays: []
      };
    }
  }

  /**
   * Generate performance insights
   */
  generateInsights() {
    try {
      const insights = [];
      const overallCompletion = this.calculateOverallCompletion();
      const streak = this.calculateLearningStreak();
      const velocity = this.calculateCompletionVelocity();

      // Achievement insights
      if (streak.currentStreak >= 7) {
        insights.push({
          message: `Impressive! You've maintained a ${streak.currentStreak}-day learning streak.`,
          type: 'achievement',
          priority: 'high'
        });
      }

      if (overallCompletion >= 80) {
        insights.push({
          message: `You're ${overallCompletion}% complete! You're almost there!`,
          type: 'achievement',
          priority: 'high'
        });
      }

      // Recommendation insights
      if (velocity.trend === 'decreasing') {
        insights.push({
          message: 'Your learning pace has slowed down. Consider setting smaller daily goals.',
          type: 'recommendation',
          priority: 'medium'
        });
      }

      if (streak.currentStreak === 0) {
        insights.push({
          message: 'Start a learning streak! Complete at least one item today.',
          type: 'recommendation',
          priority: 'medium'
        });
      }

      // Warning insights
      if (overallCompletion < 10) {
        insights.push({
          message: 'You\'re just getting started. Focus on completing basic concepts first.',
          type: 'warning',
          priority: 'low'
        });
      }

      return insights;
    } catch (_error) {
      console.warn('Failed to generate insights:', _error);
      return [];
    }
  }

  /**
   * Helper method to get all progress items across all paths
   */
  getAllProgressItems() {
    const items = [];
    Object.entries(this.progressData).forEach(([pathName, pathData]) => {
      Object.entries(pathData).forEach(([itemName, itemData]) => {
        items.push({
          path: pathName,
          item: itemName,
          ...itemData
        });
      });
    });
    return items;
  }

  /**
   * Helper method to format hour into time of day
   */
  formatTimeOfDay(hour) {
    if (hour >= 6 && hour < 12) {
      return 'morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'evening';
    }
    return 'late night';
  }
}
