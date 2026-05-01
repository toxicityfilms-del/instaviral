/**
 * Analytics-only: one line per AI feature request (caption / hashtag / ideas).
 * Filter logs with prefix `[AI_USAGE]`.
 * `source`: `openai` | `fallback` (premium paths) | `local` (free tier, no `data.source`).
 */
function normalizeAiUsageSource(data) {
  if (data && typeof data === 'object' && (data.source === 'openai' || data.source === 'fallback')) {
    return data.source;
  }
  return 'local';
}

function aiUsageIsoTime() {
  return new Date().toISOString();
}

function logAiFeatureUsage({ userId, feature, data }) {
  const time = aiUsageIsoTime();
  const uid = userId != null && userId !== undefined ? String(userId) : '';
  const feat = String(feature || '');
  const source = normalizeAiUsageSource(data);
  // eslint-disable-next-line no-console
  console.log(`[AI_USAGE] time=${time} userId=${uid} feature=${feat} source=${source}`);
}

module.exports = { logAiFeatureUsage, normalizeAiUsageSource };
