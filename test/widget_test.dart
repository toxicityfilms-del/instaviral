import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelboost_ai/core/config/api_config.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/auth/presentation/login_screen.dart';
import 'package:reelboost_ai/services/api_runtime.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ApiRuntime.seedForTest(baseUrl: ApiConfig.apiBaseUrl);
  });

  testWidgets('Login screen shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const LoginScreen(),
        ),
      ),
    );
    expect(find.text('ReelBoost AI'), findsOneWidget);
  });
}
