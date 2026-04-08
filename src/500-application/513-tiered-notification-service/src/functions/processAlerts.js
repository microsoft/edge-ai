/**
 * Azure Function: processAlerts
 *
 * Event Hub triggered function that processes inference alert messages from
 * the AIO dataflow pipeline. Parses InferenceResultMessage payloads, filters
 * by severity threshold, deduplicates repeated alerts, and dispatches webhook
 * notifications with severity-tiered routing.
 *
 * Severity tiers:
 *   critical/high — immediate webhook dispatch
 *   medium        — buffered into periodic digest
 *   low           — logged for dashboard consumption only
 *
 * Environment variables:
 *   EventHubConnection           - Event Hub namespace connection string (Listen)
 *   ALERT_EVENTHUB_NAME          - Event Hub name for alert messages
 *   ALERT_EVENTHUB_CONSUMER_GROUP - Consumer group for this function
 *   NOTIFICATION_WEBHOOK_URL     - Destination webhook URL
 *   ALERT_SEVERITY_THRESHOLD     - Minimum severity: low, medium, high, critical
 *   DEDUP_WINDOW_MS              - Deduplication window in milliseconds (default: 30000)
 *   DIGEST_INTERVAL_MS           - Medium-severity digest interval in ms (default: 300000)
 */

import { app } from "@azure/functions";

const SEVERITY_LEVELS = Object.freeze({
  low: 0,
  medium: 1,
  high: 2,
  critical: 3,
});

const DEDUP_WINDOW_MS = Number.isNaN(parseInt(process.env.DEDUP_WINDOW_MS, 10)) ? 30000 : parseInt(process.env.DEDUP_WINDOW_MS, 10);
const DIGEST_INTERVAL_MS = Number.isNaN(parseInt(process.env.DIGEST_INTERVAL_MS, 10)) ? 300000 : parseInt(process.env.DIGEST_INTERVAL_MS, 10);

/**
 * Validate a webhook URL to prevent SSRF and ensure HTTPS.
 * @param {string} urlString - URL to validate
 * @returns {string} The validated URL
 * @throws {Error} If the URL is invalid, non-HTTPS, or targets a private network
 */
