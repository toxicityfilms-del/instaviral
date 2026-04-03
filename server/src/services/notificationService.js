const path = require('path');
const User = require('../models/User');
const { isPremiumActive } = require('../utils/userHelpers');
const { getMockTrends } = require('./trendsMockService');

let adminApp;

function initFirebaseAdmin() {
  if (adminApp) return adminApp;
  const p = process.env.FIREBASE_SERVICE_ACCOUNT_JSON_PATH;
  if (!p) {
    return null;
  }
  try {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const admin = require('firebase-admin');
    const serviceAccount = require(path.resolve(p));
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    adminApp = admin;
    return adminApp;
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('Firebase Admin init failed:', e.message);
    return null;
  }
}

/**
 * Sends a trending digest notification to premium users with FCM tokens.
 */
async function sendTrendingDigest() {
  const admin = initFirebaseAdmin();
  if (!admin) {
    // eslint-disable-next-line no-console
    console.warn('Trend alerts skipped: FIREBASE_SERVICE_ACCOUNT_JSON_PATH not set or invalid.');
    return { sent: 0, skipped: true };
  }

  const trends = getMockTrends();
  const idea = trends.ideas[0];
  const title = 'Trending on ReelBoost';
  const body = idea ? `${idea.title} (${idea.niche})` : 'Fresh reel ideas are live — open the app.';

  const users = await User.find({
    subscriptionTier: 'premium',
    trendAlertsEnabled: true,
    fcmToken: { $ne: null, $exists: true },
  }).lean();

  const messaging = admin.messaging();
  let sent = 0;
  for (const u of users) {
    if (!isPremiumActive(u)) continue;
    if (!u.fcmToken) continue;
    try {
      await messaging.send({
        token: u.fcmToken,
        notification: { title, body },
        data: {
          type: 'trending_alert',
          source: String(trends.source || 'mock'),
        },
        android: { priority: 'high' },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
      });
      sent += 1;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.warn('FCM send failed for user', u._id, err.message);
    }
  }

  // eslint-disable-next-line no-console
  console.log(`Trending digest sent to ${sent} device(s).`);
  return { sent, skipped: false };
}

module.exports = { initFirebaseAdmin, sendTrendingDigest };
