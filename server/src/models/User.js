const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      trim: true,
      default: '',
    },
    subscriptionTier: {
      type: String,
      enum: ['free', 'premium'],
      default: 'free',
    },
    premiumExpiresAt: {
      type: Date,
      default: null,
    },
    trendAlertsEnabled: {
      type: Boolean,
      default: true,
    },
    fcmToken: {
      type: String,
      default: null,
    },
    fcmTokenUpdatedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
