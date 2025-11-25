/**
 * Memory Monitor Utility
 * Monitors and tracks memory usage patterns for the SSE Manager
 */

import EventEmitter from 'events';

class MemoryMonitor extends EventEmitter {
  constructor(sseManager, options = {}) {
    super();
    this.sseManager = sseManager;
    this.monitoringInterval = options.monitoringInterval || 30000; // 30 seconds
    this.alertThreshold = options.alertThreshold || 10000000; // 10MB
    this.cleanupThreshold = options.cleanupThreshold || 0.8; // 80% of limits
    this.monitorTimer = null;
    this.memoryHistory = [];
    this.maxHistorySize = 100;
  }

  /**
   * Start monitoring memory usage
   */
  start() {
    if (this.monitorTimer) {
      return;
    }

    this.monitorTimer = setInterval(() => {
      this.checkMemoryUsage();
    }, this.monitoringInterval);
  }

  /**
   * Stop monitoring
   */
  stop() {
    if (this.monitorTimer) {
      clearInterval(this.monitorTimer);
      this.monitorTimer = null;
    }
  }

  /**
   * Check current memory usage and trigger actions if needed
   */
  checkMemoryUsage() {
    const stats = this.sseManager.getMemoryStats();
    const timestamp = new Date().toISOString();

    // Add to history
    this.memoryHistory.push({
      timestamp,
      ...stats
    });

    // Limit history size
    if (this.memoryHistory.length > this.maxHistorySize) {
      this.memoryHistory.shift();
    }

    // Check thresholds
    this.checkThresholds(stats);

    // Emit monitoring event
    this.emit('memoryCheck', { timestamp, stats });
  }

  /**
   * Check if memory usage exceeds thresholds
   * @param {Object} stats - Memory statistics
   */
  checkThresholds(stats) {
    const maxConnections = this.sseManager.getMaxConnections();
    const maxProgressTypes = this.sseManager.getMaxProgressTypes();
    const maxHistorySize = this.sseManager.getMaxHistorySize();

    // Check connection threshold
    if (stats.clientCount > maxConnections * this.cleanupThreshold) {
      this.emit('connectionThresholdExceeded', {
        current: stats.clientCount,
        max: maxConnections,
        threshold: maxConnections * this.cleanupThreshold
      });
    }

    // Check progress type threshold
    if (stats.progressTypeCount > maxProgressTypes * this.cleanupThreshold) {
      this.emit('progressTypeThresholdExceeded', {
        current: stats.progressTypeCount,
        max: maxProgressTypes,
        threshold: maxProgressTypes * this.cleanupThreshold
      });
    }

    // Check total memory threshold
    if (stats.estimatedMemoryUsage > this.alertThreshold) {
      this.emit('memoryThresholdExceeded', {
        current: stats.estimatedMemoryUsage,
        threshold: this.alertThreshold
      });
    }

    // Check event history threshold
    const totalHistoryThreshold = maxHistorySize * stats.progressTypeCount * this.cleanupThreshold;
    if (stats.totalEventHistory > totalHistoryThreshold) {
      this.emit('eventHistoryThresholdExceeded', {
        current: stats.totalEventHistory,
        threshold: totalHistoryThreshold
      });
    }

    // Trigger automatic cleanup if needed
    if (this.sseManager.shouldTriggerCleanup()) {
      this.triggerCleanup();
    }
  }

  /**
   * Trigger automatic cleanup
   */
  triggerCleanup() {

    try {
      // Cleanup expired events
      this.sseManager.cleanupExpiredEvents();

      // Cleanup unused progress types
      this.sseManager.cleanupUnusedProgressTypes();

      // Cleanup stale connections
      this.sseManager.cleanupStaleConnections();

      this.emit('cleanupTriggered', {
        timestamp: new Date().toISOString(),
        reason: 'automatic'
      });
    } catch (error) {
      console.error('[MemoryMonitor] Error during cleanup:', error);
      this.emit('cleanupError', { error: error.message });
    }
  }

  /**
   * Get memory usage trend
   * @returns {Object} Memory trend analysis
   */
  getMemoryTrend() {
    if (this.memoryHistory.length < 2) {
      return { trend: 'insufficient_data', samples: this.memoryHistory.length };
    }

    const recent = this.memoryHistory.slice(-10); // Last 10 samples
    const older = this.memoryHistory.slice(-20, -10); // 10 samples before that

    if (older.length === 0) {
      return { trend: 'insufficient_data', samples: this.memoryHistory.length };
    }

    const recentAverage = recent.reduce((sum, sample) => sum + sample.estimatedMemoryUsage, 0) / recent.length;
    const olderAverage = older.reduce((sum, sample) => sum + sample.estimatedMemoryUsage, 0) / older.length;

    const percentChange = ((recentAverage - olderAverage) / olderAverage) * 100;

    let trend = 'stable';
    if (percentChange > 10) {
      trend = 'increasing';
    } else if (percentChange < -10) {
      trend = 'decreasing';
    }

    return {
      trend,
      percentChange: Math.round(percentChange * 100) / 100,
      recentAverage: Math.round(recentAverage),
      olderAverage: Math.round(olderAverage),
      samples: this.memoryHistory.length
    };
  }

  /**
   * Get detailed memory report
   * @returns {Object} Detailed memory report
   */
  getMemoryReport() {
    const currentStats = this.sseManager.getMemoryStats();
    const trend = this.getMemoryTrend();
    const maxConnections = this.sseManager.getMaxConnections();
    const maxProgressTypes = this.sseManager.getMaxProgressTypes();

    return {
      timestamp: new Date().toISOString(),
      current: currentStats,
      limits: {
        maxConnections,
        maxProgressTypes,
        maxHistorySize: this.sseManager.getMaxHistorySize(),
        alertThreshold: this.alertThreshold
      },
      utilization: {
        connections: Math.round((currentStats.clientCount / maxConnections) * 100),
        progressTypes: Math.round((currentStats.progressTypeCount / maxProgressTypes) * 100),
        memory: Math.round((currentStats.estimatedMemoryUsage / this.alertThreshold) * 100)
      },
      trend,
      monitoring: {
        isActive: this.monitorTimer !== null,
        interval: this.monitoringInterval,
        historySamples: this.memoryHistory.length
      }
    };
  }

  /**
   * Export memory history for analysis
   * @returns {Array} Memory history
   */
  exportHistory() {
    return [...this.memoryHistory];
  }

  /**
   * Clear memory history
   */
  clearHistory() {
    this.memoryHistory = [];
  }
}

export default MemoryMonitor;
