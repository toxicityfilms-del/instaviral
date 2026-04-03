import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final pages = [
      _OnboardPageData(s.onboardingTitle1, s.onboardingBody1, Icons.auto_awesome_rounded),
      _OnboardPageData(s.onboardingTitle2, s.onboardingBody2, Icons.compare_arrows_rounded),
      _OnboardPageData(s.onboardingTitle3, s.onboardingBody3, Icons.ios_share_rounded),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.onFinished(),
                  child: Text(s.onboardingSkip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: Icon(p.icon, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 16),
                          AppCard(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              p.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.onCardSecondary(context),
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i == _index
                            ? AppTheme.accent
                            : AppTheme.onCardSecondary(context).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GradientButton(
                  label: _index < pages.length - 1 ? s.onboardingNext : s.onboardingStart,
                  icon: _index < pages.length - 1 ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded,
                  onPressed: () {
                    if (_index < pages.length - 1) {
                      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
                    } else {
                      widget.onFinished();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  const _OnboardPageData(this.title, this.body, this.icon);
  final String title;
  final String body;
  final IconData icon;
}
