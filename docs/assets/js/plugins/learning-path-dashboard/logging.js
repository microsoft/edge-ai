const LOG_PREFIX = 'LearningPathDashboard';

export const loggingMixin = {
  log(level, message, ...args) {
    const timestamp = new Date().toISOString();
    const normalizedLevel = typeof level === 'string' ? level.toUpperCase() : 'INFO';
    const formattedMessage = `[${timestamp}] [${LOG_PREFIX}:${normalizedLevel}] ${message}`;

    switch (normalizedLevel) {
      case 'DEBUG':
        if (this?.config?.debug) {
          console.log(formattedMessage, ...args);
        }
        break;
      case 'WARN':
      case 'WARNING':
        console.warn(formattedMessage, ...args);
        break;
      case 'ERROR':
        console.error(formattedMessage, ...args);
        break;
      default:
        console.log(formattedMessage, ...args);
    }
  },

  logWarning(message, ...args) {
    this.log('warning', message, ...args);
  },

  logError(message, ...args) {
    this.log('error', message, ...args);
  }
};
