import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/models/hashtag_models.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';
import 'package:reelboost_ai/widgets/section_title.dart';

class HashtagScreen extends ConsumerStatefulWidget {
  const HashtagScreen({super.key});

  @override
  ConsumerState<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends ConsumerState<HashtagScreen> with SingleTickerProviderStateMixin {
  final _keyword = TextEditingController();
  late TabController _tabs;
  HashtagBuckets? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _keyword.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final kw = _keyword.text.trim();
    if (kw.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final api = ref.read(reelboostApiProvider);
    try {
      final r = await api.generateHashtags(kw);
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
      appBar: AppBar(title: const Text('Hashtag generator')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _keyword,
                  decoration: const InputDecoration(
                    labelText: 'Keyword',
                    hintText: 'e.g. fitness',
                  ),
                  onSubmitted: (_) => _run(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Generate 30 hashtags',
                  loading: _loading,
                  onPressed: _loading ? null : _run,
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(height: 24),
                if (_result != null) ...[
                  const SectionTitle('Competition buckets'),
                  TabBar(
                    controller: _tabs,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(color: AppTheme.accent2, width: 3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    dividerColor: Colors.white.withValues(alpha: 0.08),
                    tabs: const [
                      Tab(text: 'High'),
                      Tab(text: 'Medium'),
                      Tab(text: 'Low'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _TagList(_result!.high),
                        _TagList(_result!.medium),
                        _TagList(_result!.low),
                      ],
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

class _TagList extends StatelessWidget {
  const _TagList(this.tags);
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: tags.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            tags[i],
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
          ),
        );
      },
    );
  }
}
