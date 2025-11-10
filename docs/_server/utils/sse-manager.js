/**
 * Unified SSE Manager
 * Handles Server-Sent Events for all progress types (self-assessment, kata, lab)
 */

import { EventEmitter } from 'events';

class UnifiedSSEManager extends EventEmitter {
  constructor() {
    super();
    this.clients = new Map(); // Map of client IDs to client info
    this.progressStreams = new Map(); // Map of progress types to client sets
    this.eventHistory = new Map(); // Map of progress types to recent events
    this.maxHistorySize = 100; // Maximum number of events to keep in history
    this.maxConnections = 500; // Maximum concurrent connections
    this.maxProgressTypes = 100; // Maximum number of progress types
    this.eventExpirationHours = 24; // Hours after which events expire
    this.connectionTimeoutHours = 2; // Hours after which inactive connections timeout
    this.heartbeatInterval = 30000; // 30 seconds heartbeat
    this.heartbeatTimer = null;

    // Set EventEmitter max listeners to prevent memory leak warnings
    this.setMaxListeners(50);

    // Initialize progress type streams
    this.initializeProgressStreams();

    // Start heartbeat
    this.startHeartbeat();
  }

  /**
   * Initialize progress type streams
   */
  initializeProgressStreams() {
    const progressTypes = ['self-assessment', 'kata-progress', 'lab-progress'];

    progressTypes.forEach(type => {
      this.progressStreams.set(type, new Set());
      this.eventHistory.set(type, []);
    });
  }

