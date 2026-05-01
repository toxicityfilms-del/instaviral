const OpenAI = require('openai');
const { dynamicBestTime, dynamicAudio } = require('../utils/contentVariants');

/** Response tag when premium OpenAI path failed or API key is missing — local result, no 503. */
const OPENAI_FALLBACK_SOURCE = 'fallback';
/** Response tag when premium OpenAI completed successfully (Flutter shows “AI powered result”). */
const OPENAI_PRIMARY_SOURCE = 'openai';

/**
 * Premium OpenAI calls use this instead of throwing when the key is missing.
 * free path = never uses this; premium path = null here triggers local fallback + source.
 */
function tryGetClient() {
  const key = (process.env.OPENAI_API_KEY || '').trim();
  if (!key) return null;
  return new OpenAI({ apiKey: key });
}

function isQuotaOrRateLimitError(err) {
  const code =
    err?.code ||
    err?.error?.code ||
    err?.error?.error?.code ||
    err?.response?.data?.error?.code;

  const status =
    err?.status ||
    err?.statusCode ||
    err?.response?.status ||
    err?.error?.status ||
    err?.error?.statusCode;

  const message = String(err?.message || err?.error?.message || '').toLowerCase();
  const quotaText =
    message.includes('you exceeded your current quota') ||
    message.includes('insufficient_quota') ||
    message.includes('rate limit') ||
    message.includes('rate_limit_exceeded');

  return status === 429 || code === 'insufficient_quota' || code === 'rate_limit_exceeded' || quotaText;
}

/** Output cap: caption length (premium + local templates). */
const CAPTION_MAX_WORDS = 120;
/** Output cap: total hashtags across high/medium/low (API shape unchanged). */
const HASHTAG_TOTAL_MAX = 15;
/** Output cap: reel ideas returned (premium + free templates). */
const IDEAS_MAX = 5;

function slugTopic(text) {
  const s = String(text || 'trending')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '')
    .slice(0, 24);
  return s || 'trending';
}

function truncateToMaxWords(text, maxWords) {
  const s = String(text || '').trim();
  if (!s) return '';
  const words = s.split(/\s+/).filter(Boolean);
  if (words.length <= maxWords) return s;
  return words.slice(0, maxWords).join(' ');
}

/** Trim high → medium → low until total ≤ maxTotal (keeps bucket semantics). */
function capHashtagBucketsTotal(buckets, maxTotal = HASHTAG_TOTAL_MAX) {
  const high = [...(buckets.high || [])];
  const medium = [...(buckets.medium || [])];
  const low = [...(buckets.low || [])];
  let total = high.length + medium.length + low.length;
  while (total > maxTotal && low.length > 0) {
    low.pop();
    total -= 1;
  }
  while (total > maxTotal && medium.length > 0) {
    medium.pop();
    total -= 1;
  }
  while (total > maxTotal && high.length > 0) {
    high.pop();
    total -= 1;
  }
  return { high, medium, low };
}

/**
 * free path — no OpenAI cost: keyword slug + curated buckets, 15 tags total (5+5+5).
 * Used for hashtag endpoint when user is not premium, and as OpenAI quota fallback.
 */
function localHashtagsFromKeyword(keyword) {
  const t = slugTopic(keyword);
  const high = [`#${t}`, `#${t}reels`, `#${t}viral`, `#${t}tips`, `#${t}fyp`];
  const medium = [`#${t}content`, `#${t}creator`, `#${t}daily`, `#${t}love`, `#${t}grow`];
  const low = [`#reels`, `#instagram`, `#explorepage`, `#viral`, `#fyp`];
  return { high, medium, low };
}

function fallbackHashtags(keyword) {
  return capHashtagBucketsTotal(localHashtagsFromKeyword(keyword), HASHTAG_TOTAL_MAX);
}

/**
 * free path — no OpenAI cost: lightweight caption template (capped).
 */
function fallbackCaption(idea) {
  const line = String(idea || 'your reel').trim();
  const raw = {
    caption: `POV: ${line} ✨ Drop a 🔥 if you relate!\n\nSave this for later — comment “YES” for part 2. #reels #fyp #viral`,
    hooks: [
      `Wait for it… ${line} hits different 😮‍💨`,
      `Nobody talks about this part of ${line} 👀`,
      `3 seconds that’ll change how you see ${line}`,
    ],
  };
  return {
    caption: truncateToMaxWords(raw.caption, CAPTION_MAX_WORDS),
    hooks: raw.hooks,
  };
}

