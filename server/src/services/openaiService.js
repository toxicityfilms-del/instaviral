const OpenAI = require('openai');

function getClient() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) {
    const err = new Error('OPENAI_API_KEY is not configured');
    err.status = 503;
    throw err;
  }
  return new OpenAI({ apiKey: key });
}

/**
 * @param {string} keyword
 * @returns {Promise<{ high: string[], medium: string[], low: string[] }>}
 */
async function generateHashtags(keyword) {
  const client = getClient();
  const prompt = `Generate 30 Instagram hashtags for "${keyword}", include high, medium and low competition. Return ONLY valid JSON with this exact shape (no markdown):
{"high":["#tag1",...],"medium":["#tag1",...],"low":["#tag1",...]}
Each array should have roughly 10 hashtags. Hashtags must start with #.`;

  const completion = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'You output only valid JSON for Instagram hashtag lists.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.7,
  });

  const text = completion.choices[0]?.message?.content?.trim() || '{}';
  const parsed = safeJsonParse(text);
  return normalizeHashtagBuckets(parsed);
}

/**
 * @param {string} idea
 * @returns {Promise<{ caption: string, hooks: string[] }>}
 */
async function generateCaptionAndHooks(idea) {
  const client = getClient();
  const prompt = `Write a viral Instagram caption with a strong hook for: "${idea}".
Also provide 2-3 short alternate opening hooks (one line each) that could replace the first line.
Return ONLY valid JSON:
{"caption":"...","hooks":["hook1","hook2","hook3"]}`;

  const completion = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'You write viral Instagram captions. Output JSON only.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.85,
  });

  const text = completion.choices[0]?.message?.content?.trim() || '{}';
  const parsed = safeJsonParse(text);
  const hooks = Array.isArray(parsed.hooks) ? parsed.hooks.slice(0, 3) : [];
  return {
    caption: typeof parsed.caption === 'string' ? parsed.caption : '',
    hooks,
  };
}

/**
 * @param {string} niche
 * @returns {Promise<string[]>}
 */
async function generateIdeas(niche) {
  const client = getClient();
  const prompt = `Generate 10 viral Instagram reel ideas for niche: "${niche}".
Return ONLY a JSON array of 10 strings: ["idea1",...]`;

  const completion = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'You generate viral short-form content ideas. Output JSON array only.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.8,
  });

  const text = completion.choices[0]?.message?.content?.trim() || '[]';
  const parsed = safeJsonParse(text);
  return Array.isArray(parsed) ? parsed.map(String).slice(0, 10) : [];
}

function safeJsonParse(text) {
  let t = text.trim();
  if (t.startsWith('```')) {
    t = t.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  }
  try {
    return JSON.parse(t);
  } catch {
    return {};
  }
}

function normalizeHashtagBuckets(parsed) {
  const high = Array.isArray(parsed.high) ? parsed.high.map(String) : [];
  const medium = Array.isArray(parsed.medium) ? parsed.medium.map(String) : [];
  const low = Array.isArray(parsed.low) ? parsed.low.map(String) : [];
  const ensureHash = (s) => (s.startsWith('#') ? s : `#${s.replace(/^#/, '')}`);
  return {
    high: high.map(ensureHash).filter(Boolean),
    medium: medium.map(ensureHash).filter(Boolean),
    low: low.map(ensureHash).filter(Boolean),
  };
}

module.exports = {
  generateHashtags,
  generateCaptionAndHooks,
  generateIdeas,
};
