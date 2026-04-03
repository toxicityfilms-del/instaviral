import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';

/// Rounded, high-contrast spinner for buttons and full-page loads.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 36,
    this.strokeWidth = 3,
    this.message,
  });

  final double size;
  final double strokeWidth;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent2),
        backgroundColor: AppTheme.accent.withValues(alpha: 0.22),
      ),
    );

    if (message == null || message!.isEmpty) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 18),
        Text(
          message!,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
