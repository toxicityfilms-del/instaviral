import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: disabled ? null : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          color: disabled ? Colors.white.withValues(alpha: 0.07) : null,
          boxShadow: disabled ? null : AppTheme.buttonShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : onPressed,
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading) ...[
                    const AppLoadingIndicator(size: 22, strokeWidth: 2.5),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ] else ...[
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
