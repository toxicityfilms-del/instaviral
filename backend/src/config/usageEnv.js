/**
 * Usage / ad-reward tuning via environment (loaded when the process starts).
 */

function readIntEnv(name, defaultVal, min, max) {
  const raw = process.env[name];
  if (raw == null || String(raw).trim() === '') return defaultVal;
  const n = parseInt(String(raw), 10);
  if (!Number.isFinite(n)) return defaultVal;
  return Math.min(max, Math.max(min, n));
}

/**
 * Free-tier base post analyses per UTC day (before rewarded-ad bonuses).
 * Env: FREE_POST_ANALYZE_DAILY or FREE_POST_ANALYZE_LIMIT (default 3; was 5 in older deployments).
 */
function readFreePostAnalyzeDaily() {
  const raw =
    process.env.FREE_POST_ANALYZE_DAILY ?? process.env.FREE_POST_ANALYZE_LIMIT ?? '';
  if (raw == null || String(raw).trim() === '') return 3;
  const n = parseInt(String(raw), 10);
  if (!Number.isFinite(n)) return 3;
  return Math.min(50, Math.max(1, n));
}

const FREE_POST_ANALYZE_DAILY = readFreePostAnalyzeDaily();

/** Premium fair use (₹199/mo — not unlimited). Env overrides optional. */
const PREMIUM_ANALYZE_MAX_PER_MINUTE = readIntEnv('PREMIUM_ANALYZE_MAX_PER_MINUTE', 10, 1, 120);
const PREMIUM_ANALYZE_MAX_PER_DAY = readIntEnv('PREMIUM_ANALYZE_MAX_PER_DAY', 150, 1, 10000);
const PREMIUM_ANALYZE_MAX_PER_MONTH = readIntEnv('PREMIUM_ANALYZE_MAX_PER_MONTH', 3000, 1, 100000);

/** Max rewarded-ad bonus slots per UTC day (was 5). */
const MAX_AD_REWARD_SLOTS = readIntEnv('MAX_AD_REWARDS_PER_DAY', 5, 1, 50);

/** Invalid ad-completion attempts before flag + daily block (strictly greater than this count triggers). */
const SUSPICIOUS_INVALID_AD_THRESHOLD = readIntEnv('SUSPICIOUS_INVALID_AD_THRESHOLD', 5, 1, 500);

/** Minimum seconds between distinct rewarded ad grants; 0 disables cooldown. */
const REWARD_COOLDOWN_SECONDS = readIntEnv('REWARD_COOLDOWN_SECONDS', 30, 0, 86400);
const AD_REWARD_COOLDOWN_MS = REWARD_COOLDOWN_SECONDS * 1000;

module.exports = {
  FREE_POST_ANALYZE_DAILY,
  PREMIUM_ANALYZE_MAX_PER_MINUTE,
  PREMIUM_ANALYZE_MAX_PER_DAY,
  PREMIUM_ANALYZE_MAX_PER_MONTH,
  MAX_AD_REWARD_SLOTS,
  AD_REWARD_COOLDOWN_MS,
  REWARD_COOLDOWN_SECONDS,
  SUSPICIOUS_INVALID_AD_THRESHOLD,
};
