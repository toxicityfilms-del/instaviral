import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:reelboost_ai/core/notifications/local_notifications_service.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/settings/app_settings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/auth/presentation/login_screen.dart';
import 'package:reelboost_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:reelboost_ai/features/shell/presentation/post_login_shell.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/core/ads/app_ads_service.dart';
import 'package:reelboost_ai/services/api_bootstrap.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'async',
          ),
        );
      }
      return true;
    };

    try {
      await ApiBootstrap.initialize();
    } catch (e, st) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: e, stack: st, library: 'ApiBootstrap'),
        );
      }
    }

    try {
      await AppAdsService.ensureInitialized();
    } catch (e, st) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: e, stack: st, library: 'AppAdsService'),
        );
      }
    }

    try {
      await LocalNotificationsService.init();
    } catch (e, st) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: e, stack: st, library: 'LocalNotifications'),
        );
      }
    }

    runApp(const ProviderScope(child: ReelBoostApp()));
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(exception: error, stack: stack, library: 'zone'),
      );
    }
  });
}

class ReelBoostApp extends ConsumerWidget {
  const ReelBoostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      title: 'ReelBoost AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.localeCode == AppLocaleCode.hi ? const Locale('hi') : const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  String? _lastDeepLinkToken;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = _appLinks;
    if (appLinks == null) return;
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (_) {}

    try {
      _sub = appLinks.uriLinkStream.listen((uri) {
        _handleUri(uri);
      }, onError: (_) {});
    } catch (_) {}
  }

  String? _tokenFromUri(Uri uri) {
    final qp = uri.queryParameters['token']?.trim();
    if (qp != null && qp.isNotEmpty) return qp;
    final frag = uri.fragment;
    if (frag.contains('token=')) {
      final fragUri = Uri.tryParse('x://x/?$frag');
      final ft = fragUri?.queryParameters['token']?.trim();
      if (ft != null && ft.isNotEmpty) return ft;
    }
    return null;
  }

  bool _isResetPasswordPath(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final scheme = uri.scheme.toLowerCase();

    if (scheme == 'reelboost') return true;
    if (host.contains('reset-password')) return true;
    if (path.contains('/reset-password') || path == '/reset') return true;
    return false;
  }

  void _handleUri(Uri uri) {
    if (!_isResetPasswordPath(uri)) return;
    final token = _tokenFromUri(uri);
    if (token == null || token.isEmpty) return;
    if (_lastDeepLinkToken == token) return;
    _lastDeepLinkToken = token;

    final nav = _rootNavigatorKey.currentState;
    final context = _rootNavigatorKey.currentContext;
    if (nav == null || context == null) return;

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(initialToken: token),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const PostLoginShell();
      },
      loading: () => Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
          child: const Center(
            child: AppLoadingIndicator(
              size: 40,
              strokeWidth: 3.2,
              message: 'Restoring session…',
            ),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: AppCard(
                padding: const EdgeInsets.all(22),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
