function isPremiumActive(user) {
  if (!user || (user.subscriptionTier || 'free') !== 'premium') return false;
  if (!user.premiumExpiresAt) return false;
  return new Date(user.premiumExpiresAt) > new Date();
}

function serializeUser(user) {
  const premium = isPremiumActive(user);
  return {
    id: user._id,
    email: user.email,
    name: user.name,
    subscriptionTier: user.subscriptionTier || 'free',
    premiumExpiresAt: user.premiumExpiresAt || null,
    trendAlertsEnabled: user.trendAlertsEnabled !== false,
    isPremium: premium,
  };
}

module.exports = { isPremiumActive, serializeUser };
