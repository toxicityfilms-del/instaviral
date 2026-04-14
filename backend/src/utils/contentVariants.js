'use strict';

/**
 * Deterministic pick from caption/idea + niche so timing/audio vary per request without OpenAI.
 */
function simpleHash(str) {
  const s = String(str || '');
  let h = 2166136261;
  for (let i = 0; i < s.length; i += 1) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function pick(seed, list) {
  if (!list.length) return '';
  return list[seed % list.length];
}

function dynamicBestTime(ideaOrCaption, niche) {
  const idea = String(ideaOrCaption || '').slice(0, 500);
  const n = String(niche || '').trim();
  const nicheTail = n
    ? ` For “${n.slice(0, 48)}${n.length > 48 ? '…' : ''}”, compare weekday vs weekend in Insights after3 posts.`
    : ' Refine using Instagram Insights once you have a few posts.';
  const seed = simpleHash(`${idea}|${n}|bestTime`);
  const variants = [
    `Tue–Thu 6:30–9:00 PM (local) — strong evening discovery window.${nicheTail}`,
    `Wed/Fri 12:00–2:00 PM — lunch scroll; keep the hook visible in frame 1.${nicheTail}`,
    `Sat/Sun 10:00 AM–1:00 PM — weekend “coffee scroll”; works well for story-led hooks.${nicheTail}`,
    `Weekday 7:30–9:30 AM — short commute-friendly cuts; first line must punch.${nicheTail}`,
    `Sun 4:00–7:00 PM — reflective / tutorial angles; use on-screen text early.${nicheTail}`,
  ];
  return pick(seed, variants);
}

function dynamicAudio(ideaOrCaption, niche) {
  const idea = String(ideaOrCaption || '').slice(0, 500);
  const n = String(niche || '').trim();
  const nicheHint = n
    ? ` Sort Reels audio by what’s rising in the “${n.slice(0, 40)}” cluster this week.`
    : ' Reels audio → trending; match energy to your first 2 seconds of video.';
  const seed = simpleHash(`${idea}|${n}|audio`);
  const variants = [
    `Pick a 12–18s clip with a beat drop on your main reveal.${nicheHint}`,
    `Try a soft “day in my life” bed if pacing is calm; swap to faster drums for quick cuts.${nicheHint}`,
    `Use a comedic sound only if the visual beat lands on the punchline.${nicheHint}`,
    `Try emotional piano/strings if the caption is story-first; avoid competing with voiceover.${nicheHint}`,
    `Use a sped-up instrumental loop if you’re doing listicles or rapid tips.${nicheHint}`,
  ];
  return pick(seed * 13 + 7, variants);
}

module.exports = { simpleHash, dynamicBestTime, dynamicAudio };
