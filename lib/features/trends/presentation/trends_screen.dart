import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/models/trends_models.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';
import 'package:reelboost_ai/widgets/section_title.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  TrendsPayload? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(reelboostApiProvider);
    try {
      final d = await api.getTrends();
      setState(() => _data = d);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: AppLoadingIndicator(
                    size: 40,
                    strokeWidth: 3,
                    message: 'Loading trends…',
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _data == null
                      ? const SizedBox.shrink()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            children: [
                              Text(
                                'Source: ${_data!.source} · ${_data!.updatedAt}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                              ),
                              const SizedBox(height: 16),
                              const SectionTitle('Trending reel ideas'),
                              ..._data!.ideas.map(
                                (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    tileColor: AppTheme.cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    title: Text(i.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text('${i.niche} · ${i.difficulty}'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const SectionTitle('Sounds (mock)'),
                              ..._data!.sounds.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    tileColor: AppTheme.cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    title: Text(s.name),
                                    subtitle: Text('${s.mood} — ${s.note}'),
                                  ),
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
