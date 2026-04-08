import { describe, it, expect } from 'vitest';
import {
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
} from '../../src/functions/processAlerts.js';

describe('SEVERITY_LEVELS', () => {
  it('contains all four severity tiers with correct rank order', () => {
    expect(SEVERITY_LEVELS).toEqual({
      low: 0,
      medium: 1,
      high: 2,
      critical: 3,
    });
  });

  it('is frozen and cannot be mutated', () => {
    expect(Object.isFrozen(SEVERITY_LEVELS)).toBe(true);
  });
});

describe('validateWebhookUrl', () => {
  it('accepts a valid HTTPS URL', () => {
    const url = 'https://webhook.example.com/hook';
    expect(validateWebhookUrl(url)).toBe(url);
  });

  it('rejects HTTP URLs', () => {
    expect(() => validateWebhookUrl('http://webhook.example.com/hook'))
      .toThrow('Webhook URL must use HTTPS');
  });

  it('rejects malformed URLs', () => {
    expect(() => validateWebhookUrl('not-a-url')).toThrow();
  });

  it('rejects localhost', () => {
    expect(() => validateWebhookUrl('https://localhost/hook'))
      .toThrow('private/internal');
  });

  it('rejects 127.x.x.x loopback addresses', () => {
    expect(() => validateWebhookUrl('https://127.0.0.1/hook'))
      .toThrow('private/internal');
  });

  it('rejects 10.x.x.x private addresses', () => {
    expect(() => validateWebhookUrl('https://10.0.0.1/hook'))
      .toThrow('private/internal');
  });

  it('rejects 172.16-31.x.x private addresses', () => {
    expect(() => validateWebhookUrl('https://172.16.0.1/hook'))
      .toThrow('private/internal');
  });

  it('rejects 192.168.x.x private addresses', () => {
    expect(() => validateWebhookUrl('https://192.168.1.1/hook'))
      .toThrow('private/internal');
  });

  it('rejects link-local 169.254.x.x addresses', () => {
    expect(() => validateWebhookUrl('https://169.254.1.1/hook'))
      .toThrow('private/internal');
  });

  it('rejects IPv6 loopback [::1]', () => {
    expect(() => validateWebhookUrl('https://[::1]/hook'))
      .toThrow('private/internal');
  });
});

describe('getWebhookType', () => {
  describe('Teams detection', () => {
    it('returns "teams" for webhook.office.com', () => {
      expect(getWebhookType('https://webhook.office.com/webhook/abc')).toBe('teams');
    });

    it('returns "teams" for subdomains of webhook.office.com', () => {
      expect(getWebhookType('https://tenant.webhook.office.com/hook')).toBe('teams');
    });

    it('returns "teams" for logic.azure.com', () => {
      expect(getWebhookType('https://logic.azure.com/workflows/123')).toBe('teams');
    });

    it('returns "teams" for subdomains of logic.azure.com', () => {
      expect(getWebhookType('https://prod.logic.azure.com/workflows/123')).toBe('teams');
    });

    it('rejects subdomain-prefix bypass for webhook.office.com', () => {
      expect(getWebhookType('https://evil-webhook.office.com.attacker.com/hook')).toBe('generic');
    });

    it('rejects subdomain-prefix bypass for logic.azure.com', () => {
      expect(getWebhookType('https://evil-logic.azure.com.attacker.com/hook')).toBe('generic');
    });
  });

  describe('Slack detection', () => {
    it('returns "slack" for hooks.slack.com', () => {
      expect(getWebhookType('https://hooks.slack.com/services/T00/B00/abc')).toBe('slack');
    });

    it('returns "slack" for subdomains of hooks.slack.com', () => {
      expect(getWebhookType('https://app.hooks.slack.com/services/T00')).toBe('slack');
    });

    it('rejects subdomain-prefix bypass for hooks.slack.com', () => {
      expect(getWebhookType('https://evil-hooks.slack.com.attacker.com/hook')).toBe('generic');
    });
  });

  describe('Generic fallback', () => {
    it('returns "generic" for unknown domains', () => {
      expect(getWebhookType('https://custom.webhook.example.com/hook')).toBe('generic');
    });

    it('returns "generic" for malformed URLs', () => {
      expect(getWebhookType('not-a-url')).toBe('generic');
    });
  });
});

