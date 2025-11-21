import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/localizations.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../core/providers/auth_state_provider.dart';
import '../widgets/shimmer_loading.dart';
import 'dashboard_screen.dart';
import 'team_dashboard_screen.dart';
import 'mvp_dashboard_screen.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository());

final dashboardDataProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  final role = ref.watch(authStateProvider).role;
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchDashboardData(role);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final authState = ref.watch(authStateProvider);
    final asyncData = ref.watch(dashboardDataProvider);

    return asyncData.when(
      loading: () => _buildLoading(strings),
      error: (error, stackTrace) => _buildError(context, strings, error),
      data: (data) => _HomeDashboardBody(
        data: data,
        role: authState.role,
      ),
    );
  }

  Widget _buildLoading(AppLocalizations strings) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.translate('dashboard.loading_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const ShimmerLoading(height: 160),
              const SizedBox(height: 16),
              const ShimmerLoading(height: 120),
              const SizedBox(height: 16),
              const ShimmerLoading(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppLocalizations strings,
    Object error,
  ) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.translate('dashboard.error_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardBody extends StatelessWidget {
  const _HomeDashboardBody({
    required this.data,
    required this.role,
  });

  final DashboardData data;
  final AppUserRole role;

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case AppUserRole.player:
      case AppUserRole.guest:
        return DashboardScreen(data: data);
      case AppUserRole.coach:
      case AppUserRole.teamOwner:
        return TeamDashboardScreen(data: data, role: role);
      case AppUserRole.mvp:
        return MvpDashboardScreen(data: data);
      case AppUserRole.admin:
        return TeamDashboardScreen(data: data, role: role);
    }
  }
}
