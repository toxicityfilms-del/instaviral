/**
 * API tests for POST /api/usage/ad-reward (free plan: no slot grants; premium rejected).
 *
 * Usage: npm run test:api:ad-reward
 * Requires: backend running, MongoDB (MONGO_URI for premium user flag).
 *
 * Env: TEST_API_BASE (default http://localhost:3000/api)
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const dns = require('dns');
if (process.env.MONGO_DNS_SERVERS) {
  const servers = process.env.MONGO_DNS_SERVERS.split(',').map((s) => s.trim()).filter(Boolean);
  if (servers.length) dns.setServers(servers);
}

const mongoose = require('mongoose');
const User = require('../src/models/User');

const BASE = process.env.TEST_API_BASE || 'http://localhost:3000/api';

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

async function json(res) {
  const t = await res.text();
  try {
    return JSON.parse(t);
  } catch {
    return { _raw: t };
  }
}

function authHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

function freshCompletionPayload(suffix) {
  const ts = Date.now();
  return {
    completionId: `testad_${ts}_${suffix}_claim`,
    completedAtMs: ts,
  };
}

async function signupUser(email, password) {
  const res = await fetch(`${BASE}/auth/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, name: 'Ad Reward Test' }),
  });
  const body = await json(res);
  assert(res.ok && body.success === true, `signup failed: ${res.status} ${JSON.stringify(body)}`);
  return { token: body.token, user: body.user };
}

async function getProfile(token) {
  const res = await fetch(`${BASE}/profile/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const body = await json(res);
  assert(res.ok && body.success === true, `profile/me failed: ${res.status}`);
  return body.data;
}

async function postAdReward(token, { completionId, completedAtMs }) {
  const res = await fetch(`${BASE}/usage/ad-reward`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify({ completionId, completedAtMs }),
  });
  const body = await json(res);
  return { res, body };
}

async function main() {
  console.log('Base URL:', BASE);

  const freeEmail = `adreward_free_${Date.now()}@example.com`;
  const premEmail = `adreward_prem_${Date.now()}@example.com`;
  const password = 'testpass12';

  const { token: freeToken, user: signupFree } = await signupUser(freeEmail, password);
  assert(signupFree.postAnalyzeLimit === 3, 'signup free limit should be 3');
  assert(signupFree.postAnalyzeRemaining === 3, 'signup free remaining should be 3');
  assert(signupFree.postAnalyzeAdRewardsRemaining === 0, 'free plan should not offer ad reward slots');

  const before = await getProfile(freeToken);
  const remBefore = before.postAnalyzeRemaining;
  const limBefore = before.postAnalyzeLimit;
  assert(limBefore === 3 && remBefore === 3, 'profile should show 3/3 before ad-reward');

  const payload1 = freshCompletionPayload('a');
  let { res, body } = await postAdReward(freeToken, payload1);
  assert(res.status === 400, `free valid ad-reward expected 400, got ${res.status}`);
  assert(body.success === false, 'free claim should not succeed');
  assert(body.code === 'AD_REWARD_NOT_AVAILABLE', `expected AD_REWARD_NOT_AVAILABLE, got ${body.code}`);

  const after = await getProfile(freeToken);
  assert(after.postAnalyzeLimit === 3 && after.postAnalyzeRemaining === 3, 'usage must not change after rejected ad-reward');

  // --- Premium user: not affected (reject claim; usage stays premium-shaped) ---
  const { token: premToken } = await signupUser(premEmail, password);
  const mongoUri = process.env.MONGO_URI;
  assert(mongoUri, 'MONGO_URI is required to mark a user premium for this test');
  await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 15_000 });
  try {
    const u = await User.findOneAndUpdate(
      { email: premEmail },
      { $set: { isPremium: true } },
      { new: true }
    );
    assert(u && u.isPremium === true, 'failed to set premium flag in DB');
  } finally {
    await mongoose.disconnect();
  }

  const premProfileBefore = await getProfile(premToken);
  assert(premProfileBefore.isPremium === true, 'premium user should show isPremium');

  const premPayload = freshCompletionPayload('p');
  ({ res, body } = await postAdReward(premToken, premPayload));
  assert(res.status === 400, `premium ad-reward should be 400, got ${res.status}`);
  assert(body.success === false, 'premium should not succeed');

  const premProfileAfter = await getProfile(premToken);
  assert(premProfileAfter.isPremium === true, 'premium flag unchanged');
  assert(
    premProfileAfter.postAnalyzeRemaining == null && premProfileAfter.postAnalyzeLimit == null,
    'premium user usage fields should stay null (unaffected by failed claim)'
  );
  assert(premProfileAfter.adRewardAnalytics == null, 'premium user adRewardAnalytics should be null');
  assert(premProfileAfter.invalidAdCompletionCountToday == null, 'premium invalid count should be null');

  console.log('OK  ad-reward: free users get AD_REWARD_NOT_AVAILABLE (limit stays 3)');
  console.log('OK  ad-reward: premium users rejected and usage unchanged');
}

main().catch((e) => {
  console.error('FAIL', e.message || e);
  process.exit(1);
});
