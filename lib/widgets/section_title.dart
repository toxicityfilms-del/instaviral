import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.bottomPadding = 14});

  final String text;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.15,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
