import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsWhatsNewVersion = 'whats_new_seen_version_v1';

/// Shows a one-time “what’s new” dialog per app [version] from [PackageInfo].
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    final info = await PackageInfo.fromPlatform();
    final ver = info.version;
    final p = await SharedPreferences.getInstance();
    final seen = p.getString(_prefsWhatsNewVersion);
    if (!mounted || seen == ver) return;

    final s = ref.read(appStringsProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.whatsNewTitle),
        content: SingleChildScrollView(child: Text(s.whatsNewBody)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.whatsNewGotIt),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await p.setString(_prefsWhatsNewVersion, ver);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
