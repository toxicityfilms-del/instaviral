const User = require('../models/User');
const {
  FREE_POST_ANALYZE_DAILY,
  MAX_AD_REWARD_SLOTS,
  SUSPICIOUS_INVALID_AD_THRESHOLD,
} = require('../config/usageEnv');
const MAX_REWARD_CLAIM_IDS_PER_DAY = 20;
const MAX_REWARD_COMPLETION_AGE_MS = 15 * 60 * 1000;

function utcDayString() {
  return new Date().toISOString().slice(0, 10);
}

/** Clamp stored usage count; free plan max analyses/day = base cap only (no ad bonuses). */
function clampUsedCount(n) {
  const v = Number(n);
  if (Number.isNaN(v) || v < 0) return 0;
  return Math.min(v, FREE_POST_ANALYZE_DAILY);
}

function rewardSlotsForDay(userDoc, today) {
  const d = userDoc.postAnalyzeDaily || {};
  if (d.day !== today) return 0;
  const r = Number(d.rewardSlots);
  if (Number.isNaN(r) || r < 0) return 0;
  return Math.min(r, MAX_AD_REWARD_SLOTS);
}

/** Free tier: fixed daily cap (premium uses assert path without counting). */
function effectiveLimitForDay() {
  return FREE_POST_ANALYZE_DAILY;
}

function trimRewardClaimsArray(claims) {
  if (!Array.isArray(claims)) return [];
  return claims
    .filter((c) => c && c.adCompletionId && String(c.adCompletionId).trim().length > 0)
    .slice(-MAX_REWARD_CLAIM_IDS_PER_DAY);
}

function defaultAdRewardAnalytics() {
  return {
    totalAdsWatched: 0,
    rewardsGranted: 0,
    rewardsRejected: { duplicate: 0, cooldown: 0, limit: 0 },
  };
}

/** Normalize stored analytics for reads and writes (UTC day bucket). */
function normalizeAdRewardAnalytics(d) {
  const a = d && d.adRewardAnalytics && typeof d.adRewardAnalytics === 'object' ? d.adRewardAnalytics : {};
  const rj = a.rewardsRejected && typeof a.rewardsRejected === 'object' ? a.rewardsRejected : {};
  return {
    totalAdsWatched: Math.max(0, Math.floor(Number(a.totalAdsWatched)) || 0),
    rewardsGranted: Math.max(0, Math.floor(Number(a.rewardsGranted)) || 0),
    rewardsRejected: {
      duplicate: Math.max(0, Math.floor(Number(rj.duplicate)) || 0),
      cooldown: Math.max(0, Math.floor(Number(rj.cooldown)) || 0),
      limit: Math.max(0, Math.floor(Number(rj.limit)) || 0),
    },
  };
}

function normalizeSuspiciousDailyFields(d) {
  return {
    invalidAdCompletionCount: Math.max(0, Math.floor(Number(d.invalidAdCompletionCount)) || 0),
    adRewardsBlockedSuspicious: d.adRewardsBlockedSuspicious === true,
  };
}

/** Preserve ad reward claim rows + analytics when staying on the same UTC day; reset when the day rolls. */
function rewardClaimsForCommit(prev, today) {
  if (!prev || prev.day !== today) {
    return {
      adRewardClaims: [],
      adCompletionIds: [],
      rewardClaimIds: [],
      adRewardAnalytics: defaultAdRewardAnalytics(),
      invalidAdCompletionCount: 0,
      adRewardsBlockedSuspicious: false,
    };
  }
  const sus = normalizeSuspiciousDailyFields(prev);
  return {
    adRewardClaims: trimRewardClaimsArray(prev.adRewardClaims),
    adCompletionIds: Array.isArray(prev.adCompletionIds) ? prev.adCompletionIds : [],
    rewardClaimIds: Array.isArray(prev.rewardClaimIds) ? prev.rewardClaimIds : [],
    adRewardAnalytics: normalizeAdRewardAnalytics(prev),
    invalidAdCompletionCount: sus.invalidAdCompletionCount,
    adRewardsBlockedSuspicious: sus.adRewardsBlockedSuspicious,
  };
}

function validateRewardCompletionPayload(completionId, completedAtMs) {
  const id = completionId == null ? '' : String(completionId).trim();
  if (id.length < 8 || id.length > 120) {
    return { ok: false, code: 'INVALID_AD_COMPLETION', message: 'Invalid ad completion id.' };
  }
  if (!/^[A-Za-z0-9._:-]+$/.test(id)) {
    return { ok: false, code: 'INVALID_AD_COMPLETION', message: 'Invalid ad completion id format.' };
  }
  const ts = Number(completedAtMs);
  if (!Number.isFinite(ts) || ts <= 0) {
    return { ok: false, code: 'INVALID_AD_COMPLETION', message: 'Invalid ad completion time.' };
  }
  const delta = Date.now() - ts;
  if (delta < -60 * 1000 || delta > MAX_REWARD_COMPLETION_AGE_MS) {
    return { ok: false, code: 'AD_COMPLETION_EXPIRED', message: 'Ad completion expired. Please watch again.' };
  }
  return { ok: true, completionId: id, completedAtMs: ts };
}

