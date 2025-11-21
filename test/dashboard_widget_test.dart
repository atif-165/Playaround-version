import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:playaround/core/i18n/localizations.dart';
import 'package:playaround/data/repositories/dashboard_repository.dart';
import 'package:playaround/presentation/core/providers/auth_state_provider.dart';
import 'package:playaround/presentation/dashboard/home_screen.dart';
import 'package:playaround/presentation/widgets/shimmer_loading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppLocalizations.load();
  });

  testWidgets('dashboard shows shimmer while loading', (tester) async {
    final completer = Completer<DashboardData>();
    final authNotifier = AuthStateNotifier()..signIn(role: AppUserRole.player);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(completer.future),
          ),
        ],
        child: const _DashboardHarness(),
      ),
    );

    await tester.pump();

    expect(find.byType(ShimmerLoading), findsWidgets);

    completer.complete(_dummyDashboardData());
    await tester.pumpAndSettle();

    expect(find.text('Your player dashboard'), findsOneWidget);
  });

  testWidgets('coach role renders coach dashboard headline', (tester) async {
    final authNotifier = AuthStateNotifier()..signIn(role: AppUserRole.coach);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
              Future.value(
                  _dummyDashboardData(headline: 'Coach dashboard data')),
            ),
          ),
        ],
        child: const _DashboardHarness(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Coach performance overview'), findsOneWidget);
  });
}

class FakeDashboardRepository extends DashboardRepository {
  FakeDashboardRepository(this._future) : super();

  final Future<DashboardData> _future;

  @override
  Future<DashboardData> fetchDashboardData(AppUserRole role) => _future;
}

class _DashboardHarness extends ConsumerWidget {
  const _DashboardHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: const HomeScreen(),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    );
  }
}

DashboardData _dummyDashboardData(
    {String headline = 'Ready for the next session?'}) {
  return DashboardData(
    headline: headline,
    stats: [
      DashboardStat(label: 'Stat A', value: '1', delta: 0.1),
      DashboardStat(label: 'Stat B', value: '2', delta: -0.05),
    ],
    events: [
      DashboardEvent(
        title: 'Event A',
        date: 'Nov 12',
        location: 'Arena',
        status: 'upcoming',
      ),
    ],
    highlights: const ['Highlight 1'],
    actions: const ['Action 1'],
  );
}
