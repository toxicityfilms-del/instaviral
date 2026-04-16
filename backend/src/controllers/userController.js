const { validationResult } = require('express-validator');
const User = require('../models/User');

async function upgrade(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const userId = String(req.body.userId || '').trim();
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isPremium = true;
    await user.save();

    return res.json({
      success: true,
      data: {
        id: user._id != null ? String(user._id) : '',
        email: user.email || '',
        name: user.name || '',
        bio: user.bio || '',
        instagramLink: user.instagramLink || '',
        facebookLink: user.facebookLink || '',
        tiktokLink: user.tiktokLink || '',
        niche: user.niche || '',
        isPremium: true,
      },
    });
  } catch (e) {
    return next(e);
  }
}

module.exports = { upgrade };