/**
 * free path — no OpenAI cost: fixed templates (5 items).
 */
function fallbackIdeas(niche) {
  const n = String(niche || 'content').trim();
  const all = [
    `${n}: “before vs after” transformation in 15s`,
    `${n}: myth vs fact — one line each, fast cuts`,
    `${n}: “things I wish I knew sooner” listicle reel`,
    `${n}: day-in-the-life hook in the first 2 seconds`,
    `${n}: common mistake + quick fix (text on screen)`,
    `${n}: “unpopular opinion” + stitch-friendly ending`,
    `${n}: tutorial in 3 steps with countdown timer`,
    `${n}: storytime voiceover + B-roll from camera roll`,
    `${n}: “POV you just discovered…” pattern interrupt`,
    `${n}: trend sound + niche-specific caption twist`,
  ];
  return all.slice(0, IDEAS_MAX);
}

/**
 * @param {string} keyword
 * @param {{ enableOpenAi?: boolean }} [opts] — free path = no OpenAI cost; premium path = OpenAI enabled (gpt-4o-mini).
 */
async function generateHashtags(keyword, { enableOpenAi = false } = {}) {
  if (!enableOpenAi) {
    // free path — no OpenAI cost (keyword-based local buckets)
    return localHashtagsFromKeyword(keyword);
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — OpenAI unavailable (missing key): local fallback, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — hashtag local fallback (source=fallback)');
      return { ...fallbackHashtags(keyword), source: OPENAI_FALLBACK_SOURCE };
    }
    // premium path — OpenAI enabled (gpt-4o-mini), max 15 tags total
    const prompt = `Generate exactly 15 Instagram hashtags for "${keyword}" split by competition: 5 high, 5 medium, 5 low. Return ONLY valid JSON (no markdown):
{"high":["#tag1",...5 items],"medium":[...5],"low":[...5]}
Hashtags must start with #.`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You output only valid JSON for Instagram hashtag lists.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.7,
      max_tokens: 400,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '{}';
    const parsed = safeJsonParse(text);
    const capped = capHashtagBucketsTotal(normalizeHashtagBuckets(parsed), HASHTAG_TOTAL_MAX);
    const total = capped.high.length + capped.medium.length + capped.low.length;
    if (total === 0) {
      return { ...fallbackHashtags(keyword), source: OPENAI_FALLBACK_SOURCE };
    }
    return { ...capped, source: OPENAI_PRIMARY_SOURCE };
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] hashtag failed (${reason}) — local fallback (source=fallback)`);
    return { ...fallbackHashtags(keyword), source: OPENAI_FALLBACK_SOURCE };
  }
}

/**
 * @param {string} idea
 * @param {{ enableOpenAi?: boolean }} [opts] — free path = local templates only; premium path = OpenAI (caption max 120 words).
 */
async function generateCaptionAndHooks(idea, { enableOpenAi = false } = {}) {
  if (!enableOpenAi) {
    // free path — no OpenAI cost
    return fallbackCaption(idea);
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — missing key: local fallback, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — caption local fallback (source=fallback)');
      return { ...fallbackCaption(idea), source: OPENAI_FALLBACK_SOURCE };
    }
    // premium path — OpenAI enabled (gpt-4o-mini)
    const prompt = `Write a viral Instagram caption with emojis for this topic: ${idea}.
Caption must be at most ${CAPTION_MAX_WORDS} words. Also provide 2-3 short alternate opening hooks (one line each).
Return ONLY valid JSON:
{"caption":"...","hooks":["hook1","hook2","hook3"]}`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: `You write viral Instagram captions with emojis. Caption max ${CAPTION_MAX_WORDS} words. Output JSON only.`,
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0.85,
      max_tokens: 500,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '{}';
    const parsed = safeJsonParse(text);
    const hooks = Array.isArray(parsed.hooks) ? parsed.hooks.slice(0, 3) : [];
    const caption = truncateToMaxWords(typeof parsed.caption === 'string' ? parsed.caption : '', CAPTION_MAX_WORDS);
    if (!caption.trim()) {
      return { ...fallbackCaption(idea), source: OPENAI_FALLBACK_SOURCE };
    }
    return { caption, hooks };
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] caption failed (${reason}) — local fallback (source=fallback)`);
    return { ...fallbackCaption(idea), source: OPENAI_FALLBACK_SOURCE };
  }
}

