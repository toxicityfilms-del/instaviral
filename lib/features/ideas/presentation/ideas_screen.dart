import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/core/utils/shared_ai_limit_dialog.dart';
import 'package:reelboost_ai/services/reelboost_api_service.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:reelboost_ai/widgets/section_title.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  final _niche = TextEditingController();
  List<String> _ideas = [];
  bool _loading = false;

  @override
  void dispose() {
    _niche.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final n = _niche.text.trim();
    if (n.isEmpty) return;
    setState(() {
      _loading = true;
      _ideas = [];
    });
    final api = ref.read(reelboostApiProvider);
    final session = ref.read(authControllerProvider).asData?.value;
    try {
      final r = await api.generateIdeas(n);
      setState(() => _ideas = r.value);
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
      final detail =
          e.message.trim().isNotEmpty ? e.message.trim() : kSharedAiDailyLimitMessage;
      await showSharedAiDailyLimitDialog(context, serverDetail: detail, limit: e.limit);
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
      appBar: AppBar(title: const Text('Reel ideas')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _niche,
                  decoration: const InputDecoration(
                    labelText: 'Niche',
                    hintText: 'e.g. skincare routines',
                  ),
                  onSubmitted: (_) => _run(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Generate 10 ideas',
                  loading: _loading,
                  onPressed: _loading ? null : _run,
                  icon: Icons.movie_filter_rounded,
                ),
                const SizedBox(height: 24),
                if (_ideas.isNotEmpty) const SectionTitle('Ideas'),
                Expanded(
                  child: ListView.separated(
                    itemCount: _ideas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_ideas[i], style: const TextStyle(height: 1.4))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