describe('buildDedupKey', () => {
  it('builds key from source, label, and severity', () => {
    const alert = { source: 'camera-1', label: 'person' };
    expect(buildDedupKey(alert, 'high')).toBe('camera-1|person|high');
  });

  it('falls back to device_id when source is absent', () => {
    const alert = { device_id: 'dev-42', label: 'fire' };
    expect(buildDedupKey(alert, 'critical')).toBe('dev-42|fire|critical');
  });

  it('falls back to topic when source and device_id are absent', () => {
    const alert = { topic: 'mqtts://alerts', class_name: 'smoke' };
    expect(buildDedupKey(alert, 'medium')).toBe('mqtts://alerts|smoke|medium');
  });

  it('uses "unknown" defaults when no identifying fields exist', () => {
    expect(buildDedupKey({}, 'low')).toBe('unknown|unknown|low');
  });
});

describe('parseAlertPayload', () => {
  it('returns null for falsy input', () => {
    expect(parseAlertPayload(null)).toBeNull();
    expect(parseAlertPayload(undefined)).toBeNull();
    expect(parseAlertPayload('')).toBeNull();
  });

  it('parses a JSON string', () => {
    const result = parseAlertPayload('{"severity":"high"}');
    expect(result).toEqual({ severity: 'high' });
  });

  it('returns an object as-is', () => {
    const obj = { severity: 'low' };
    expect(parseAlertPayload(obj)).toBe(obj);
  });

  it('parses a Buffer containing JSON', () => {
    const buf = Buffer.from('{"label":"fire"}');
    expect(parseAlertPayload(buf)).toEqual({ label: 'fire' });
  });

  it('returns null for plain Uint8Array (only Buffer is decoded)', () => {
    const arr = new TextEncoder().encode('{"label":"smoke"}');
    expect(parseAlertPayload(arr)).toBeNull();
  });

  it('returns null for invalid JSON string', () => {
    expect(parseAlertPayload('not-json')).toBeNull();
  });
});

describe('extractSeverity', () => {
  it('returns explicit severity when present', () => {
    expect(extractSeverity({ severity: 'HIGH' })).toBe('high');
    expect(extractSeverity({ severity: 'Critical' })).toBe('critical');
  });

  it('returns "critical" for confidence >= 0.95', () => {
    expect(extractSeverity({ confidence: 0.95 })).toBe('critical');
    expect(extractSeverity({ confidence: 1.0 })).toBe('critical');
  });

  it('returns "high" for confidence >= 0.8 and < 0.95', () => {
    expect(extractSeverity({ confidence: 0.8 })).toBe('high');
    expect(extractSeverity({ confidence: 0.94 })).toBe('high');
  });

  it('returns "medium" for confidence >= 0.5 and < 0.8', () => {
    expect(extractSeverity({ confidence: 0.5 })).toBe('medium');
    expect(extractSeverity({ confidence: 0.79 })).toBe('medium');
  });

  it('returns "low" for confidence < 0.5', () => {
    expect(extractSeverity({ confidence: 0.49 })).toBe('low');
    expect(extractSeverity({ confidence: 0 })).toBe('low');
  });

  it('uses score as fallback for confidence', () => {
    expect(extractSeverity({ score: 0.99 })).toBe('critical');
  });

  it('returns "low" when no severity or confidence fields exist', () => {
    expect(extractSeverity({})).toBe('low');
  });
});

describe('meetsSeverityThreshold', () => {
  it('returns true when severity equals threshold', () => {
    expect(meetsSeverityThreshold('medium', 'medium')).toBe(true);
  });

  it('returns true when severity exceeds threshold', () => {
    expect(meetsSeverityThreshold('critical', 'low')).toBe(true);
    expect(meetsSeverityThreshold('high', 'medium')).toBe(true);
  });

  it('returns false when severity is below threshold', () => {
    expect(meetsSeverityThreshold('low', 'high')).toBe(false);
    expect(meetsSeverityThreshold('medium', 'critical')).toBe(false);
  });

  it('treats unknown severity as rank 0', () => {
    expect(meetsSeverityThreshold('unknown', 'low')).toBe(true);
    expect(meetsSeverityThreshold('unknown', 'medium')).toBe(false);
  });
});

const sampleAlert = {
  source: 'camera-1',
  label: 'person',
  confidence: 0.92,
  model_name: 'yolov8',
  timestamp: '2025-01-15T10:30:00Z',
};