/**
 * @param {string} niche
 * @param {{ enableOpenAi?: boolean }} [opts] — free path = local templates; premium path = OpenAI (max 5 ideas).
 */
async function generateIdeas(niche, { enableOpenAi = false } = {}) {
  if (!enableOpenAi) {
    // free path — no OpenAI cost
    return { ideas: fallbackIdeas(niche) };
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — missing key: local fallback, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — ideas local fallback (source=fallback)');
      return { ideas: fallbackIdeas(niche), source: OPENAI_FALLBACK_SOURCE };
    }
    // premium path — OpenAI enabled (gpt-4o-mini)
    const prompt = `Generate exactly ${IDEAS_MAX} viral Instagram reel content ideas for niche "${niche}".
Return ONLY a JSON array of ${IDEAS_MAX} strings: ["idea1",...]`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You generate viral short-form content ideas. Output JSON array only.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.8,
      max_tokens: 500,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '[]';
    const parsed = safeJsonParse(text);
    const ideas = Array.isArray(parsed) ? parsed.map(String).slice(0, IDEAS_MAX) : [];
    if (ideas.length === 0) {
      return { ideas: fallbackIdeas(niche), source: OPENAI_FALLBACK_SOURCE };
    }
    return { ideas, source: OPENAI_PRIMARY_SOURCE };
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] ideas failed (${reason}) — local fallback (source=fallback)`);
    return { ideas: fallbackIdeas(niche), source: OPENAI_FALLBACK_SOURCE };
  }
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

function normalizePostAnalysis(parsed, nicheForFallback = '') {
  let hashtags = parsed.hashtags;
  if (typeof hashtags === 'string') {
    hashtags = hashtags
      .split(/[\s,]+/)
      .map((s) => s.trim())
      .filter(Boolean);
  }
  if (!Array.isArray(hashtags)) hashtags = [];
  const ensureHash = (s) => {
    const t = String(s).trim();
    if (!t) return '';
    return t.startsWith('#') ? t : `#${t.replace(/^#/, '')}`;
  };
  const audioRaw =
    parsed.audio ??
    parsed.trendingAudio ??
    parsed.trending_audio ??
    parsed.trendingAudioSuggestion ??
    '';
  const hook = String(parsed.hook || '').trim();
  const caption = String(parsed.caption || '').trim();
  const niche = String(nicheForFallback || '').trim();
  let bestTime = String(parsed.bestTime || parsed.best_time || '').trim();
  let audio = String(audioRaw || '').trim();
  const ideaKey = caption || hook || 'post';
  if (!bestTime) bestTime = dynamicBestTime(ideaKey, niche);
  if (!audio) audio = dynamicAudio(ideaKey, niche);
  const cappedTags = hashtags.map(ensureHash).filter(Boolean).slice(0, HASHTAG_TOTAL_MAX);
  return {
    hook,
    caption: truncateToMaxWords(caption, CAPTION_MAX_WORDS),
    hashtags: cappedTags,
    bestTime,
    audio,
  };
}

/**
 * free path — no OpenAI cost (post/analyze-media when not premium).
 */
function fallbackPostAnalysis(idea, hasImage, niche) {
  const hint = String(idea || (hasImage ? 'this visual' : 'your reel')).trim() || 'your reel';
  const nicheHint = String(niche || '').trim();
  const captionRaw = `This is your sign to post ✨\n\n${hint}\n\nComment “FIRE” if you’d watch the full story. #reels #fyp #viral #explorepage`;
  return {
    hook: `POV: you’re about to blow up with ${hint.slice(0, 40)}${hint.length > 40 ? '…' : ''}`,
    caption: truncateToMaxWords(captionRaw, CAPTION_MAX_WORDS),
    hashtags: [
      '#reels',
      '#fyp',
      '#viral',
      '#explorepage',
      '#instagram',
      '#trending',
      '#creator',
      '#content',
      '#growth',
      '#instagood',
      '#reelitfeelit',
      '#explore',
      '#photooftheday',
      '#love',
      '#instadaily',
    ].slice(0, HASHTAG_TOTAL_MAX),
    bestTime: dynamicBestTime(hint, nicheHint),
    audio: dynamicAudio(hint, nicheHint),
  };
}