/** Read-only usage for API responses (profile, login, post-analyze meta). */
function buildPostAnalyzeUsageMeta(userDoc) {
  if (!userDoc) {
    return {
      isPremium: false,
      postAnalyzeLimit: FREE_POST_ANALYZE_DAILY,
      postAnalyzeRemaining: FREE_POST_ANALYZE_DAILY,
      postAnalyzeAdRewardsRemaining: 0,
      adRewardAnalytics: defaultAdRewardAnalytics(),
      adRewardSuspiciousFlag: false,
      adRewardsBlockedSuspicious: false,
      invalidAdCompletionCountToday: 0,
    };
  }
  if (userDoc.isPremium === true) {
    return {
      isPremium: true,
      postAnalyzeLimit: null,
      postAnalyzeRemaining: null,
      postAnalyzeAdRewardsRemaining: null,
      adRewardAnalytics: null,
      adRewardSuspiciousFlag: userDoc.adRewardSuspiciousFlag === true,
      adRewardsBlockedSuspicious: null,
      invalidAdCompletionCountToday: null,
    };
  }
  const today = utcDayString();
  const d = userDoc.postAnalyzeDaily || {};
  const freeLimit = FREE_POST_ANALYZE_DAILY;
  const usedToday = d.day === today ? clampUsedCount(d.count) : 0;
  const sus = d.day === today ? normalizeSuspiciousDailyFields(d) : { invalidAdCompletionCount: 0, adRewardsBlockedSuspicious: false };
  return {
    isPremium: false,
    postAnalyzeLimit: freeLimit,
    postAnalyzeRemaining: Math.max(0, freeLimit - usedToday),
    postAnalyzeAdRewardsRemaining: 0,
    adRewardAnalytics:
      d.day === today ? normalizeAdRewardAnalytics(d) : defaultAdRewardAnalytics(),
    adRewardSuspiciousFlag: userDoc.adRewardSuspiciousFlag === true,
    adRewardsBlockedSuspicious: d.day === today ? sus.adRewardsBlockedSuspicious : false,
    invalidAdCompletionCountToday: sus.invalidAdCompletionCount,
  };
}

/**
 * Free: block if today's count already at effective limit (does not increment).
 * Premium: always allowed; no counter.
 */
async function assertPostAnalyzeAllowed(userId) {
  const user = await User.findById(userId);
  if (!user) {
    return {
      ok: false,
      status: 404,
      body: { success: false, message: 'User not found' },
    };
  }
  if (user.isPremium === true) {
    return { ok: true, isPremium: true };
  }
  const today = utcDayString();
  const d = user.postAnalyzeDaily || { day: '', count: 0, rewardSlots: 0 };
  const used = d.day === today ? clampUsedCount(d.count) : 0;
  const eff = effectiveLimitForDay();
  if (used >= eff) {
    return {
      ok: false,
      status: 403,
      body: {
        success: false,
        code: 'POST_ANALYZE_LIMIT',
        message: `Free plan allows ${eff} post analyses per day. Upgrade to Premium for unlimited analyses.`,
        limit: eff,
        used,
      },
    };
  }
  return { ok: true, isPremium: false };
}

/**
 * Call only after OpenAI analysis succeeded. Free users: +1 for today (capped). Premium: no DB change.
 */
async function commitPostAnalyzeUsageAfterSuccess(userId) {
  const user = await User.findById(userId);
  if (!user) {
    return {
      isPremium: false,
      postAnalyzeLimit: FREE_POST_ANALYZE_DAILY,
      postAnalyzeRemaining: 0,
      postAnalyzeAdRewardsRemaining: 0,
      adRewardAnalytics: defaultAdRewardAnalytics(),
      adRewardSuspiciousFlag: false,
      adRewardsBlockedSuspicious: false,
      invalidAdCompletionCountToday: 0,
    };
  }
  if (user.isPremium === true) {
    const meta = buildPostAnalyzeUsageMeta(user);
    return {
      isPremium: true,
      postAnalyzeLimit: null,
      postAnalyzeRemaining: null,
      postAnalyzeAdRewardsRemaining: null,
      adRewardAnalytics: null,
      adRewardSuspiciousFlag: meta.adRewardSuspiciousFlag,
      adRewardsBlockedSuspicious: null,
      invalidAdCompletionCountToday: null,
    };
  }
  const today = utcDayString();
  const prev = user.postAnalyzeDaily || { day: '', count: 0, rewardSlots: 0 };
  const rewardSlots = prev.day === today ? rewardSlotsForDay(user, today) : 0;
  const eff = FREE_POST_ANALYZE_DAILY;
  let used = prev.day === today ? clampUsedCount(prev.count) : 0;
  used = Math.min(used + 1, eff);
  const keptClaims = rewardClaimsForCommit(prev, today);
  user.postAnalyzeDaily = {
    day: today,
    count: used,
    rewardSlots,
    ...keptClaims,
  };
  await user.save();
  const remaining = Math.max(0, eff - used);
  const fresh = await User.findById(userId);
  const meta = buildPostAnalyzeUsageMeta(fresh);
  return {
    isPremium: false,
    postAnalyzeLimit: eff,
    postAnalyzeRemaining: remaining,
    postAnalyzeAdRewardsRemaining: meta.postAnalyzeAdRewardsRemaining,
    adRewardAnalytics: meta.adRewardAnalytics,
    adRewardSuspiciousFlag: meta.adRewardSuspiciousFlag,
    adRewardsBlockedSuspicious: meta.adRewardsBlockedSuspicious,
    invalidAdCompletionCountToday: meta.invalidAdCompletionCountToday,
  };
}

