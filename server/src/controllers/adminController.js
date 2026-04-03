const { sendTrendingDigest } = require('../services/notificationService');

/**
 * Manual trigger for testing trending notifications (premium + FCM).
 * Header: X-Admin-Secret: <ADMIN_SECRET>
 */
async function triggerTrendingDigest(req, res, next) {
  try {
    const secret = process.env.ADMIN_SECRET;
    if (!secret || req.headers['x-admin-secret'] !== secret) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }
    const result = await sendTrendingDigest();
    return res.json({ success: true, data: result });
  } catch (e) {
    return next(e);
  }
}

module.exports = { triggerTrendingDigest };
