import 'package:flutter/material.dart';

/// Shown when API `data.source` is set (`openai` vs `fallback` for premium paths).
class AiResultSourceLabel extends StatelessWidget {
  const AiResultSourceLabel({super.key, this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    final text = switch (source) {
      'fallback' => 'Basic result (Upgrade for better AI)',
      'openai' => 'AI powered result',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: Colors.white.withValues(alpha: 0.52),
        ),
      ),
    );
  }
}
