const crypto = require('crypto');
const { validationResult } = require('express-validator');
const Razorpay = require('razorpay');
const User = require('../models/User');
const { serializeUser } = require('../utils/userHelpers');

function getRazorpay() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) {
    const err = new Error('Razorpay is not configured');
    err.status = 503;
    throw err;
  }
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

function premiumAmountPaise() {
  const raw = process.env.PREMIUM_AMOUNT_PAISE || '49900';
  const n = parseInt(raw, 10);
  return Number.isFinite(n) && n > 0 ? n : 49900;
}

function premiumDays() {
  const raw = process.env.PREMIUM_DAYS || '30';
  const n = parseInt(raw, 10);
  return Number.isFinite(n) && n > 0 ? n : 30;
}

async function createOrder(req, res, next) {
  try {
    const userId = req.user.sub;
    const rzp = getRazorpay();
    const amount = premiumAmountPaise();
    const receipt = `rb_${userId}_${Date.now()}`.slice(0, 40);
    const order = await rzp.orders.create({
      amount,
      currency: 'INR',
      receipt,
      notes: { userId: String(userId), purpose: 'reelboost_premium' },
    });
    return res.json({
      success: true,
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        keyId: process.env.RAZORPAY_KEY_ID,
      },
    });
  } catch (e) {
    return next(e);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const { razorpay_order_id: orderId, razorpay_payment_id: paymentId, razorpay_signature: signature } =
      req.body;
    const secret = process.env.RAZORPAY_KEY_SECRET;
    if (!secret) {
      const err = new Error('Razorpay is not configured');
      err.status = 503;
      throw err;
    }
    const body = `${orderId}|${paymentId}`;
    const expected = crypto.createHmac('sha256', secret).update(body).digest('hex');
    if (expected !== signature) {
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const days = premiumDays();
    const now = new Date();
    const base =
      user.premiumExpiresAt && new Date(user.premiumExpiresAt) > now
        ? new Date(user.premiumExpiresAt)
        : now;
    const nextExpiry = new Date(base.getTime() + days * 24 * 60 * 60 * 1000);

    user.subscriptionTier = 'premium';
    user.premiumExpiresAt = nextExpiry;
    await user.save();

    return res.json({
      success: true,
      data: { user: serializeUser(user) },
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { createOrder, verifyPayment };