  /**
   * Start heartbeat to keep connections alive
   */
  startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      this.broadcastHeartbeat();
    }, this.heartbeatInterval);
  }

  /**
   * Stop heartbeat
   */
  stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  /**
   * Generate unique client ID
   * @returns {string} Unique client ID
   */
  generateClientId() {
    return `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Add SSE client
   * @param {Object} res - Express response object
   * @param {string} progressType - Progress type to subscribe to
   * @param {Object} options - Client options
   * @returns {string|null} Client ID or null if rejected
   */
  addClient(res, progressType, options = {}) {
    // Enforce connection limit
    if (this.clients.size >= this.maxConnections) {
      console.warn(`[SSE] Connection limit reached (${this.maxConnections}), rejecting new client`);
      return null;
    }

    // Enforce progress type limit
    const finalProgressType = progressType || 'general';
    if (!this.progressStreams.has(finalProgressType) && this.progressStreams.size >= this.maxProgressTypes) {
      console.warn(`[SSE] Progress type limit reached (${this.maxProgressTypes}), rejecting new type: ${finalProgressType}`);
      return null;
    }

    const clientId = this.generateClientId();
    const { sendHistory = true, heartbeat = true } = options;

    // Check if this is a mock response object (for testing) or real response
    const isMockResponse = res && typeof res.writeHead === 'function' && typeof res.write === 'function';
    const isRealResponse = res && res.headersSent !== undefined;
    const isValidResponse = isRealResponse || isMockResponse;

    if (isValidResponse) {
      // Set SSE headers for real responses
      if (isRealResponse && !res.headersSent) {
        res.writeHead(200, {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Cache-Control'
        });
      } else if (isMockResponse) {
        // For mock responses, just call writeHead
        res.writeHead(200, {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Cache-Control'
        });
      }
    }

    // Store client info (always store, even for invalid responses to support testing)
    const clientInfo = {
      id: clientId,
      response: res,
      progressType: finalProgressType,
      connectedAt: new Date().toISOString(),
      lastActivity: new Date().toISOString(),
      heartbeat,
      active: true
    };

    this.clients.set(clientId, clientInfo);

    // Add to progress type stream
    if (!this.progressStreams.has(finalProgressType)) {
      this.progressStreams.set(finalProgressType, new Set());
      this.eventHistory.set(finalProgressType, []);
    }
    this.progressStreams.get(finalProgressType).add(clientId);

    // Send welcome message
    this.sendToClient(clientId, {
      type: 'connection',
      data: {
        clientId,
        progressType: finalProgressType,
        connectedAt: clientInfo.connectedAt,
        message: 'SSE connection established'
      }
    });

    // Send recent events if requested
    if (sendHistory && this.eventHistory.has(finalProgressType)) {
      const history = this.eventHistory.get(finalProgressType);
      history.forEach(event => {
        this.sendToClient(clientId, {
          type: 'history',
          data: event
        });
      });
    }

    // Handle client disconnect (only for real responses)
    if (isRealResponse) {
      res.on('close', () => {
        this.removeClient(clientId);
      });

      res.on('error', () => {
        this.removeClient(clientId);
      });
    }

    // Emit client connected event
    this.emit('clientConnected', { clientId, progressType: finalProgressType });

    // Start heartbeat if this is the first client
    if (this.clients.size === 1 && !this.isHeartbeatActive()) {
      this.startHeartbeat();
    }

    return clientId;
  }

  /**
   * Remove SSE client
   * @param {string} clientId - Client ID to remove
   */
  removeClient(clientId) {
    const clientInfo = this.clients.get(clientId);

    if (clientInfo) {
      // Mark as inactive
      clientInfo.active = false;

      // Remove from progress type stream
      if (this.progressStreams.has(clientInfo.progressType)) {
        const progressStream = this.progressStreams.get(clientInfo.progressType);
        progressStream.delete(clientId);

        // Clean up empty progress streams
        if (progressStream.size === 0) {
          this.progressStreams.delete(clientInfo.progressType);
          // Keep event history for a while in case clients reconnect
        }
      }

      // Remove from clients map
      this.clients.delete(clientId);

      // Stop heartbeat if no clients remain
      if (this.clients.size === 0 && this.isHeartbeatActive()) {
        this.stopHeartbeat();
      }

      // Emit client disconnected event
      this.emit('clientDisconnected', { clientId, progressType: clientInfo.progressType });
    }
  }

  /**
   * Send event to specific client
   * @param {string} clientId - Client ID
   * @param {Object} event - Event data
   */
  sendToClient(clientId, event) {
    const clientInfo = this.clients.get(clientId);

    if (clientInfo && clientInfo.active && clientInfo.response) {
      // Validate response object has required methods
      if (typeof clientInfo.response.write !== 'function') {
        console.warn(`Client ${clientId} has invalid response object, removing`);
        this.removeClient(clientId);
        return;
      }

      try {
        const eventData = this.formatSSEEvent(event);
        clientInfo.response.write(eventData);

        // Update last activity
        clientInfo.lastActivity = new Date().toISOString();
      } catch (error) {
        console.error(`Error sending to client ${clientId}:`, error);
        this.removeClient(clientId);
      }
    }
  }

  /**
   * Broadcast event to all clients of a progress type
   * @param {string} progressType - Progress type
   * @param {Object} event - Event data
   */
  broadcastToProgressType(progressType, event) {
    const clients = this.progressStreams.get(progressType);

    if (clients) {
      // Add to history
      this.addToHistory(progressType, event);

      // Send to all clients
      clients.forEach(clientId => {
        this.sendToClient(clientId, event);
      });
    }

    // Emit broadcast event
    this.emit('broadcast', { progressType, event, clientCount: clients ? clients.size : 0 });
  }

  /**
   * Broadcast event to all clients
   * @param {Object} event - Event data
   */
  broadcastToAll(event) {
    this.progressStreams.forEach((clients, progressType) => {
      this.broadcastToProgressType(progressType, event);
    });
  }

  /**
   * Send heartbeat to all clients
   */
  broadcastHeartbeat() {
    const heartbeatEvent = {
      type: 'heartbeat',
      data: {
        timestamp: new Date().toISOString(),
        activeClients: this.getActiveClientCount()
      }
    };

    this.clients.forEach((clientInfo, clientId) => {
      if (clientInfo.heartbeat && clientInfo.active) {
        this.sendToClient(clientId, heartbeatEvent);
      }
    });
  }

  /**
   * Add event to history
   * @param {string} progressType - Progress type
   * @param {Object} event - Event data
   */
  addToHistory(progressType, event) {
    // Initialize history for progress type if it doesn't exist
    if (!this.eventHistory.has(progressType)) {
      this.eventHistory.set(progressType, []);
    }

    const history = this.eventHistory.get(progressType);

    // Add timestamp if not present
    if (!event.timestamp) {
      event.timestamp = new Date().toISOString();
    }

    history.push(event);

    // Limit history size
    if (history.length > this.maxHistorySize) {
      history.shift(); // Remove oldest event
    }
  }

  /**
   * Format event for SSE
   * @param {Object} event - Event data
   * @returns {string} Formatted SSE event
   */
  formatSSEEvent(event) {
    const { type = 'message', data, id, retry } = event;

    let formatted = '';

    if (id) {
      formatted += `id: ${id}\n`;
    }

    if (retry) {
      formatted += `retry: ${retry}\n`;
    }

    formatted += `event: ${type}\n`;
    formatted += `data: ${JSON.stringify(data)}\n\n`;

    return formatted;
  }

  /**
   * Get active client count
   * @returns {number} Number of active clients
   */
  getActiveClientCount() {
    return this.clients.size;
  }

  /**
   * Get client count by progress type
   * @param {string} progressType - Progress type
   * @returns {number} Number of clients for progress type
   */
  getClientCountByType(progressType) {
    const clients = this.progressStreams.get(progressType);
    return clients ? clients.size : 0;
  }

  /**
   * Get client statistics
   * @returns {Object} Client statistics
   */
  getClientStats() {
    const stats = {
      totalClients: this.getActiveClientCount(),
      clientsByType: {},
      connectionTimes: [],
      uptime: process.uptime()
    };

    this.progressStreams.forEach((clients, progressType) => {
      stats.clientsByType[progressType] = clients.size;
    });

    this.clients.forEach(clientInfo => {
      stats.connectionTimes.push({
        clientId: clientInfo.id,
        connectedAt: clientInfo.connectedAt,
        progressType: clientInfo.progressType
      });
    });

    return stats;
  }

  /**
   * Get maximum allowed connections
   * @returns {number} Maximum connections
   */
  getMaxConnections() {
    return this.maxConnections;
  }

  /**
   * Get maximum allowed progress types
   * @returns {number} Maximum progress types
   */
  getMaxProgressTypes() {
    return this.maxProgressTypes;
  }

  /**
   * Get maximum event history size
   * @returns {number} Maximum history size
   */
  getMaxHistorySize() {
    return this.maxHistorySize;
  }

  /**
   * Get event history for a progress type
   * @param {string} progressType - Progress type
   * @returns {Array} Event history
   */
  getEventHistory(progressType) {
    return this.eventHistory.get(progressType) || [];
  }

  /**
   * Check if progress type exists
   * @param {string} progressType - Progress type
   * @returns {boolean} True if exists
   */
  hasProgressType(progressType) {
    return this.progressStreams.has(progressType);
  }

  /**
   * Get all progress types
   * @returns {Array} List of progress types
   */
  getProgressTypes() {
    return Array.from(this.progressStreams.keys());
  }

  /**
   * Check if heartbeat is active
   * @returns {boolean} True if heartbeat is running
   */
  isHeartbeatActive() {
    return this.heartbeatTimer !== null;
  }

  /**
   * Get client information
   * @param {string} clientId - Client ID
   * @returns {Object|null} Client info or null
   */
  getClientInfo(clientId) {
    return this.clients.get(clientId) || null;
  }

  /**
   * Get memory usage statistics
   * @returns {Object} Memory statistics
   */
  getMemoryStats() {
    let totalEventHistory = 0;
    this.eventHistory.forEach(history => {
      totalEventHistory += history.length;
    });

    // Rough estimation of memory usage
    const estimatedMemoryUsage =
      (this.clients.size * 1000) + // ~1KB per client
      (totalEventHistory * 500) + // ~500 bytes per event
      (this.progressStreams.size * 100); // ~100 bytes per progress type

    return {
      clientCount: this.clients.size,
      progressTypeCount: this.progressStreams.size,
      totalEventHistory,
      estimatedMemoryUsage,
      isHeartbeatActive: this.isHeartbeatActive()
    };
  }

  /**
   * Check if cleanup should be triggered based on memory usage
   * @returns {boolean} True if cleanup should be triggered
   */
  shouldTriggerCleanup() {
    const stats = this.getMemoryStats();

    // Trigger cleanup if memory usage exceeds thresholds
    return (
      stats.clientCount > this.maxConnections * 0.8 ||
      stats.totalEventHistory > this.maxHistorySize * this.progressStreams.size * 0.8 ||
      stats.estimatedMemoryUsage > 10000000 // 10MB threshold
    );
  }

  /**
   * Cleanup expired events from history
   */
  cleanupExpiredEvents() {
    const expirationTime = Date.now() - (this.eventExpirationHours * 60 * 60 * 1000);

    this.eventHistory.forEach((history, progressType) => {
      const validEvents = history.filter(event => {
        const eventTime = new Date(event.timestamp).getTime();
        return eventTime > expirationTime;
      });

        if (validEvents.length !== history.length) {
          this.eventHistory.set(progressType, validEvents);
        }
    });
  }

  /**
   * Cleanup unused progress types that have no clients and no recent events
   */
  cleanupUnusedProgressTypes() {
    const unusedTypes = [];

    this.progressStreams.forEach((clients, progressType) => {
      // Skip initial progress types that should always exist
      if (['self-assessment', 'kata-progress', 'lab-progress'].includes(progressType)) {
        return;
      }

      // Check if type has no clients and no recent events
      if (clients.size === 0) {
        const history = this.eventHistory.get(progressType) || [];
        const hasRecentEvents = history.some(event => {
          const eventTime = new Date(event.timestamp).getTime();
          const oneHourAgo = Date.now() - (60 * 60 * 1000);
          return eventTime > oneHourAgo;
        });

        if (!hasRecentEvents) {
          unusedTypes.push(progressType);
        }
      }
    });

      // Remove unused types
      unusedTypes.forEach(type => {
        this.progressStreams.delete(type);
        this.eventHistory.delete(type);
      });
  }

  /**
   * Cleanup stale connections that haven't been active
   */
  cleanupStaleConnections() {
    const timeoutTime = Date.now() - (this.connectionTimeoutHours * 60 * 60 * 1000);
    const staleClients = [];

    this.clients.forEach((clientInfo, clientId) => {
      const lastActivity = new Date(clientInfo.lastActivity || clientInfo.connectedAt).getTime();
      if (lastActivity < timeoutTime) {
        staleClients.push(clientId);
      }
    });

    staleClients.forEach(clientId => {
      this.removeClient(clientId);
    });
  }

  /**
   * Cleanup resources
   */
  cleanup() {
    // Stop heartbeat first to prevent new operations
    this.stopHeartbeat();

    // Close all client connections gracefully
    this.clients.forEach((clientInfo, clientId) => {
      if (clientInfo.active && clientInfo.response) {
        try {
          // Try to send a final message
          if (typeof clientInfo.response.write === 'function') {
            const closeEvent = this.formatSSEEvent({
              type: 'connection',
              data: { message: 'Server shutting down', type: 'close' }
            });
            clientInfo.response.write(closeEvent);
          }

          // End the response
          if (typeof clientInfo.response.end === 'function') {
            clientInfo.response.end();
          }
        } catch {
          console.error(`Error closing client ${clientId}:`);
        }
      }
    });

    // Clear all data structures
    this.clients.clear();
    this.progressStreams.clear();
    this.eventHistory.clear();

    // Remove all event listeners to prevent memory leaks
    this.removeAllListeners();

    // Re-initialize basic structure for potential restart
    this.initializeProgressStreams();
  }
}

// Create singleton instance
const sseManager = new UnifiedSSEManager();

/**
 * Broadcasts manifest update notification to all clients subscribed to the learning-path-manifest channel.
 * @param {Object} data - The manifest update data to broadcast
 */
export function broadcastManifestUpdate(data) {
  sseManager.broadcastToProgressType('learning-path-manifest', {
    type: 'manifest-update',
    data
  });
}

export default sseManager;
