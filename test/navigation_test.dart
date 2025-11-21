import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:playaround/config/app_routes.dart';
import 'package:playaround/core/i18n/localizations.dart';
import 'package:playaround/presentation/auth/login_screen.dart';
import 'package:playaround/presentation/core/providers/auth_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppLocalizations.load();
  });

  testWidgets('unauthenticated users are redirected to login', (tester) async {
    final authNotifier = AuthStateNotifier(); // defaults to unauthenticated

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
        child: const _TestRouterApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('coach role shows coach analytics tab', (tester) async {
    final authNotifier = AuthStateNotifier()..signIn(role: AppUserRole.coach);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
        child: const _TestRouterApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Coach Hub'), findsOneWidget);
  });
}

class _TestRouterApp extends ConsumerWidget {
  const _TestRouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    );
  }
}