async function analyzePost({ idea, imageBase64, niche, bio, enableOpenAi = true }) {
  const hasImage = !!(imageBase64 && String(imageBase64).trim());
  const ideaStr = String(idea || '').trim();
  const nicheStr = String(niche || '').trim();
  const bioStr = String(bio || '').trim().slice(0, 400);
  if (!enableOpenAi) {
    // free path — no OpenAI cost
    return fallbackPostAnalysis(ideaStr, hasImage, nicheStr);
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — missing key: local fallback, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — post analyze local fallback (source=fallback)');
      return { ...fallbackPostAnalysis(ideaStr, hasImage, nicheStr), source: OPENAI_FALLBACK_SOURCE };
    }
    // premium path — OpenAI enabled (gpt-4o-mini); caps: caption words + hashtag count
    const sys =
      'You analyze Instagram posts and Reels. Reply with ONLY valid JSON (no markdown, no code fences). Keys: hook (string), caption (string, max 120 words), hashtags (array of exactly 15 strings, each starting with #), bestTime (string), audio (string — trending audio suggestion). bestTime and audio must be tailored to THIS specific idea (vary wording and reasoning; do not reuse the same generic posting window or audio line across different ideas). When the user message includes a concrete creator niche, reflect it consistently in hook tone, caption wording, all hashtags, posting-window reasoning, and audio suggestion.';
    const nicheLine = nicheStr || '(not set — treat as general / broad audience)';
    const ideaLine =
      ideaStr || (hasImage ? '(No text idea — infer from the attached image.)' : '(No idea text provided.)');
    let userText = `Analyze this Instagram post idea and generate:
1. Viral 3-second hook
2. Caption with emojis (max 120 words)
3. Exactly 15 hashtags
4. Best time to post
5. Trending audio suggestion

Niche: ${nicheLine}
Idea: ${ideaLine}`;
    if (bioStr) {
      userText += `\n\nCreator bio (tone/voice hint): ${bioStr}`;
    }
    if (hasImage) {
      userText +=
        '\n\nAn image is attached. Use it for visual context, mood, and niche when writing the hook, caption, and hashtags.';
    }
    if (nicheStr) {
      userText += `\n\nNICHE MODE: The creator profile niche is "${nicheStr}". Align the hook, caption voice, every hashtag, best-time advice, and audio pick with what actually performs in that niche on Instagram Reels. Prefer niche-specific vocabulary, hashtag clusters competitors use, and audio trends common in that vertical.`;
    } else {
      userText +=
        '\n\nNO PROFILE NICHE: The app did not send a creator niche. Still deliver 15 strong hashtags for the idea, but keep hook and caption broadly appealing; for timing and audio, give practical Instagram-wide guidance and note the user can refine by adding a niche in their profile.';
    }

    /** @type {import('openai').OpenAI.Chat.Completions.ChatCompletionMessageParam[]} */
    const userMessage = {
      role: 'user',
      content: [{ type: 'text', text: userText }],
    };
    if (hasImage) {
      let b64 = String(imageBase64).trim();
      const url = b64.startsWith('data:') ? b64 : `data:image/jpeg;base64,${b64}`;
      userMessage.content.push({ type: 'image_url', image_url: { url } });
    }

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'system', content: sys }, userMessage],
      temperature: 0.75,
      max_tokens: 900,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '{}';
    const parsed = safeJsonParse(text);
    return normalizePostAnalysis(parsed, nicheStr);
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] analyzePost failed (${reason}) — local fallback (source=fallback)`);
    return { ...fallbackPostAnalysis(ideaStr, hasImage, nicheStr), source: OPENAI_FALLBACK_SOURCE };
  }
}

function normalizeMediaContext(parsed) {
  const pickArr = (v) => (Array.isArray(v) ? v.map(String).map((s) => s.trim()).filter(Boolean) : []);
  const objects = pickArr(parsed.objects);
  const actions = pickArr(parsed.actions);
  const keywords = pickArr(parsed.keywords);
  return {
    description: String(parsed.description || '').trim(),
    objects: objects.slice(0, 12),
    actions: actions.slice(0, 10),
    mood: String(parsed.mood || '').trim(),
    setting: String(parsed.setting || '').trim(),
    textOnScreen: String(parsed.textOnScreen || parsed.text_on_screen || '').trim(),
    keywords: keywords.slice(0, 18),
  };
}

function safeFileHint(file) {
  if (!file) return '';
  const name = String(file.originalname || '').slice(0, 120);
  const mime = String(file.mimetype || '').slice(0, 80);
  const bytes = Number(file.size || 0);
  return `fileName=${name} mime=${mime} bytes=${bytes}`;
}

async function extractMediaContext({ imageDataUrl, file, niche, userNotes, enableOpenAi = true }) {
  const nicheStr = String(niche || '').trim();
  const notes = String(userNotes || '').trim().slice(0, 600);
  const hasImage = !!(imageDataUrl && String(imageDataUrl).trim());

  if (!hasImage) {
    return normalizeMediaContext({
      description: notes || '',
      keywords: nicheStr ? nicheStr.split(/[\s,]+/).filter(Boolean) : [],
    });
  }

  const hint = safeFileHint(file);
  if (!enableOpenAi) {
    // free path — no OpenAI cost (heuristic context from notes/niche/file hint)
    return normalizeMediaContext({
      description: notes || 'Uploaded media',
      mood: '',
      setting: '',
      textOnScreen: '',
      objects: [],
      actions: [],
      keywords: [
        ...new Set(
          [nicheStr, notes, hint]
            .join(' ')
            .split(/[\s,]+/)
            .map((s) => s.trim())
            .filter(Boolean)
            .slice(0, 18)
        ),
      ],
    });
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — missing key: heuristic context only, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — media context heuristic (source=fallback)');
      return {
        ...normalizeMediaContext({
          description: notes || 'Uploaded media',
          mood: '',
          setting: '',
          textOnScreen: '',
          objects: [],
          actions: [],
          keywords: [
            ...new Set(
              [nicheStr, notes, hint]
                .join(' ')
                .split(/[\s,]+/)
                .map((s) => s.trim())
                .filter(Boolean)
                .slice(0, 18)
            ),
          ],
        }),
        source: OPENAI_FALLBACK_SOURCE,
      };
    }
    // premium path — OpenAI vision (gpt-4o-mini)
    const sys =
      'You are a media content analyst. You must extract concrete visual details (not generic advice). Output ONLY valid JSON with keys: description (string, 1-2 sentences), objects (array of strings), actions (array of strings), mood (string), setting (string), textOnScreen (string), keywords (array of strings).';

    const userText = `Analyze the attached media and extract a concise, concrete description and tags.

