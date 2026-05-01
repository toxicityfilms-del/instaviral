import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/profile/presentation/profile_screen.dart';

Future<void> navigateToProfileForUpgrade(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
  );
}

/// Same pattern as [UploadPostScreen] daily limit: dialog + primary upgrade to Profile.
Future<void> showSharedAiDailyLimitDialog(
  BuildContext context, {
  String? serverDetail,
  int? limit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.hourglass_disabled_rounded,
        color: AppTheme.accent2.withValues(alpha: 0.95),
        size: 36,
      ),
      title: const Text('Daily limit reached'),
      content: Text(
        [
          if (serverDetail != null && serverDetail.trim().isNotEmpty) serverDetail.trim(),
          limit != null
              ? 'You’ve used all $limit free AI actions for today. Upgrade to Premium for unlimited access every day.'
              : 'You’ve used all your free AI actions for today. Upgrade to Premium for unlimited access every day.',
        ].where((s) => s.isNotEmpty).join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            navigateToProfileForUpgrade(context);
          },
          child: const Text('Upgrade to Premium'),
        ),
      ],
    ),
  );
}

/// Matches post analyzer behavior after the last free use succeeds.
void showLastFreeAiUseSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('That was your last free AI use for today.'),
      action: SnackBarAction(
        label: 'Upgrade',
        onPressed: () {
          if (context.mounted) navigateToProfileForUpgrade(context);
        },
      ),
    ),
  );
}