function validateWebhookUrl(urlString) {
  const parsed = new URL(urlString);

  if (parsed.protocol !== "https:") {
    throw new Error(`Webhook URL must use HTTPS, got: ${parsed.protocol}`);
  }

  const hostname = parsed.hostname.toLowerCase();
  const blockedPatterns = [
    /^localhost$/,
    /^127\./,
    /^10\./,
    /^172\.(1[6-9]|2\d|3[01])\./,
    /^192\.168\./,
    /^169\.254\./,
    /^0\./,
    /^\[::1\]$/,
    /^\[fd/,
    /^\[fe80:/,
  ];

  for (const pattern of blockedPatterns) {
    if (pattern.test(hostname)) {
      throw new Error(`Webhook URL must not target private/internal addresses: ${hostname}`);
    }
  }

  return urlString;
}

/**
 * Classify a webhook URL by provider using secure hostname matching.
 * Parses the URL and compares the hostname with exact or suffix checks
 * to prevent subdomain-prefix bypass attacks (CWE-020).
 * @param {string} webhookUrl - Webhook destination URL
 * @returns {"teams"|"slack"|"generic"} Provider type
 */
function getWebhookType(webhookUrl) {
  try {
    const { hostname } = new URL(webhookUrl);
    const host = hostname.toLowerCase();
    if (
      host === "webhook.office.com" ||
      host.endsWith(".webhook.office.com") ||
      host === "logic.azure.com" ||
      host.endsWith(".logic.azure.com")
    ) {
      return "teams";
    }
    if (host === "hooks.slack.com" || host.endsWith(".hooks.slack.com")) {
      return "slack";
    }
  } catch {
    // Malformed URL falls through to generic
  }
  return "generic";
}

/**
 * In-memory deduplication cache.
 * Key: "source|label|severity" → value: timestamp of last dispatched alert.
 * Entries older than DEDUP_WINDOW_MS are evicted on each access.
 *
 * Limitation: this cache is per-instance and non-durable. On Azure Functions
 * Consumption plan, cold starts reset it and scale-out creates independent
 * copies. Deduplication is therefore best-effort — duplicate webhooks may
 * fire during scale-out events. For stricter guarantees, replace with
 * Azure Table Storage or Redis.
 */
const dedupCache = new Map();

/**
 * Buffer for medium-severity alerts awaiting digest dispatch.
 * Flushed when DIGEST_INTERVAL_MS elapses or at the end of each batch.
 *
 * Limitation: buffer contents are lost on cold start. To prevent silent
 * data loss, the handler forces a flush at the end of every Event Hub
 * batch regardless of the digest interval.
 */
const digestBuffer = [];
let lastDigestFlush = Date.now();

/**
 * Build a dedup key from an alert's identifying fields.
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity
 * @returns {string} Dedup key
 */
function buildDedupKey(alert, severity) {
  const source = alert.source ?? alert.device_id ?? alert.topic ?? "unknown";
  const label = alert.label ?? alert.class_name ?? "unknown";
  return `${source}|${label}|${severity}`;
}

/**
 * Check whether an alert is a duplicate within the dedup window.
 * Evicts stale entries and records the current alert if it is new.
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity
 * @returns {boolean} True if this alert is a duplicate that should be suppressed
 */
function isDuplicate(alert, severity) {
  const now = Date.now();
  const key = buildDedupKey(alert, severity);

  // Evict stale entries
  for (const [k, ts] of dedupCache) {
    if (now - ts > DEDUP_WINDOW_MS) {
      dedupCache.delete(k);
    }
  }

  const lastSeen = dedupCache.get(key);
  if (lastSeen !== undefined && now - lastSeen < DEDUP_WINDOW_MS) {
    return true;
  }

  dedupCache.set(key, now);
  return false;
}

/**
 * Parse an inference alert payload from Event Hub message body.
 * Handles both raw JSON strings and pre-parsed objects.
 * @param {string|object} body - Event Hub message body
 * @returns {object|null} Parsed alert or null on failure
 */
function parseAlertPayload(body) {
  if (!body) {
    return null;
  }
  try {
    if (Buffer.isBuffer(body) || body instanceof Uint8Array) {
      body = body.toString('utf8');
    }
    const parsed = typeof body === "string" ? JSON.parse(body) : body;
    return parsed;
  } catch {
    return null;
  }
}

/**
 * Determine the severity level string from an inference result payload.
 * Supports both explicit severity fields and confidence-based thresholds.
 * @param {object} alert - Parsed alert payload
 * @returns {string} Severity level: low, medium, high, or critical
 */
function extractSeverity(alert) {
  if (alert.severity) {
    return alert.severity.toLowerCase();
  }

  const confidence = alert.confidence ?? alert.score ?? 0;
  if (confidence >= 0.95) {
    return "critical";
  }
  if (confidence >= 0.8) {
    return "high";
  }
  if (confidence >= 0.5) {
    return "medium";
  }
  return "low";
}

/**
 * Check whether a severity level meets or exceeds the configured threshold.
 * @param {string} severity - Alert severity level
 * @param {string} threshold - Minimum severity threshold
 * @returns {boolean} True if severity meets threshold
 */
function meetsSeverityThreshold(severity, threshold) {
  const severityRank = SEVERITY_LEVELS[severity] ?? 0;
  const thresholdRank = SEVERITY_LEVELS[threshold] ?? 0;
  return severityRank >= thresholdRank;
}

/**
 * Build a Teams Adaptive Card payload for an inference alert.
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity level
 * @returns {object} Teams webhook-compatible message payload
 */
function buildTeamsPayload(alert, severity) {
  const severityColors = {
    critical: "attention",
    high: "warning",
    medium: "accent",
    low: "good",
  };

  const timestamp = alert.timestamp ?? new Date().toISOString();
  const model = alert.model_name ?? alert.model ?? "unknown";
  const source = alert.source ?? alert.device_id ?? alert.topic ?? "edge";

  return {
    type: "message",
    attachments: [
      {
        contentType: "application/vnd.microsoft.card.adaptive",
        content: {
          $schema: "http://adaptivecards.io/schemas/adaptive-card.json",
          type: "AdaptiveCard",
          version: "1.4",
          body: [
            {
              type: "TextBlock",
              text: `Edge AI Alert — ${severity.toUpperCase()}`,
              weight: "bolder",
              size: "medium",
              color: severityColors[severity] ?? "default",
            },
            {
              type: "FactSet",
              facts: [
                { title: "Severity", value: severity.toUpperCase() },
                { title: "Source", value: String(source) },
                { title: "Model", value: String(model) },
                { title: "Timestamp", value: String(timestamp) },
                {
                  title: "Confidence",
                  value: String(alert.confidence ?? alert.score ?? "N/A"),
                },
                {
                  title: "Label",
                  value: String(alert.label ?? alert.class_name ?? "N/A"),
                },
              ],
            },
          ],
        },
      },
    ],
  };
}

/**
 * Build a Slack Block Kit payload for an inference alert.
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity level
 * @returns {object} Slack webhook-compatible message payload
 */
function buildSlackPayload(alert, severity) {
  const timestamp = alert.timestamp ?? new Date().toISOString();
  const model = alert.model_name ?? alert.model ?? "unknown";
  const source = alert.source ?? alert.device_id ?? alert.topic ?? "edge";
  const label = alert.label ?? alert.class_name ?? "N/A";
  const confidence = alert.confidence ?? alert.score ?? "N/A";

  return {
    blocks: [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: `Edge AI Alert — ${severity.toUpperCase()}`,
        },
      },
      {
        type: "section",
        fields: [
          { type: "mrkdwn", text: `*Severity:* ${severity.toUpperCase()}` },
          { type: "mrkdwn", text: `*Source:* ${source}` },
          { type: "mrkdwn", text: `*Model:* ${model}` },
          { type: "mrkdwn", text: `*Timestamp:* ${timestamp}` },
          { type: "mrkdwn", text: `*Confidence:* ${confidence}` },
          { type: "mrkdwn", text: `*Label:* ${label}` },
        ],
      },
    ],
  };
}

