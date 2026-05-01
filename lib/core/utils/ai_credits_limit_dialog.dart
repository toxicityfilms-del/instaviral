import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/profile/presentation/profile_screen.dart';

/// Production copy for shared daily AI cap (`403` + `LIMIT_REACHED` / `POST_ANALYZE_LIMIT` → [PostAnalyzeLimitException]).
Future<void> showAiCreditsLimitDialog(
  BuildContext context, {
  VoidCallback? onUpgrade,
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
      title: const Text('Daily Free Limit Reached'),
      content: const Text(
        'You have used your 3 free AI credits today. Upgrade to Premium for unlimited AI.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            if (onUpgrade != null) {
              onUpgrade();
            } else {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            }
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}

Future<void> navigateToProfileForUpgrade(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
  );
}

/// After a successful AI call when remaining hits 0 (free tier).
void showLastFreeAiUseSnackBar(BuildContext context, {VoidCallback? onUpgrade}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('That was your last free AI use for today.'),
      action: SnackBarAction(
        label: 'Upgrade',
        onPressed: () {
          if (!context.mounted) return;
          if (onUpgrade != null) {
            onUpgrade();
          } else {
            navigateToProfileForUpgrade(context);
          }
        },
      ),
    ),
  );
}