/**
 * Free plan: rewarded ads do not extend the daily cap (returns AD_REWARD_NOT_AVAILABLE after payload validation).
 * Premium: rejected (no ad rewards). Invalid payloads still count toward suspicious-ad thresholds.
 */
async function grantAdRewardSlot(userId, { completionId, completedAtMs } = {}) {
  const user = await User.findById(userId);
  if (!user) {
    return {
      ok: false,
      status: 404,
      body: { success: false, message: 'User not found' },
    };
  }
  if (user.isPremium === true) {
    return {
      ok: false,
      status: 400,
      body: { success: false, message: 'Premium users do not need ad rewards' },
    };
  }
  const today = utcDayString();
  let d = user.postAnalyzeDaily || {
    day: '',
    count: 0,
    rewardSlots: 0,
    adRewardClaims: [],
    adCompletionIds: [],
    rewardClaimIds: [],
    adRewardAnalytics: defaultAdRewardAnalytics(),
    invalidAdCompletionCount: 0,
    adRewardsBlockedSuspicious: false,
  };
  if (d.day !== today) {
    d = {
      day: today,
      count: 0,
      rewardSlots: 0,
      adRewardClaims: [],
      adCompletionIds: [],
      rewardClaimIds: [],
      adRewardAnalytics: defaultAdRewardAnalytics(),
      invalidAdCompletionCount: 0,
      adRewardsBlockedSuspicious: false,
    };
  } else {
    const sus = normalizeSuspiciousDailyFields(d);
    d.invalidAdCompletionCount = sus.invalidAdCompletionCount;
    d.adRewardsBlockedSuspicious = sus.adRewardsBlockedSuspicious;
  }

  if (d.adRewardsBlockedSuspicious === true) {
    return {
      ok: false,
      status: 400,
      body: {
        success: false,
        code: 'AD_REWARD_SUSPENDED',
        message: 'Ad rewards are temporarily unavailable for your account. Try again tomorrow.',
      },
    };
  }

  const payload = validateRewardCompletionPayload(completionId, completedAtMs);
  if (!payload.ok) {
    d.invalidAdCompletionCount = normalizeSuspiciousDailyFields(d).invalidAdCompletionCount + 1;
    if (d.invalidAdCompletionCount > SUSPICIOUS_INVALID_AD_THRESHOLD) {
      d.adRewardsBlockedSuspicious = true;
      user.adRewardSuspiciousFlag = true;
    }
    user.postAnalyzeDaily = d;
    await user.save();
    return {
      ok: false,
      status: 400,
      body: { success: false, code: payload.code, message: payload.message },
    };
  }

  return {
    ok: false,
    status: 400,
    body: {
      success: false,
      code: 'AD_REWARD_NOT_AVAILABLE',
      message:
        'Rewarded ads do not add post analyses on the free plan. Upgrade to Premium for unlimited analyses.',
    },
  };
}

/**
 * Admin: clear suspicious-ad flags and today's invalid/block counters on the user document.
 */
async function resetSuspiciousAdFlags(userId) {
  const user = await User.findById(userId);
  if (!user) {
    return {
      ok: false,
      status: 404,
      body: { success: false, message: 'User not found' },
    };
  }
  user.adRewardSuspiciousFlag = false;
  if (!user.postAnalyzeDaily) {
    user.postAnalyzeDaily = {};
  }
  user.postAnalyzeDaily.invalidAdCompletionCount = 0;
  user.postAnalyzeDaily.adRewardsBlockedSuspicious = false;
  user.markModified('postAnalyzeDaily');
  await user.save();
  const fresh = await User.findById(userId);
  return { ok: true, meta: buildPostAnalyzeUsageMeta(fresh) };
}

module.exports = {
  FREE_POST_ANALYZE_DAILY,
  MAX_AD_REWARD_SLOTS,
  SUSPICIOUS_INVALID_AD_THRESHOLD,
  defaultAdRewardAnalytics,
  normalizeAdRewardAnalytics,
  buildPostAnalyzeUsageMeta,
  assertPostAnalyzeAllowed,
  commitPostAnalyzeUsageAfterSuccess,
  grantAdRewardSlot,
  resetSuspiciousAdFlags,
};