/**
 * Build a generic webhook JSON payload for an inference alert.
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity level
 * @returns {object} Generic JSON payload
 */
function buildGenericPayload(alert, severity) {
  return {
    event: "edge_ai_alert",
    severity,
    timestamp: alert.timestamp ?? new Date().toISOString(),
    source: alert.source ?? alert.device_id ?? alert.topic ?? "edge",
    model: alert.model_name ?? alert.model ?? "unknown",
    label: alert.label ?? alert.class_name ?? null,
    confidence: alert.confidence ?? alert.score ?? null,
    details: alert,
  };
}

/**
 * Detect webhook type from URL and build the appropriate payload.
 * @param {string} webhookUrl - Destination webhook URL
 * @param {object} alert - Parsed alert payload
 * @param {string} severity - Resolved severity level
 * @returns {object} Webhook-appropriate payload
 */
function buildWebhookPayload(webhookUrl, alert, severity) {
  const type = getWebhookType(webhookUrl);
  if (type === "teams") {
    return buildTeamsPayload(alert, severity);
  }
  if (type === "slack") {
    return buildSlackPayload(alert, severity);
  }
  return buildGenericPayload(alert, severity);
}

/**
 * Dispatch a payload to the configured webhook URL.
 * Retries once on transient failure: server errors (HTTP 5xx) are retried
 * inside the response branch, network/timeout errors are retried via the
 * catch branch. Client errors (4xx) fail immediately without retry.
 * @param {string} webhookUrl - Destination URL
 * @param {object} payload - JSON payload to send
 * @param {object} context - Function invocation context for logging
 * @returns {Promise<boolean>} True if dispatch succeeded
 */
async function dispatchWebhook(webhookUrl, payload, context) {
  const maxAttempts = 2;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(10_000),
      });

      if (response.ok) {
        return true;
      }

      const status = response.status;
      if (status >= 500 && attempt < maxAttempts) {
        context.warn(`Webhook returned ${status}, retrying (attempt ${attempt}/${maxAttempts})`);
        continue;
      }

      context.error(`Webhook dispatch failed: HTTP ${status}`);
      return false;
    } catch (err) {
      if (attempt < maxAttempts) {
        context.warn(`Webhook request error: ${err.message}, retrying`);
        continue;
      }
      context.error(`Webhook dispatch error after ${maxAttempts} attempts: ${err.message}`);
      return false;
    }
  }
  return false;
}

/**
 * Build a digest summary payload combining multiple medium-severity alerts.
 * @param {string} webhookUrl - Destination webhook URL
 * @param {Array<{alert: object, severity: string}>} alerts - Buffered alerts
 * @returns {object} Webhook-appropriate digest payload
 */
function buildDigestPayload(webhookUrl, alerts) {
  const type = getWebhookType(webhookUrl);
  const summary = alerts.map((a) => {
    const source = a.alert.source ?? a.alert.device_id ?? a.alert.topic ?? "edge";
    const label = a.alert.label ?? a.alert.class_name ?? "N/A";
    const confidence = a.alert.confidence ?? a.alert.score ?? "N/A";
    return `${source}: ${label} (${confidence})`;
  });

  if (type === "teams") {
    return {
      type: "message",
      attachments: [
        {
          contentType: "application/vnd.microsoft.card.adaptive",
          content: {
            $schema: "http://adaptivecards.io/schemas/adaptive-card.json",
            type: "AdaptiveCard",
            version: "1.4",
            body: [
              {
                type: "TextBlock",
                text: `Edge AI Digest — ${alerts.length} MEDIUM alert(s)`,
                weight: "bolder",
                size: "medium",
                color: "accent",
              },
              {
                type: "TextBlock",
                text: summary.join("\n"),
                wrap: true,
              },
            ],
          },
        },
      ],
    };
  }

  if (type === "slack") {
    return {
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: `Edge AI Digest — ${alerts.length} MEDIUM alert(s)`,
          },
        },
        {
          type: "section",
          text: { type: "mrkdwn", text: summary.map((s) => `• ${s}`).join("\n") },
        },
      ],
    };
  }

  return {
    event: "edge_ai_digest",
    severity: "medium",
    count: alerts.length,
    timestamp: new Date().toISOString(),
    alerts: summary,
  };
}

