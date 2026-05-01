// Smoke fuzz harness — minimal Jazzer.js stub to exercise CI plumbing.
export function fuzz(data) {
  try {
    Buffer.from(data).toString('utf8');
  } catch (_) {
    /* swallow */
  }
}
