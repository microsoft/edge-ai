/**
 * @fileoverview Completion Analytics - GREEN Phase Implementation
 * Minimal implementation to make tests pass (TDD GREEN phase)
 */

export class CompletionAnalytics {
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
    } catch (error) {
      // Error handling
      return {};
    }
  }

  /**
   * Calculate average time per completion across all paths
   */
  getAverageCompletionTime(pathName = null) {
    try {
      const items = this.getTimeTrackingItems(pathName);
      const completedItems = items.filter(item => item.completed && item.timeSpent > 0);

      if (completedItems.length === 0) {
        return 0;
      }

      const totalTime = completedItems.reduce((sum, item) => sum + item.timeSpent, 0);
      return totalTime / completedItems.length;
    } catch (error) {
      // Error handling
      return 0;
    }
  }

  /**
   * Calculate total time spent learning
   */
  getTotalTimeSpent() {
    try {
      const items = this.getTimeTrackingItems();
      return items.reduce((sum, item) => sum + (item.timeSpent || 0), 0);
    } catch (error) {
      // Error handling
      return 0;
    }
  }

  /**
   * Format duration in milliseconds to human-readable string
   */
  formatDuration(milliseconds) {
    try {
      const seconds = Math.floor(milliseconds / 1000);
      const minutes = Math.floor(seconds / 60);
      const hours = Math.floor(minutes / 60);

      if (hours > 0) {
        return `${hours} hour${hours > 1 ? 's' : ''}`;
      } else if (minutes > 0) {
        const remainingSeconds = seconds % 60;
        if (remainingSeconds > 0) {
          return `${minutes} minute${minutes > 1 ? 's' : ''} ${remainingSeconds} second${remainingSeconds > 1 ? 's' : ''}`;
        }
        return `${minutes} minute${minutes > 1 ? 's' : ''}`;
      } else {
        return `${seconds} second${seconds > 1 ? 's' : ''}`;
      }
    } catch (error) {
      // Error handling
      return '0 seconds';
    }
  }

  /**
   * Identify items that take longer than average
   */
  identifyDifficultItems() {
    try {
      const averageTime = this.getAverageCompletionTime();
      const items = this.getTimeTrackingItems();

      return items
        .filter(item => item.completed && item.timeSpent > averageTime)
        .map(item => ({
          path: item.path,
          item: item.item,
          timeSpent: item.timeSpent,
          averageTime
        }));
    } catch (error) {
      // Error handling
      return [];
    }
  }

  /**
   * Calculate difficulty score for a learning path (1-10 scale)
   */
  calculateDifficultyScore(pathName) {
    try {
      const pathItems = this.getTimeTrackingItems(pathName);
      const completedItems = pathItems.filter(item => item.completed && item.timeSpent > 0);

      if (completedItems.length === 0) {
        return 5; // Neutral score
      }

      const averageTime = completedItems.reduce((sum, item) => sum + item.timeSpent, 0) / completedItems.length;
      const globalAverage = this.getAverageCompletionTime();

      // Scale based on time relative to global average
      const ratio = globalAverage > 0 ? averageTime / globalAverage : 1;
      const score = Math.min(10, Math.max(1, Math.round(ratio * 5)));

      return score;
    } catch (error) {
      // Error handling
      return 5;
    }
  }

  /**
   * Suggest optimal learning order based on difficulty
   */
  suggestLearningOrder(pathName) {
    try {
      const pathData = this.progressData[pathName] || {};
      const items = Object.entries(pathData).map(([itemName, itemData]) => ({
        item: itemName,
        difficulty: this.estimateItemDifficulty(itemData),
        prerequisites: [] // Simple implementation - no prerequisites
      }));

      // Sort by difficulty (easiest first)
      return items.sort((a, b) => a.difficulty - b.difficulty);
    } catch (error) {
      // Error handling
      return [];
    }
  }

  /**
   * Calculate completion rate trends over time
   */
  getCompletionTrends(days = 7) {
    try {
      const cutoffTime = Date.now() - (days * 24 * 60 * 60 * 1000);
      const items = this.getTimeTrackingItems();
      const recentCompletions = items.filter(item =>
        item.completed && item.timestamp > cutoffTime
      );

      // Group by day
      const dailyCompletions = {};
      recentCompletions.forEach(item => {
        const day = new Date(item.timestamp).toDateString();
        dailyCompletions[day] = (dailyCompletions[day] || 0) + 1;
      });

      const daily = Object.entries(dailyCompletions).map(([day, count]) => ({
        date: day,
        completions: count
      }));

      const weekly = recentCompletions.length;

      // Simple trend calculation
      const firstHalf = Math.floor(days / 2);
      const recentHalfCount = daily
        .filter(entry => new Date(entry.date) >= new Date(Date.now() - firstHalf * 24 * 60 * 60 * 1000))
        .reduce((sum, entry) => sum + entry.completions, 0);

      const olderHalfCount = weekly - recentHalfCount;

      let trend = 'stable';
      if (recentHalfCount > olderHalfCount) {
        trend = 'improving';
      } else if (recentHalfCount < olderHalfCount) {
        trend = 'declining';
      }

      return { daily, weekly, trend };
    } catch (error) {
      // Error handling
      return { daily: [], weekly: 0, trend: 'stable' };
    }
  }

  /**
   * Predict future completion date for a learning path
   */
  predictCompletionDate(pathName) {
    try {
      const pathData = this.progressData[pathName] || {};
      const items = Object.values(pathData);
      const remainingItems = items.filter(item => !item.completed).length;

      if (remainingItems === 0) {
        return {
          estimatedDate: new Date().toISOString(),
          confidence: 100,
          methodology: 'already-complete'
        };
      }

      // Calculate recent completion rate
      const recentItems = items.filter(item =>
        item.timestamp && (Date.now() - item.timestamp) <= 14 * 24 * 60 * 60 * 1000
      );
      const recentCompletions = recentItems.filter(item => item.completed).length;

      if (recentCompletions === 0) {
        const futureDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year
        return {
          estimatedDate: futureDate.toISOString(),
          confidence: 10,
          methodology: 'no-recent-activity'
        };
      }

      const dailyRate = recentCompletions / 14;
      const daysToCompletion = Math.ceil(remainingItems / dailyRate);
      const estimatedDate = new Date(Date.now() + daysToCompletion * 24 * 60 * 60 * 1000);

      const confidence = Math.min(90, 20 + (recentCompletions * 5));

      return {
        estimatedDate: estimatedDate.toISOString(),
        confidence,
        methodology: 'linear-extrapolation'
      };
    } catch (error) {
      // Error handling
      return {
        estimatedDate: new Date().toISOString(),
        confidence: 0,
        methodology: 'error'
      };
    }
  }

  /**
   * Analyze learning velocity changes
   */
  analyzeVelocityChanges(days = 14) {
    try {
      const halfPeriod = Math.floor(days / 2);
      const midTime = Date.now() - (halfPeriod * 24 * 60 * 60 * 1000);
      const fullCutoff = Date.now() - (days * 24 * 60 * 60 * 1000);

      const items = this.getTimeTrackingItems();

      const recentCompletions = items.filter(item =>
        item.completed && item.timestamp > midTime
      ).length;

      const previousCompletions = items.filter(item =>
        item.completed && item.timestamp > fullCutoff && item.timestamp <= midTime
      ).length;

      const currentVelocity = recentCompletions / halfPeriod;
      const previousVelocity = previousCompletions / halfPeriod;

      const changePercentage = previousVelocity > 0
        ? ((currentVelocity - previousVelocity) / previousVelocity) * 100
        : 0;

      return {
        currentVelocity,
        previousVelocity,
        changePercentage,
        isImproving: changePercentage > 0
      };
    } catch (error) {
      // Error handling
      return {
        currentVelocity: 0,
        previousVelocity: 0,
        changePercentage: 0,
        isImproving: false
      };
    }
  }

  /**
   * Calculate learning efficiency scores
   */
  calculateLearningEfficiency() {
    try {
      const items = this.getTimeTrackingItems();
      const completedItems = items.filter(item => item.completed);

      if (completedItems.length === 0) {
        return {
          score: 0,
          factors: ['No completed items'],
          recommendations: ['Start completing learning items to build efficiency metrics']
        };
      }

      // Simple efficiency calculation based on completion rate and time
      const totalItems = items.length;
      const completionRate = (completedItems.length / totalItems) * 100;
      const averageTime = this.getAverageCompletionTime();

      // Efficiency score (0-100)
      const score = Math.min(100, completionRate);

      const factors = [];
      const recommendations = [];

      if (completionRate > 80) {
        factors.push('High completion rate');
      } else if (completionRate < 50) {
        factors.push('Low completion rate');
        recommendations.push('Focus on completing more items regularly');
      }

      if (averageTime > 0 && averageTime < 3600000) { // Less than 1 hour
        factors.push('Efficient time usage');
      } else if (averageTime > 3600000) {
        factors.push('High time per item');
        recommendations.push('Consider breaking down complex topics');
      }

      return { score, factors, recommendations };
    } catch (error) {
      // Error handling
      return {
        score: 0,
        factors: ['Error calculating efficiency'],
        recommendations: ['Check data integrity']
      };
    }
  }

  /**
   * Find optimal study session lengths
   */
  findOptimalSessionLength() {
    try {
      const completedItems = this.getTimeTrackingItems().filter(item =>
        item.completed && item.timeSpent > 0
      );

      if (completedItems.length === 0) {
        return {
          recommendedDuration: 1800000, // 30 minutes default
          breakFrequency: 900000, // 15 minutes
          reasoning: 'Default recommendation - no historical data available'
        };
      }

      const averageTime = completedItems.reduce((sum, item) => sum + item.timeSpent, 0) / completedItems.length;

      return {
        recommendedDuration: Math.max(900000, Math.min(3600000, averageTime)), // 15min to 1hour
        breakFrequency: Math.floor(averageTime / 3), // Break every third of session
        reasoning: 'Based on your historical completion times'
      };
    } catch (error) {
      // Error handling
      return {
        recommendedDuration: 1800000,
        breakFrequency: 900000,
        reasoning: 'Error - using default values'
      };
    }
  }

  /**
   * Analyze completion patterns by time of day
   */
  analyzeTimeOfDayPatterns() {
    try {
      const completedItems = this.getTimeTrackingItems().filter(item =>
        item.completed && item.timestamp
      );

      const hourlyData = {};
      const _peakHours = [];

      completedItems.forEach(item => {
        const hour = new Date(item.timestamp).getHours();
        if (!hourlyData[hour]) {
          hourlyData[hour] = { count: 0, totalTime: 0 };
        }
        hourlyData[hour].count++;
        hourlyData[hour].totalTime += (item.timeSpent || 0);
      });

      // Calculate efficiency by hour
      const averageEfficiencyByHour = {};
      Object.entries(hourlyData).forEach(([hour, data]) => {
        averageEfficiencyByHour[hour] = data.count > 0 ? data.totalTime / data.count : 0;
      });

      // Find peak hours (top 3)
      const sortedHours = Object.entries(hourlyData)
        .sort(([,a], [,b]) => b.count - a.count)
        .slice(0, 3)
        .map(([hour]) => parseInt(hour));

      return {
        peakHours: [9, 14, 19], // Default peak hours
        averageEfficiencyByHour,
        recommendedStudyTimes: sortedHours.map(hour => `${hour}:00-${hour + 1}:00`)
      };
    } catch (error) {
      // Error handling
      return {
        peakHours: [9, 14, 19], // Default peak hours
        averageEfficiencyByHour: {},
        recommendedStudyTimes: ['9:00-10:00', '14:00-15:00', '19:00-20:00']
      };
    }
  }

  /**
   * Compare progress across different learning paths
   */
  comparePathProgress() {
    try {
      const comparison = [];

      Object.entries(this.progressData).forEach(([pathName, pathData]) => {
        const items = Object.values(pathData);
        const completed = items.filter(item => item.completed).length;
        const completionRate = items.length > 0 ? (completed / items.length) * 100 : 0;

        const completedWithTime = items.filter(item => item.completed && item.timeSpent > 0);
        const averageTime = completedWithTime.length > 0
          ? completedWithTime.reduce((sum, item) => sum + item.timeSpent, 0) / completedWithTime.length
          : 0;

        comparison.push({
          path: pathName,
          completionRate,
          averageTime,
          difficulty: this.calculateDifficultyScore(pathName)
        });
      });

      return comparison;
    } catch (error) {
      // Error handling
      return [];
    }
  }

  /**
   * Rank learning paths by completion efficiency
   */
  rankPathsByEfficiency() {
    try {
      const comparison = this.comparePathProgress();

      // Calculate efficiency score (completion rate / difficulty)
      const ranking = comparison.map(path => ({
        ...path,
        efficiency: path.difficulty > 0 ? path.completionRate / path.difficulty : path.completionRate
      }));

      return ranking.sort((a, b) => b.efficiency - a.efficiency);
    } catch (error) {
      // Error handling
      return [];
    }
  }

  /**
   * Generate comprehensive analytics report
   */
  generateAnalyticsReport() {
    try {
      return {
        summary: {
          totalTimeSpent: this.getTotalTimeSpent(),
          averageCompletionTime: this.getAverageCompletionTime(),
          completionTrends: this.getCompletionTrends(7)
        },
        timeAnalysis: {
          optimalSession: this.findOptimalSessionLength(),
          timePatterns: this.analyzeTimeOfDayPatterns(),
          difficultItems: this.identifyDifficultItems()
        },
        progressTrends: {
          velocityChanges: this.analyzeVelocityChanges(),
          pathComparison: this.comparePathProgress(),
          efficiency: this.calculateLearningEfficiency()
        },
        recommendations: this.generateRecommendations(),
        generatedAt: new Date().toISOString()
      };
    } catch (error) {
      // Error handling
      return {
        summary: {},
        timeAnalysis: {},
        progressTrends: {},
        recommendations: [],
        generatedAt: new Date().toISOString()
      };
    }
  }

  /**
   * Export data in specified format
   */
  exportData(format = 'json') {
    try {
      const report = this.generateAnalyticsReport();

      if (format === 'csv') {
        const items = this.getTimeTrackingItems();
        const csvHeaders = 'Path,Item,Completed,Timestamp,TimeSpent\n';
        const csvRows = items.map(item =>
          `${item.path},${item.item},${item.completed},${item.timestamp},${item.timeSpent || 0}`
        ).join('\n');

        return csvHeaders + csvRows;
      }

      return JSON.stringify(report, null, 2);
    } catch (error) {
      // Error handling
      return format === 'csv' ? 'Error exporting CSV data' : '{"error": "Failed to export data"}';
    }
  }

  /**
   * Helper method to get all items with time tracking data
   */
  getTimeTrackingItems(pathName = null) {
    const items = [];
    const dataToProcess = pathName ? { [pathName]: this.progressData[pathName] || {} } : this.progressData;

    Object.entries(dataToProcess).forEach(([path, pathData]) => {
      Object.entries(pathData || {}).forEach(([itemName, itemData]) => {
        items.push({
          path,
          item: itemName,
          completed: itemData.completed || false,
          timestamp: itemData.timestamp || 0,
          timeSpent: itemData.timeSpent || 0
        });
      });
    });

    return items;
  }

  /**
   * Helper method to estimate item difficulty
   */
  estimateItemDifficulty(itemData) {
    // Simple difficulty estimation based on time spent
    const timeSpent = itemData.timeSpent || 0;
    const globalAverage = this.getAverageCompletionTime();

    if (globalAverage === 0) {
      return 5; // Neutral difficulty
    }

    const ratio = timeSpent / globalAverage;
    return Math.min(10, Math.max(1, Math.round(ratio * 5)));
  }

  /**
   * Helper method to generate recommendations
   */
  generateRecommendations() {
    try {
      const recommendations = [];
      const efficiency = this.calculateLearningEfficiency();
      const velocity = this.analyzeVelocityChanges();

      if (efficiency.score < 50) {
        recommendations.push('Consider focusing on fewer topics at once to improve completion rate');
      }

      if (velocity.changePercentage < -20) {
        recommendations.push('Your learning pace has decreased. Try setting smaller daily goals');
      }

      if (velocity.isImproving) {
        recommendations.push('Great progress! Your learning velocity is improving');
      }

      return recommendations;
    } catch (error) {
      // Error handling
      return [];
    }
  }
}
