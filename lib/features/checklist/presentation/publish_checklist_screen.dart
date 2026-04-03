import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/widgets/app_card.dart';

class PublishChecklistScreen extends ConsumerStatefulWidget {
  const PublishChecklistScreen({super.key});

  @override
  ConsumerState<PublishChecklistScreen> createState() => _PublishChecklistScreenState();
}

class _PublishChecklistScreenState extends ConsumerState<PublishChecklistScreen> {
  final _checked = <int, bool>{};

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final items = [
      s.checklistItemHook,
      s.checklistItemCaption,
      s.checklistItemHashtags,
      s.checklistItemCoverText,
      s.checklistItemAudio,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.checklistAppBar)),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Text(
                  s.checklistIntro,
                  style: TextStyle(color: AppTheme.onCardSecondary(context), height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(items.length, (i) {
                final done = _checked[i] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: CheckboxListTile(
                      value: done,
                      onChanged: (v) => setState(() => _checked[i] = v ?? false),
                      title: Text(
                        items[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onCardPrimary(context),
                          height: 1.35,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return AppTheme.accent;
                        return null;
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
