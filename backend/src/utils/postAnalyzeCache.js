const crypto = require('crypto');

const TTL_MS = 60 * 60 * 1000;
const MAX_ENTRIES = 2000;
/** @type {Map<string, { at: number, payload: object }>} */
const cache = new Map();

function hashKey(userId, parts) {
  const h = crypto.createHash('sha256');
  h.update(String(userId || ''));
  for (const p of parts) {
    h.update('\n');
    h.update(String(p ?? ''));
  }
  return h.digest('hex');
}

/**
 * @param {string} userId
 * @param {string[]} parts stable request facets (not full image base64)
 * @returns {object | null}
 */
function getPostAnalyzeCache(userId, parts) {
  const k = hashKey(userId, parts);
  const row = cache.get(k);
  if (!row) return null;
  if (Date.now() - row.at > TTL_MS) {
    cache.delete(k);
    return null;
  }
  return row.payload;
}

/**
 * @param {string} userId
 * @param {string[]} parts
 * @param {object} payload analysis `data` object (cloned shallow)
 */
function setPostAnalyzeCache(userId, parts, payload) {
  if (cache.size >= MAX_ENTRIES) {
    const first = cache.keys().next().value;
    if (first) cache.delete(first);
  }
  cache.set(hashKey(userId, parts), { at: Date.now(), payload: { ...payload } });
}

module.exports = { getPostAnalyzeCache, setPostAnalyzeCache, TTL_MS, MAX_ENTRIES };
