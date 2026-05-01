const { validationResult } = require('express-validator');
const { generateIdeas } = require('../services/openaiService');
const {
  assertPostAnalyzeAllowed,
  buildSharedAiLimitReachedBody,
  commitPostAnalyzeUsageAfterSuccess,
} = require('../services/usageService');
const { logAiFeatureUsage } = require('../utils/aiUsageLog');

function userId(req) {
  return req.user?.sub;
}

async function generate(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const id = userId(req);
    const gate = await assertPostAnalyzeAllowed(id);
    if (!gate.ok) {
      if (gate.status === 403 && gate.body?.code === 'POST_ANALYZE_LIMIT') {
        return res.status(403).json(buildSharedAiLimitReachedBody(gate.body));
      }
      return res.status(gate.status).json(gate.body);
    }
    const { niche } = req.body;
    // free path: local templates only; premium path: OpenAI (gpt-4o-mini); missing key → data.source === "fallback"
    const data = await generateIdeas(niche, { enableOpenAi: gate.isPremium === true });
    logAiFeatureUsage({ userId: id, feature: 'ideas', data });
    const meta = await commitPostAnalyzeUsageAfterSuccess(id);
    if (!meta.isPremium) {
      if (meta.postAnalyzeRemaining != null) {
        res.set('X-RateLimit-Remaining', String(meta.postAnalyzeRemaining));
      }
      if (meta.postAnalyzeLimit != null) {
        res.set('X-RateLimit-Limit', String(meta.postAnalyzeLimit));
      }
    }
    return res.json({
      success: true,
      data,
      limit: meta.postAnalyzeLimit,
      remaining: meta.postAnalyzeRemaining,
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { generate };
