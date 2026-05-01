import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/premium/premium_checkout.dart';
import 'package:reelboost_ai/core/premium/premium_monthly_pitch_dialog.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/ai_credits_limit_dialog.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/models/caption_models.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';
import 'package:reelboost_ai/widgets/ai_result_source_label.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:reelboost_ai/widgets/section_title.dart';

class CaptionScreen extends ConsumerStatefulWidget {
  const CaptionScreen({super.key});

  @override
  ConsumerState<CaptionScreen> createState() => _CaptionScreenState();
}

class _CaptionScreenState extends ConsumerState<CaptionScreen> {
  final _idea = TextEditingController();
  CaptionResult? _result;
  String? _resultSource;
  bool _loading = false;

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final t = _idea.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final api = ref.read(reelboostApiProvider);
    final session = ref.read(authControllerProvider).asData?.value;
    try {
      final r = await api.generateCaption(t);
      setState(() {
        _result = r.value;
        _resultSource = r.source;
      });
      if (session != null && r.limit != null && r.remaining != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              session.withPostAnalyzeUsage(
                isPremium: false,
                postAnalyzeLimit: r.limit,
                postAnalyzeRemaining: r.remaining,
                postAnalyzeAdRewardsRemaining: session.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
      if (!mounted) return;
      if (r.remaining != null && r.remaining! <= 0) {
        showLastFreeAiUseSnackBar(context);
      }
    } on PostAnalyzeLimitException catch (e) {
      if (!mounted) return;
      await showAiCreditsLimitDialog(
        context,
        onUpgrade: () => showPremiumMonthlyPitchDialog(
          context,
          onDebugStartPurchase: () => attemptPremiumRazorpayCheckout(ref, context),
        ),
      );
      final s = ref.read(authControllerProvider).asData?.value;
      if (s != null) {
        ref.read(authControllerProvider.notifier).applyUser(
              s.withPostAnalyzeUsage(
                isPremium: false,
                postAnalyzeLimit: e.limit ?? s.postAnalyzeLimit,
                postAnalyzeRemaining: 0,
                postAnalyzeAdRewardsRemaining: s.postAnalyzeAdRewardsRemaining,
              ),
            );
      }
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
      appBar: AppBar(title: const Text('Caption + hooks')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _idea,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Your idea',
                    hintText: 'e.g. gym motivation',
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Generate caption',
                  loading: _loading,
                  onPressed: _loading ? null : _run,
                  icon: Icons.auto_fix_high_rounded,
                ),
                if (_result != null) ...[
                  const SizedBox(height: 28),
                  AiResultSourceLabel(source: _resultSource),
                  const SectionTitle('Viral caption'),
                  _CopyCard(_result!.caption),
                  const SizedBox(height: 16),
                  const SectionTitle('Hooks (2–3)'),
                  ..._result!.hooks.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CopyCard(h),
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

class _CopyCard extends StatelessWidget {
  const _CopyCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy'),
            ),
          ),
        ],
      ),
    );
  }
}
