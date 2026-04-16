const { validationResult } = require('express-validator');
const { analyzeViralScore } = require('../services/viralScoreService');

const NICHE_RULES = [
  { niche: 'fitness', re: /\b(fitness|gym|workout|muscle|fat ?loss|cardio|protein|bodybuilding|exercise)\b/i },
  { niche: 'business', re: /\b(business|startup|entrepreneur|sales|marketing|brand|revenue|client|lead)\b/i },
  { niche: 'motivation', re: /\b(motivation|mindset|discipline|grind|success|focus|inspiration|self ?growth)\b/i },
  { niche: 'comedy', re: /\b(comedy|funny|meme|joke|lol|roast|satire|skit)\b/i },
  { niche: 'education', re: /\b(learn|education|tutorial|how to|tips|guide|explainer|lesson|study)\b/i },
  { niche: 'fashion', re: /\b(fashion|style|outfit|ootd|makeup|beauty|streetwear|lookbook)\b/i },
  { niche: 'lifestyle', re: /\b(lifestyle|vlog|routine|daily|wellness|travel|home|selfcare)\b/i },
];

function detectNiche(caption, hashtags) {
  const src = `${String(caption || '')} ${String(hashtags || '')}`;
  let best = 'lifestyle';
  let bestScore = 0;
  for (const rule of NICHE_RULES) {
    const matches = src.match(new RegExp(rule.re.source, 'gi'));
    const score = matches ? matches.length : 0;
    if (score > bestScore) {
      bestScore = score;
      best = rule.niche;
    }
  }
  return best;
}

function dynamicBestTimeByNiche(niche) {
  const byNiche = {
    fitness: ['6:00–8:30 AM', '6:30–9:00 PM'],
    business: ['8:00–10:00 AM', '12:00–2:00 PM'],
    motivation: ['7:00–9:00 AM', '8:00–10:00 PM'],
    comedy: ['8:00–11:00 PM', '12:00–2:00 PM'],
    education: ['7:00–9:00 PM', '12:00–1:30 PM'],
    fashion: ['5:00–7:30 PM', '11:00 AM–1:00 PM'],
    lifestyle: ['9:00–11:00 AM', '6:00–8:00 PM'],
  };
  const slots = byNiche[niche] || byNiche.lifestyle;
  return slots[1] || slots[0];
}

function dynamicAudioSuggestion(niche) {
  const byNiche = {
    fitness: 'Power workout trap / gym phonk',
    business: 'Confident corporate trap beat',
    motivation: 'Epic rise cinematic beat',
    comedy: 'Fast meme remix with punch hits',
    education: 'Clean no-vocal instructional bed',
    fashion: 'Runway house bass drop',
    lifestyle: 'Warm feel-good indie pop loop',
  };
  return byNiche[niche] || byNiche.lifestyle;
}

async function analyze(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const { caption, hashtags } = req.body;
    const cap = String(caption || '');
    const tags = String(hashtags || '');
    const data = analyzeViralScore(cap, tags);
    const niche = detectNiche(cap, tags);
    return res.json({
      success: true,
      data: {
        ...data,
        niche,
        bestTime: dynamicBestTimeByNiche(niche),
        audioSuggestion: dynamicAudioSuggestion(niche),
      },
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { analyze };