Creator niche: ${nicheStr || '(not set)'}
User notes (optional): ${notes || '(none)'}
Upload hint: ${hint || '(none)'}

Rules:
- Use details visible in the media (subjects, setting, colors, vibe, product/category, on-screen text).
- If niche is provided, include niche-specific keywords that match what is actually shown.
- Avoid generic marketing language.`;

    /** @type {import('openai').OpenAI.Chat.Completions.ChatCompletionMessageParam} */
    const userMessage = {
      role: 'user',
      content: [{ type: 'text', text: userText }],
    };
    const url = String(imageDataUrl).trim();
    userMessage.content.push({ type: 'image_url', image_url: { url } });

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'system', content: sys }, userMessage],
      temperature: 0.2,
      max_tokens: 700,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '{}';
    const parsed = safeJsonParse(text);
    return normalizeMediaContext(parsed);
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] extractMediaContext failed (${reason}) — heuristic fallback (source=fallback)`);
    return {
      ...normalizeMediaContext({
        description: notes || 'Uploaded media',
        mood: '',
        setting: '',
        textOnScreen: '',
        objects: [],
        actions: [],
        keywords: [
          ...new Set(
            [nicheStr, notes, hint]
              .join(' ')
              .split(/[\s,]+/)
              .map((s) => s.trim())
              .filter(Boolean)
              .slice(0, 18)
          ),
        ],
      }),
      source: OPENAI_FALLBACK_SOURCE,
    };
  }
}

