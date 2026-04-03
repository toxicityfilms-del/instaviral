import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/home/presentation/home_screen.dart';
import 'package:reelboost_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reelboost_ai/features/shell/presentation/whats_new_gate.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingDoneKey = 'onboarding_v3_complete';

class PostLoginShell extends ConsumerStatefulWidget {
  const PostLoginShell({super.key});

  @override
  ConsumerState<PostLoginShell> createState() => _PostLoginShellState();
}

class _PostLoginShellState extends ConsumerState<PostLoginShell> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _onboardingDone = p.getBool(_onboardingDoneKey) ?? false);
  }

  Future<void> _finishOnboarding() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardingDoneKey, true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
          child: const Center(child: AppLoadingIndicator(size: 36)),
        ),
      );
    }
    if (!_onboardingDone!) {
      return OnboardingScreen(onFinished: _finishOnboarding);
    }
    return const WhatsNewGate(child: HomeScreen());
  }
}