describe('buildTeamsPayload', () => {
  it('returns an Adaptive Card message', () => {
    const payload = buildTeamsPayload(sampleAlert, 'high');
    expect(payload.type).toBe('message');
    expect(payload.attachments).toHaveLength(1);
    expect(payload.attachments[0].contentType).toBe('application/vnd.microsoft.card.adaptive');
  });

  it('includes severity in the title block', () => {
    const payload = buildTeamsPayload(sampleAlert, 'high');
    const body = payload.attachments[0].content.body;
    const title = body.find((b) => b.type === 'TextBlock' && b.weight === 'bolder');
    expect(title.text).toContain('HIGH');
  });

  it('includes alert facts: source, model, confidence, label', () => {
    const payload = buildTeamsPayload(sampleAlert, 'critical');
    const factSet = payload.attachments[0].content.body.find((b) => b.type === 'FactSet');
    const factTitles = factSet.facts.map((f) => f.title);
    expect(factTitles).toEqual(
      expect.arrayContaining(['Source', 'Model', 'Confidence', 'Label']),
    );
  });
});

describe('buildSlackPayload', () => {
  it('returns a Slack Block Kit message with blocks array', () => {
    const payload = buildSlackPayload(sampleAlert, 'high');
    expect(payload.blocks).toBeDefined();
    expect(payload.blocks.length).toBeGreaterThanOrEqual(2);
  });

  it('includes severity in the header', () => {
    const payload = buildSlackPayload(sampleAlert, 'high');
    const header = payload.blocks.find((b) => b.type === 'header');
    expect(header.text.text).toContain('HIGH');
  });

  it('includes alert fields in a section block', () => {
    const payload = buildSlackPayload(sampleAlert, 'medium');
    const section = payload.blocks.find((b) => b.type === 'section');
    const fieldTexts = section.fields.map((f) => f.text).join(' ');
    expect(fieldTexts).toContain('camera-1');
    expect(fieldTexts).toContain('yolov8');
  });
});

describe('buildGenericPayload', () => {
  it('returns a flat JSON payload with event type', () => {
    const payload = buildGenericPayload(sampleAlert, 'high');
    expect(payload.event).toBe('edge_ai_alert');
    expect(payload.severity).toBe('high');
  });

  it('includes source, model, label, and confidence', () => {
    const payload = buildGenericPayload(sampleAlert, 'critical');
    expect(payload.source).toBe('camera-1');
    expect(payload.model).toBe('yolov8');
    expect(payload.label).toBe('person');
    expect(payload.confidence).toBe(0.92);
  });

  it('embeds the full alert in details', () => {
    const payload = buildGenericPayload(sampleAlert, 'low');
    expect(payload.details).toBe(sampleAlert);
  });
});

describe('buildWebhookPayload', () => {
  it('delegates to Teams builder for webhook.office.com', () => {
    const payload = buildWebhookPayload(
      'https://webhook.office.com/hook/abc',
      sampleAlert,
      'high',
    );
    expect(payload.type).toBe('message');
    expect(payload.attachments[0].contentType).toContain('adaptive');
  });

  it('delegates to Slack builder for hooks.slack.com', () => {
    const payload = buildWebhookPayload(
      'https://hooks.slack.com/services/T00/B00/abc',
      sampleAlert,
      'high',
    );
    expect(payload.blocks).toBeDefined();
  });

  it('delegates to generic builder for unknown URLs', () => {
    const payload = buildWebhookPayload(
      'https://custom.example.com/hook',
      sampleAlert,
      'high',
    );
    expect(payload.event).toBe('edge_ai_alert');
  });
});

describe('buildDigestPayload', () => {
  const bufferedAlerts = [
    { alert: { source: 'cam-1', label: 'person', confidence: 0.6 }, severity: 'medium' },
    { alert: { source: 'cam-2', label: 'vehicle', confidence: 0.55 }, severity: 'medium' },
  ];

  it('builds a Teams digest with alert count in title', () => {
    const payload = buildDigestPayload('https://webhook.office.com/hook', bufferedAlerts);
    expect(payload.type).toBe('message');
    const body = payload.attachments[0].content.body;
    const title = body.find((b) => b.weight === 'bolder');
    expect(title.text).toContain('2');
    expect(title.text).toContain('MEDIUM');
  });

  it('builds a Slack digest with alert count in header', () => {
    const payload = buildDigestPayload('https://hooks.slack.com/services/T00', bufferedAlerts);
    expect(payload.blocks).toBeDefined();
    const header = payload.blocks.find((b) => b.type === 'header');
    expect(header.text.text).toContain('2');
  });

  it('builds a generic digest with count and alerts array', () => {
    const payload = buildDigestPayload('https://custom.example.com/hook', bufferedAlerts);
    expect(payload.event).toBe('edge_ai_digest');
    expect(payload.count).toBe(2);
    expect(payload.alerts).toHaveLength(2);
    expect(payload.alerts[0]).toContain('cam-1');
  });
});
