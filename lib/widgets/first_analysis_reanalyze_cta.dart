import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';

/// High-emphasis gradient CTA with animated glow (first-analysis “re-analyze” flow).
class FirstAnalysisReanalyzeCta extends StatefulWidget {
  const FirstAnalysisReanalyzeCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<FirstAnalysisReanalyzeCta> createState() => _FirstAnalysisReanalyzeCtaState();
}

class _FirstAnalysisReanalyzeCtaState extends State<FirstAnalysisReanalyzeCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _disabled => widget.onPressed == null || widget.loading;

  static const LinearGradient _hotGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C3AED),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (!_disabled) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FirstAnalysisReanalyzeCta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_disabled) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final glow = 0.85 + t * 0.55;
        final spread = -2.0 + t * 3;

        return SizedBox(
          width: double.infinity,
          child: Transform.scale(
            scale: disabled ? 1.0 : 1.0 + t * 0.008,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: disabled ? null : _hotGradient,
                color: disabled ? Colors.white.withValues(alpha: 0.07) : null,
                border: Border.all(
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.1)
                      : Color.lerp(
                          Colors.white.withValues(alpha: 0.35),
                          AppTheme.accent2.withValues(alpha: 0.75),
                          t,
                        )!,
                  width: disabled ? 1 : 1.5,
                ),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.28 * glow),
                          blurRadius: 22 + t * 14,
                          spreadRadius: spread,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppTheme.accent2.withValues(alpha: 0.45 * glow),
                          blurRadius: 28 + t * 12,
                          spreadRadius: -1 + t * 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.4 * glow),
                          blurRadius: 18 + t * 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: disabled ? null : widget.onPressed,
                  splashColor: Colors.white.withValues(alpha: 0.22),
                  highlightColor: Colors.white.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.loading) ...[
                          const AppLoadingIndicator(size: 22, strokeWidth: 2.5),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                fontSize: 15,
                                height: 1.25,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.98), size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.15,
                                fontSize: 15,
                                height: 1.25,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                  Shadow(
                                    color: AppTheme.accent2.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
