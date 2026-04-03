const { validationResult } = require('express-validator');
const User = require('../models/User');
const { serializeUser } = require('../utils/userHelpers');

async function getMe(req, res, next) {
  try {
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    return res.json({ success: true, data: { user: serializeUser(user) } });
  } catch (e) {
    return next(e);
  }
}

async function patchMe(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    if (typeof req.body.trendAlertsEnabled === 'boolean') {
      user.trendAlertsEnabled = req.body.trendAlertsEnabled;
    }
    await user.save();
    return res.json({ success: true, data: { user: serializeUser(user) } });
  } catch (e) {
    return next(e);
  }
}

async function registerFcmToken(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const { token } = req.body;
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    user.fcmToken = token;
    user.fcmTokenUpdatedAt = new Date();
    await user.save();
    return res.json({ success: true });
  } catch (e) {
    return next(e);
  }
}

module.exports = { getMe, patchMe, registerFcmToken };
