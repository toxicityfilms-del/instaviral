/**
 * Analytics-only: one JSON line per AI feature request (caption / hashtag / ideas).
 * `source`: `openai` | `fallback` (premium paths) | `local` (free tier, no `data.source`).
 */
function normalizeAiUsageSource(data) {
  if (data && typeof data === 'object' && (data.source === 'openai' || data.source === 'fallback')) {
    return data.source;
  }
  return 'local';
}

function logAiFeatureUsage({ userId, feature, data }) {
  const uid = userId != null && userId !== undefined ? String(userId) : '';
  const source = normalizeAiUsageSource(data);
  // eslint-disable-next-line no-console
  console.log(
    JSON.stringify({
      type: 'ai_feature_usage',
      userId: uid,
      feature: String(feature || ''),
      source,
    })
  );
}

module.exports = { logAiFeatureUsage, normalizeAiUsageSource };
