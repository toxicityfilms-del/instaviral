const crypto = require('crypto');
const User = require('../models/User');
const { buildPostAnalyzeUsageMeta } = require('../services/usageService');

function verifyRazorpaySignature(orderId, paymentId, signature) {
  const secret = String(process.env.RAZORPAY_KEY_SECRET || '').trim();
  if (!secret) return false;
  const oid = String(orderId || '').trim();
  const pid = String(paymentId || '').trim();
  const sig = String(signature || '').trim();
  if (!oid || !pid || !sig) return false;
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(`${oid}|${pid}`);
  const expected = hmac.digest('hex');
  if (expected.length !== sig.length) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(expected, 'utf8'), Buffer.from(sig, 'utf8'));
  } catch {
    return false;
  }
}

function userUpgradeData(userDoc) {
  const usage = buildPostAnalyzeUsageMeta(userDoc);
  return {
    id: userDoc._id != null ? String(userDoc._id) : '',
    email: userDoc.email,
    name: userDoc.name || '',
    bio: userDoc.bio || '',
    instagramLink: userDoc.instagramLink || '',
    facebookLink: userDoc.facebookLink || '',
    tiktokLink: userDoc.tiktokLink || '',
    niche: userDoc.niche || '',
    isPremium: usage.isPremium,
    postAnalyzeLimit: usage.postAnalyzeLimit,
    postAnalyzeRemaining: usage.postAnalyzeRemaining,
    postAnalyzeAdRewardsRemaining: usage.postAnalyzeAdRewardsRemaining,
  };
}

/**
 * POST /api/user/upgrade — requires JWT. Never trusts client `userId` body; uses `req.user.sub`.
 * Production: sets premium only when Razorpay HMAC verifies (`RAZORPAY_KEY_SECRET` + payment fields).
 * Non-production: optional `DEV_ALLOW_PREMIUM_UPGRADE=true` allows upgrade without payment (QA only).
 */
async function upgradeUser(req, res, next) {
  try {
    const userId = req.user?.sub;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    const isProd = process.env.NODE_ENV === 'production';
    const hasRazorpaySecret = String(process.env.RAZORPAY_KEY_SECRET || '').trim().length > 0;
    const orderId = req.body?.razorpay_order_id ?? req.body?.razorpayOrderId;
    const paymentId = req.body?.razorpay_payment_id ?? req.body?.razorpayPaymentId;
    const signature = req.body?.razorpay_signature ?? req.body?.razorpaySignature;

    const verified = hasRazorpaySecret && verifyRazorpaySignature(orderId, paymentId, signature);
    const devBypass =
      !isProd && String(process.env.DEV_ALLOW_PREMIUM_UPGRADE || '').trim() === 'true';

    if (isProd && !hasRazorpaySecret) {
      return res.status(503).json({
        success: false,
        code: 'UPGRADE_DISABLED',
        message:
          'Premium upgrade via this API is disabled until payment verification is configured (RAZORPAY_KEY_SECRET). Use Google Play Billing for the store build.',
      });
    }

    if (!verified && !devBypass) {
      return res.status(400).json({
        success: false,
        code: 'PAYMENT_VERIFICATION_FAILED',
        message:
          'Valid verified payment is required. Ensure Razorpay checkout includes order_id and that the server has RAZORPAY_KEY_SECRET.',
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isPremium = true;
    await user.save();
    const fresh = await User.findById(userId);
    return res.json({
      success: true,
      data: userUpgradeData(fresh),
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { upgradeUser };
