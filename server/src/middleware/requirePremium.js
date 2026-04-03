const User = require('../models/User');
const { isPremiumActive } = require('../utils/userHelpers');

async function requirePremium(req, res, next) {
  try {
    const user = await User.findById(req.user.sub);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    if (!isPremiumActive(user)) {
      return res.status(402).json({
        success: false,
        code: 'PREMIUM_REQUIRED',
        message: 'Premium subscription required for this feature',
      });
    }
    req.dbUser = user;
    return next();
  } catch (e) {
    return next(e);
  }
}

module.exports = { requirePremium };
