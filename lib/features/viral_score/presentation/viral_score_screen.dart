import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/models/viral_models.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:reelboost_ai/widgets/section_title.dart';

class ViralScoreScreen extends ConsumerStatefulWidget {
  const ViralScoreScreen({super.key});

  @override
  ConsumerState<ViralScoreScreen> createState() => _ViralScoreScreenState();
}

class _ViralScoreScreenState extends ConsumerState<ViralScoreScreen> {
  final _caption = TextEditingController();
  final _hashtags = TextEditingController();
  ViralAnalysis? _result;
  bool _loading = false;

  @override
  void dispose() {
    _caption.dispose();
    _hashtags.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final c = _caption.text.trim();
    if (c.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final api = ref.read(reelboostApiProvider);
    try {
      final r = await api.analyzeViral(caption: c, hashtags: _hashtags.text.trim());
      setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viral score')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _caption,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _hashtags,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Hashtags (optional)',
                    hintText: '#fitness #gym ...',
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Analyze',
                  loading: _loading,
                  onPressed: _loading ? null : _run,
                  icon: Icons.insights_rounded,
                ),
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.35),
                          AppTheme.accent2.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_result!.score}',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Viral score (0–100)\nHook, hashtags, length, emoji, CTA',
                            style: TextStyle(height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Improvements'),
                  ..._result!.suggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.accent2),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s, style: const TextStyle(height: 1.35))),
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
    );
  }
}
