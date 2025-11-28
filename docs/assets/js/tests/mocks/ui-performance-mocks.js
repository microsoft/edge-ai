/**
 * UI Performance Mocks for Testing
 * Provides mock implementations for UI performance monitoring
 *
 * @fileoverview Mock implementations for UI performance testing tools
 */

export class UIPerformanceMonitor {
  constructor() {
    this.monitoring = false;
    this.interactions = [];
    this.currentResponsiveness = true;
  }

  startMonitoring() {
    this.monitoring = true;
    this.interactions = [];
  }

  stopMonitoring() {
    this.monitoring = false;
  }

  analyzeDegradation(responseMetrics) {
    const responseTimes = responseMetrics.map(m => m.responseTime);
    const maxResponseTime = Math.max(...responseTimes);
    const averageResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;

    // Check for performance degradation over time
    const firstHalf = responseTimes.slice(0, Math.floor(responseTimes.length / 2));
    const secondHalf = responseTimes.slice(Math.floor(responseTimes.length / 2));

    const firstHalfAvg = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
    const secondHalfAvg = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;

    const degradationThreshold = 1.5; // 50% increase is considered degradation
    const hasDegradation = secondHalfAvg > firstHalfAvg * degradationThreshold;

    return {
      hasDegradation,
      maxResponseTime,
      averageResponseTime,
      consistentPerformance: !hasDegradation && maxResponseTime < 100
    };
  }

  checkResponsivenessDuringOperation(operationName) {
    return {
      remainedResponsive: this.currentResponsiveness,
      operationName,
      timestamp: Date.now()
    };
  }

  checkCurrentResponsiveness() {
    return this.currentResponsiveness;
  }

  createScrollTracker() {
    return new ScrollTracker();
  }

  createVirtualScrollTracker() {
    return new VirtualScrollTracker();
  }
}

export class InteractionTracker {
  constructor() {
    this.tracking = false;
    this.interactions = [];
    this.responseTimes = [];
  }

  startTracking() {
    this.tracking = true;
    this.interactions = [];
    this.responseTimes = [];
  }

  stopTracking() {
    this.tracking = false;
  }

  recordInteractionStart(type, target) {
    if (this.tracking) {
      this.interactions.push({
        type,
        target,
        startTime: performance.now(),
        endTime: null
      });
    }
  }

  recordInteractionEnd(type, target, responseTime) {
    if (this.tracking) {
      const interaction = this.interactions.find(i =>
        i.type === type && i.target === target && i.endTime === null
      );

      if (interaction) {
        interaction.endTime = performance.now();
        this.responseTimes.push(responseTime);
      }
    }
  }

  getMetrics() {
    const averageResponseTime = this.responseTimes.length > 0
      ? this.responseTimes.reduce((a, b) => a + b, 0) / this.responseTimes.length
      : 0;

    const responsiveInteractions = this.responseTimes.filter(rt => rt < 100).length;
    const responsiveRatio = this.responseTimes.length > 0
      ? responsiveInteractions / this.responseTimes.length
      : 1;

    return {
      averageResponseTime,
      responsiveInteractions: responsiveRatio,
      totalInteractions: this.interactions.length
    };
  }
}

export class RenderingProfiler {
  constructor() {
    this.profiling = false;
    this.renderCycles = new Map();
    this.layoutTracking = false;
    this.layoutMetrics = {
      totalReflows: 0,
      totalRepaints: 0,
      layoutThrashing: false,
      cumulativeLayoutShift: 0
    };
  }

  startProfiling() {
    this.profiling = true;
  }

  stopProfiling() {
    this.profiling = false;
  }

  startRenderCycle(name) {
    if (this.profiling) {
      this.renderCycles.set(name, {
        startTime: performance.now(),
        endTime: null,
        frameDrops: 0,
        blockingTime: 0,
        layoutThrashing: false
      });
    }
  }

