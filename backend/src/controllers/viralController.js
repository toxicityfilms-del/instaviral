const { validationResult } = require('express-validator');
const { analyzeViralScore } = require('../services/viralScoreService');
const { dynamicBestTime, dynamicAudio } = require('../utils/contentVariants');

async function analyze(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const { caption, hashtags, niche } = req.body;
    const data = analyzeViralScore(caption, hashtags || '');
    const nicheStr = String(niche || '').trim();
    const contextKey = `${String(caption || '').trim()}\n${String(hashtags || '').trim()}`;
    return res.json({
      success: true,
      data: {
        ...data,
        niche: nicheStr || null,
        bestTime: dynamicBestTime(contextKey, nicheStr),
        audioSuggestion: dynamicAudio(contextKey, nicheStr),
      },
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { analyze };
