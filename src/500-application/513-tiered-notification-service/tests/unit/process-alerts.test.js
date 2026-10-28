import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { eventHub } = vi.hoisted(() => ({ eventHub: vi.fn() }));

vi.mock("@azure/functions", () => ({ app: { eventHub } }));

const WEBHOOK_URL = "https://notifications.example.com/alerts";
const NOW = "2026-10-28T12:00:00.000Z";
const ALERT = {
  severity: "high",
  source: "sensor-01",
  label: "temperature",
  model_name: "synthetic-model",
  confidence: 0.9,
};

describe("processAlerts", () => {
  let handler;
  let parseAlertPayload;
  let context;
  let fetchMock;

  beforeEach(async () => {
    vi.resetModules();
    eventHub.mockReset();
    vi.stubEnv("NOTIFICATION_WEBHOOK_URL", WEBHOOK_URL);
    vi.stubEnv("ALERT_SEVERITY_THRESHOLD", "high");
    vi.stubEnv("DEDUP_WINDOW_MS", "30000");
    vi.stubEnv("DIGEST_INTERVAL_MS", "300000");
    vi.useFakeTimers();
    vi.setSystemTime(new Date(NOW));
    fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200 });
    vi.stubGlobal("fetch", fetchMock);
    context = { log: vi.fn(), warn: vi.fn(), error: vi.fn() };

    ({ parseAlertPayload } = await import("../../src/functions/processAlerts.js"));
    expect(eventHub).toHaveBeenCalledExactlyOnceWith(
      "processAlerts",
      expect.objectContaining({ cardinality: "many", handler: expect.any(Function) }),
    );
    handler = eventHub.mock.calls[0][1].handler;
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
    vi.unstubAllGlobals();
    vi.useRealTimers();
    vi.resetModules();
    eventHub.mockReset();
  });

  it("preserves JSON and Buffer alerts and rejects malformed JSON", () => {
    const json = JSON.stringify(ALERT);

    expect(parseAlertPayload(json)).toEqual(ALERT);
    expect(parseAlertPayload(Buffer.from(json))).toEqual(ALERT);
    expect(parseAlertPayload("{invalid-json")).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects a private non-HTTPS webhook before dispatch", async () => {
    vi.stubEnv("NOTIFICATION_WEBHOOK_URL", "http://127.0.0.1/alerts");

    await handler([ALERT], context);

    expect(fetchMock).not.toHaveBeenCalled();
    expect(context.error).toHaveBeenCalledExactlyOnceWith(
      "Invalid NOTIFICATION_WEBHOOK_URL: Webhook URL must use HTTPS, got: http:",
    );
    expect(context.log).not.toHaveBeenCalled();
  });

  it("dispatches one generic webhook for duplicate high-severity alerts", async () => {
    await handler([JSON.stringify(ALERT), { ...ALERT }], context);

    expect(fetchMock).toHaveBeenCalledExactlyOnceWith(
      WEBHOOK_URL,
      expect.objectContaining({
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: expect.any(AbortSignal),
      }),
    );
    expect(JSON.parse(fetchMock.mock.calls[0][1].body)).toEqual({
      event: "edge_ai_alert",
      severity: "high",
      timestamp: NOW,
      source: ALERT.source,
      model: ALERT.model_name,
      label: ALERT.label,
      confidence: ALERT.confidence,
      details: ALERT,
    });
    expect(context.log).toHaveBeenCalledWith(
      "Batch complete: 1 dispatched, 0 skipped, 1 deduplicated, 0 buffered, 0 errors",
    );
    expect(context.error).not.toHaveBeenCalled();
  });

  it("flushes medium alerts at batch end before the digest interval elapses", async () => {
    vi.stubEnv("ALERT_SEVERITY_THRESHOLD", "medium");
    const alert = { ...ALERT, severity: "medium", confidence: 0.6 };

    await handler([alert], context);

    expect(Date.now()).toBe(new Date(NOW).getTime());
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe(WEBHOOK_URL);
    expect(JSON.parse(fetchMock.mock.calls[0][1].body)).toEqual({
      event: "edge_ai_digest",
      severity: "medium",
      count: 1,
      timestamp: NOW,
      alerts: ["sensor-01: temperature (0.6)"],
    });
    expect(context.log).toHaveBeenCalledWith(
      "Batch complete: 1 dispatched, 0 skipped, 0 deduplicated, 1 buffered, 0 errors",
    );
    expect(context.error).not.toHaveBeenCalled();
  });

  it("skips a lower-severity alert when the threshold is high", async () => {
    await handler([{ ...ALERT, severity: "medium" }], context);

    expect(fetchMock).not.toHaveBeenCalled();
    expect(context.log).toHaveBeenCalledWith(
      "Alert severity 'medium' below threshold 'high', skipping",
    );
    expect(context.log).toHaveBeenCalledWith(
      "Batch complete: 0 dispatched, 1 skipped, 0 deduplicated, 0 buffered, 0 errors",
    );
    expect(context.error).not.toHaveBeenCalled();
  });

  it("retries a transient server error once and records successful dispatch", async () => {
    fetchMock.mockResolvedValueOnce({ ok: false, status: 503 });

    await handler([ALERT], context);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[0][0]).toBe(WEBHOOK_URL);
    expect(fetchMock.mock.calls[1][0]).toBe(WEBHOOK_URL);
    expect(fetchMock.mock.calls[1][1].body).toBe(fetchMock.mock.calls[0][1].body);
    expect(JSON.parse(fetchMock.mock.calls[1][1].body)).toMatchObject({
      event: "edge_ai_alert",
      severity: "high",
      source: ALERT.source,
      label: ALERT.label,
    });
    expect(context.warn).toHaveBeenCalledExactlyOnceWith(
      "Webhook returned 503, retrying (attempt 1/2)",
    );
    expect(context.log).toHaveBeenCalledWith(
      "Batch complete: 1 dispatched, 0 skipped, 0 deduplicated, 0 buffered, 0 errors",
    );
    expect(context.error).not.toHaveBeenCalled();
  });
});
