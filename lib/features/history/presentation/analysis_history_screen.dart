import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/haptics/app_haptics.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/services/analysis_history_service.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/post_analysis_pack.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:share_plus/share_plus.dart';

class AnalysisHistoryScreen extends ConsumerStatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  ConsumerState<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends ConsumerState<AnalysisHistoryScreen> {
  List<AnalysisHistoryEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await AnalysisHistoryService.load();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _confirmClear(AppStrings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.historyClearTitle),
        content: Text(s.historyClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.clear)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AnalysisHistoryService.clear();
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.historyCleared)));
    }
  }

  String _sourceLabel(AppStrings s, String src) {
    if (src == 'media_analyze') return s.tileAnalyzeMedia;
    if (src == 'post_analyze') return s.tilePostAnalyzer;
    return src;
  }

  Future<void> _copyPack(PostAnalysisResult r, AppStrings s) async {
    AppHaptics.copy();
    await Clipboard.setData(ClipboardData(text: postAnalysisCopyPack(r)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.snackFullPackCopied)));
  }

  Future<void> _sharePack(PostAnalysisResult r) async {
    await Share.share(postAnalysisCopyPack(r), subject: 'ReelBoost pack');
  }

  void _openDetail(AnalysisHistoryEntry e, AppStrings s) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _HistoryDetailScreen(
          entry: e,
          sourceLabel: _sourceLabel(s, e.source),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: s.historyClearAll,
              onPressed: () => _confirmClear(s),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          s.historyEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.onCardSecondary(context), height: 1.45),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = _items[i];
                          final dt = DateTime.fromMillisecondsSinceEpoch(e.createdAtMs);
                          final dateStr =
                              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          return AppCard(
                            onTap: () => _openDetail(e, s),
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: e.pinned ? s.historyUnpin : s.historyPin,
                                  onPressed: () async {
                                    await AnalysisHistoryService.setPinned(e.id, !e.pinned);
                                    await _reload();
                                  },
                                  icon: Icon(
                                    e.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                    color: e.pinned ? AppTheme.accent2 : AppTheme.onCardSecondary(context),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppTheme.onCardPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_sourceLabel(s, e.source)} · $dateStr',
                                        style: TextStyle(
                                          color: AppTheme.onCardSecondary(context),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.historyCopyPackTooltip,
                                  onPressed: () => _copyPack(e.result, s),
                                  icon: const Icon(Icons.copy_all_rounded),
                                ),
                                IconButton(
                                  tooltip: s.actionSharePack,
                                  onPressed: () => _sharePack(e.result),
                                  icon: const Icon(Icons.share_rounded),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppTheme.onCardSecondary(context)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

class _HistoryDetailScreen extends ConsumerWidget {
  const _HistoryDetailScreen({
    required this.entry,
    required this.sourceLabel,
  });

  final AnalysisHistoryEntry entry;
  final String sourceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final r = entry.result;

    return Scaffold(
      appBar: AppBar(
        title: Text(sourceLabel),
        actions: [
          IconButton(
            tooltip: s.historyDetailDelete,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.historyDeleteConfirmTitle),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await AnalysisHistoryService.remove(entry.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Share.share(postAnalysisCopyPack(r), subject: 'ReelBoost'),
                        icon: const Icon(Icons.share_rounded),
                        label: Text(s.actionSharePack),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: s.historyCopyFullPack,
                  icon: Icons.copy_all_rounded,
                  onPressed: () async {
                    AppHaptics.copy();
                    await Clipboard.setData(ClipboardData(text: postAnalysisCopyPack(r)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.snackFullPackCopied)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                _DetailBlock(title: 'Hook', body: r.hook),
                _DetailBlock(title: 'Caption', body: r.caption),
                _DetailBlock(title: 'Hashtags', body: r.hashtags.join(' ')),
                _DetailBlock(title: 'Best time', body: r.bestTime),
                _DetailBlock(title: 'Audio / trend', body: r.audio),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = body.trim().isEmpty ? '—' : body.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SelectableText(
              text,
              style: TextStyle(color: AppTheme.onCardPrimary(context).withValues(alpha: 0.88), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