/**
 * Flush the digest buffer if the interval has elapsed.
 * @param {string} webhookUrl - Destination webhook URL
 * @param {object} context - Function invocation context for logging
 * @param {boolean} force - Force flush regardless of interval
 * @returns {Promise<{dispatched: number, errors: number}>}
 */
async function flushDigestBuffer(webhookUrl, context, force = false) {
  const now = Date.now();
  if (!force && now - lastDigestFlush < DIGEST_INTERVAL_MS) {
    return { dispatched: 0, errors: 0 };
  }
  if (digestBuffer.length === 0) {
    lastDigestFlush = now;
    return { dispatched: 0, errors: 0 };
  }

  const items = digestBuffer.splice(0, digestBuffer.length);
  lastDigestFlush = now;
  context.log(`Flushing digest buffer: ${items.length} medium alert(s)`);

  const payload = buildDigestPayload(webhookUrl, items);
  const ok = await dispatchWebhook(webhookUrl, payload, context);
  return ok ? { dispatched: 1, errors: 0 } : { dispatched: 0, errors: 1 };
}

/**
 * Event Hub trigger handler. Processes a batch of alert messages with
 * deduplication, severity filtering, and tiered dispatch routing.
 */
app.eventHub("processAlerts", {
  connection: "EventHubConnection",
  eventHubName: "%ALERT_EVENTHUB_NAME%",
  consumerGroup: "%ALERT_EVENTHUB_CONSUMER_GROUP%",
  cardinality: "many",
  handler: async (messages, context) => {
    const rawWebhookUrl = process.env.NOTIFICATION_WEBHOOK_URL;
    const threshold = (process.env.ALERT_SEVERITY_THRESHOLD ?? "high").toLowerCase();

    if (!rawWebhookUrl) {
      context.error("NOTIFICATION_WEBHOOK_URL is not configured, skipping batch");
      return;
    }

    let webhookUrl;
    try {
      webhookUrl = validateWebhookUrl(rawWebhookUrl);
    } catch (err) {
      context.error(`Invalid NOTIFICATION_WEBHOOK_URL: ${err.message}`);
      return;
    }

    const batch = Array.isArray(messages) ? messages : [messages];
    context.log(`Processing ${batch.length} alert message(s), threshold: ${threshold}`);

    let dispatched = 0;
    let skipped = 0;
    let deduplicated = 0;
    let buffered = 0;
    let errors = 0;

    for (const message of batch) {
      const alert = parseAlertPayload(message);
      if (!alert) {
        context.warn("Skipping unparseable message");
        skipped++;
        continue;
      }

      const severity = extractSeverity(alert);
      if (!meetsSeverityThreshold(severity, threshold)) {
        context.log(`Alert severity '${severity}' below threshold '${threshold}', skipping`);
        skipped++;
        continue;
      }

      // Deduplication check
      if (isDuplicate(alert, severity)) {
        context.log(`Duplicate alert suppressed (dedup window ${DEDUP_WINDOW_MS}ms)`);
        deduplicated++;
        continue;
      }

      // Tiered severity routing
      if (severity === "low") {
        context.log(`Low-severity alert logged for dashboard (not dispatched)`);
        skipped++;
        continue;
      }

      if (severity === "medium") {
        digestBuffer.push({ alert, severity });
        buffered++;
        continue;
      }

      // Critical and high: immediate dispatch
      const payload = buildWebhookPayload(webhookUrl, alert, severity);
      const success = await dispatchWebhook(webhookUrl, payload, context);

      if (success) {
        dispatched++;
      } else {
        errors++;
      }
    }

    // Force digest flush at end of each batch to prevent data loss on cold start
    const digest = await flushDigestBuffer(webhookUrl, context, true);
    dispatched += digest.dispatched;
    errors += digest.errors;

    context.log(
      `Batch complete: ${dispatched} dispatched, ${skipped} skipped, ` +
      `${deduplicated} deduplicated, ${buffered} buffered, ${errors} errors`
    );
  },
});

export {
  SEVERITY_LEVELS,
  validateWebhookUrl,
  getWebhookType,
  buildDedupKey,
  parseAlertPayload,
  extractSeverity,
  meetsSeverityThreshold,
  buildTeamsPayload,
  buildSlackPayload,
  buildGenericPayload,
  buildWebhookPayload,
  buildDigestPayload,
};
