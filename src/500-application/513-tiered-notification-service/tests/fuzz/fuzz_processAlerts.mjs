// Jazzer.js fuzz harness for tiered-notification-service processAlerts module.
// Targets pure functions exported from processAlerts.js (parseAlertPayload,
// extractSeverity, buildDedupKey, validateWebhookUrl).
// trigger fuzz CI
import { parseAlertPayload, extractSeverity, buildDedupKey, validateWebhookUrl }
  from '../../src/functions/processAlerts.js';

export function fuzz(buffer) {
  const input = buffer.toString('utf8');
  try {
    const alert = parseAlertPayload(input);
    if (alert && typeof alert === 'object') {
      const severity = extractSeverity(alert);
      buildDedupKey(alert, severity);
    }
  } catch (e) {
    if (!(e instanceof SyntaxError || e instanceof TypeError || e instanceof RangeError)) {
      throw e;
    }
  }
  try {
    validateWebhookUrl(input);
  } catch (e) {
    if (!(e instanceof TypeError || e instanceof Error)) {
      throw e;
    }
  }
}
