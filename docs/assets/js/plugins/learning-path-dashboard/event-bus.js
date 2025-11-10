export const eventBusMixin = {
  /**
   * Initialize event bus data structures
   * @private
   */
  _initializeEventBus() {
    this.eventListeners = {};
    this.eventHandlers = new Map();
  },

  /**
   * Register an event handler
   */
  on(event, handler) {
    this.initializeEventStorage(event);
    this.eventListeners[event].push(handler);
    this.eventHandlers.get(event).push(handler);
  },

  /**
   * Remove event handlers
   */
  off(event, handler) {
    if (handler) {
      this.removeSpecificHandler(event, handler);
    } else {
      this.removeAllHandlers(event);
    }
  },

  /**
   * Emit an event to registered handlers
   */
  emit(event, data) {
    if (this.eventListeners[event]) {
      this.eventListeners[event].forEach(handler => {
        try {
          handler(data);
        } catch (error) {
          this.logError(`Error in event handler for ${event}:`, error);
        }
      });
    }
  },

  /**
   * Ensure event storage structures exist
   */
  initializeEventStorage(event) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
  },

  /**
   * Remove single handler
   */
  removeSpecificHandler(event, handler) {
    if (this.eventListeners[event]) {
      const index = this.eventListeners[event].indexOf(handler);
      if (index > -1) {
        this.eventListeners[event].splice(index, 1);
      }
    }

    if (this.eventHandlers.has(event)) {
      const handlers = this.eventHandlers.get(event);
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
        if (handlers.length === 0) {
          this.eventHandlers.delete(event);
        }
      }
    }
  },

  /**
   * Remove all handlers for an event
   */
  removeAllHandlers(event) {
    if (this.eventListeners[event]) {
      delete this.eventListeners[event];
    }
    this.eventHandlers.delete(event);
  },

  /**
   * Aliases retained for backward compatibility with tests
   */
  addEventHandler(event, handler) {
    this.on(event, handler);
  },

  removeEventHandler(event, handler) {
    this.removeSpecificHandler(event, handler);
  },

  removeAllEventHandlers(event) {
    this.removeAllHandlers(event);
  },

  /**
   * Dispatch custom event on containers
   * @param {string} eventName - Event name
   * @param {Object} detail - Event detail data
   */
  dispatchContainerEvent(eventName, detail = {}) {
    if (!this.containers) {
      return;
    }

    this.containers.forEach(container => {
      const event = new CustomEvent(eventName, {
        detail,
        bubbles: true,
        cancelable: true
      });
      container.dispatchEvent(event);
    });

    this.log('debug', `Dispatched ${eventName} event on ${this.containers.length} containers`);
  }
};