  endRenderCycle(name) {
    if (this.profiling && this.renderCycles.has(name)) {
      const cycle = this.renderCycles.get(name);
      cycle.endTime = performance.now();

      // Simulate realistic rendering metrics
      const duration = cycle.endTime - cycle.startTime;
      cycle.frameDrops = duration > 100 ? Math.floor(duration / 50) : 0;
      cycle.blockingTime = Math.min(duration * 0.1, 50); // 10% of duration, max 50ms
      cycle.layoutThrashing = duration > 200;
    }
  }

  getMetrics(name) {
    return this.renderCycles.get(name) || {
      frameDrops: 0,
      blockingTime: 0,
      layoutThrashing: false
    };
  }

  startLayoutTracking() {
    this.layoutTracking = true;
    this.layoutMetrics = {
      totalReflows: 0,
      totalRepaints: 0,
      layoutThrashing: false,
      cumulativeLayoutShift: 0
    };
  }

  stopLayoutTracking() {
    this.layoutTracking = false;
  }

  getLayoutMetrics() {
    // Simulate realistic layout metrics
    this.layoutMetrics.totalReflows = Math.floor(Math.random() * 5) + 1; // 1-5 reflows
    this.layoutMetrics.totalRepaints = Math.floor(Math.random() * 10) + 5; // 5-14 repaints
    this.layoutMetrics.layoutThrashing = this.layoutMetrics.totalReflows > 8;
    this.layoutMetrics.cumulativeLayoutShift = Math.random() * 0.05; // 0-0.05 CLS

    return { ...this.layoutMetrics };
  }
}

export class AnimationFrameMonitor {
  constructor() {
    this.monitoring = false;
    this.frameRates = [];
    this.animationMetrics = {
      averageFrameRate: 60,
      frameDrops: 0,
      jankScore: 0,
      smoothAnimations: 1.0
    };
  }

  startMonitoring() {
    this.monitoring = true;
    this.frameRates = [];
  }

  stopMonitoring() {
    this.monitoring = false;
  }

  startAnimationTracking() {
    this.monitoring = true;
    this.frameRates = [];
  }

  stopAnimationTracking() {
    this.monitoring = false;
    this.calculateAnimationMetrics();
  }

  getCurrentFrameRate() {
    // Simulate realistic frame rate (55-60 FPS with occasional drops)
    const baseFrameRate = 60;
    const variation = Math.random() * 5; // 0-5 FPS variation
    const frameRate = baseFrameRate - variation;

    if (this.monitoring) {
      this.frameRates.push(frameRate);
    }

    return frameRate;
  }

  calculateAnimationMetrics() {
    if (this.frameRates.length === 0) {return;}

    const averageFrameRate = this.frameRates.reduce((a, b) => a + b, 0) / this.frameRates.length;
    const frameDrops = this.frameRates.filter(fr => fr < 55).length;
    const jankScore = frameDrops / this.frameRates.length;
    const smoothAnimations = 1 - jankScore;

    this.animationMetrics = {
      averageFrameRate,
      frameDrops,
      jankScore,
      smoothAnimations
    };
  }

  getMetrics() {
    return { ...this.animationMetrics };
  }
}

class ScrollTracker {
  constructor() {
    this.tracking = false;
    this.scrollMetrics = {
      averageFrameRate: 58,
      scrollJank: 0.05,
      contentUpdatesBlocked: false
    };
  }

  startTracking() {
    this.tracking = true;
  }

  stopTracking() {
    this.tracking = false;
  }

  getMetrics() {
    return { ...this.scrollMetrics };
  }
}

class VirtualScrollTracker {
  constructor() {
    this.tracking = false;
    this.virtualScrollMetrics = {
      averageRenderTime: 12,
      memoryUsage: 25 * 1024 * 1024, // 25MB
      virtualizedCorrectly: true
    };
  }

  startTracking() {
    this.tracking = true;
  }

  stopTracking() {
    this.tracking = false;
  }

  getMetrics() {
    return { ...this.virtualScrollMetrics };
  }
}
