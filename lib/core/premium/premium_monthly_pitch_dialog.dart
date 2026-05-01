import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';

/// Premium pitch: **₹199/month**. In release, never starts Razorpay — shows “coming soon” only.
Future<void> showPremiumMonthlyPitchDialog(
  BuildContext context, {
  required Future<void> Function() onDebugStartPurchase,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.workspace_premium_rounded, color: AppTheme.accent.withValues(alpha: 0.95), size: 36),
      title: const Text('Upgrade to Premium'),
      content: const Text(
        'ReelBoost Premium — ₹199/month\n\n'
        'Unlimited AI: captions, hashtags, reel ideas, post analysis, and analyze media. '
        'Free accounts are limited to 3 AI credits per day.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            if (!context.mounted) return;
            if (kReleaseMode) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium upgrade coming soon')),
              );
            } else {
              await onDebugStartPurchase();
            }
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}