async function analyzeMediaPost({ niche, bio, userNotes, mediaContext, enableOpenAi = true }) {
  const nicheStr = String(niche || '').trim();
  const bioStr = String(bio || '').trim().slice(0, 400);
  const notes = String(userNotes || '').trim().slice(0, 600);

  if (!enableOpenAi) {
    // free path — no OpenAI cost
    const hint = mediaContext?.description || notes || 'this post';
    return fallbackPostAnalysis(hint, false, nicheStr);
  }
  try {
    const client = tryGetClient();
    if (!client) {
      // premium path — missing key: local pack, not 503
      // eslint-disable-next-line no-console
      console.warn('[OpenAI] OPENAI_API_KEY missing — analyzeMediaPost local fallback (source=fallback)');
      const hint = mediaContext?.description || notes || 'this post';
      return { ...fallbackPostAnalysis(hint, false, nicheStr), source: OPENAI_FALLBACK_SOURCE };
    }
    // premium path — OpenAI enabled (gpt-4o-mini); caps: caption ≤120 words, 15 hashtags
    const sys =
      'You analyze Instagram Reels/posts. Reply with ONLY valid JSON (no markdown, no code fences). Keys: hook (string, a 3-second hook), caption (string, max 120 words), hashtags (array of exactly 15 strings, each starting with #), bestTime (string), audio (string — trending audio suggestion). The output MUST be specific to the described media (not generic). bestTime and audio must change when the media context or niche changes (no copy-paste generic lines). If niche is provided, align hook tone, caption voice, EVERY hashtag, bestTime advice, and audio pick to that niche.';

    const ctx = mediaContext || {};
    const ctxJson = JSON.stringify(
      {
        description: ctx.description || '',
        objects: ctx.objects || [],
        actions: ctx.actions || [],
        mood: ctx.mood || '',
        setting: ctx.setting || '',
        textOnScreen: ctx.textOnScreen || '',
        keywords: ctx.keywords || [],
      },
      null,
      0
    );

    let userText = `You are given extracted media context (from an uploaded image/video thumbnail). Use it as the primary source of truth.

Media context JSON: ${ctxJson}

Creator niche: ${nicheStr || '(not set)'}
Creator bio (tone hint): ${bioStr || '(not provided)'}
User notes: ${notes || '(none)'}

Generate:
1) Best posting time (be concrete + short reasoning)
2) Caption tailored to the media and niche (use emojis naturally, max 120 words)
3) Exactly 15 hashtags tightly matching the visible content + niche (no repeats)
4) Trending audio suggestion relevant to the media/niche (describe the kind of sound and why)
5) 3-second hook that matches the opening frame / pattern interrupt

Hard rules:
- Do NOT be generic. Mention specific objects/actions/settings from the media context.
- Hashtags must be specific to the media context; include a mix of broad + niche + contextual tags.
- Hook must be 3–8 words and punchy.`;

    if (!nicheStr) {
      userText +=
        '\n\nNo niche provided: still be specific to the media; keep the hashtags balanced and broadly discoverable.';
    }

    const completion = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'system', content: sys }, { role: 'user', content: userText }],
      temperature: 0.75,
      max_tokens: 1000,
    });

    const text = completion.choices[0]?.message?.content?.trim() || '{}';
    const parsed = safeJsonParse(text);
    return normalizePostAnalysis(parsed, nicheStr);
  } catch (e) {
    const reason = isQuotaOrRateLimitError(e) ? 'quota/rate limit' : (e?.message || 'error');
    // eslint-disable-next-line no-console
    console.warn(`[OpenAI] analyzeMediaPost failed (${reason}) — local fallback (source=fallback)`);
    const hint = mediaContext?.description || notes || 'this post';
    return { ...fallbackPostAnalysis(hint, false, nicheStr), source: OPENAI_FALLBACK_SOURCE };
  }
}

module.exports = {
  generateHashtags,
  generateCaptionAndHooks,
  generateIdeas,
  analyzePost,
  extractMediaContext,
  analyzeMediaPost,
};
