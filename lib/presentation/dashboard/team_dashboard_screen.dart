import 'package:flutter/material.dart';

import '../../core/i18n/localizations.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../core/providers/auth_state_provider.dart';
import '../widgets/action_chip.dart';
import '../widgets/event_card.dart';
import '../widgets/stat_card.dart';

class TeamDashboardScreen extends StatelessWidget {
  const TeamDashboardScreen({
    required this.data,
    required this.role,
    super.key,
  });

  final DashboardData data;
  final AppUserRole role;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(strings),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.headline,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _BuildStats(stats: data.stats),
                      const SizedBox(height: 24),
                      Text(
                        strings.translate('dashboard.team.events_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final event = data.events[index];
                    return EventCard(
                      title: event.title,
                      subtitle: event.location,
                      trailing: event.date,
                      status: event.status,
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: data.events.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.translate('dashboard.team.actions_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final action in data.actions)
                            DashboardActionChip(label: action),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.translate('dashboard.team.highlights_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      for (final highlight in data.highlights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.insights,
                                  color: Colors.cyanAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  highlight,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headline(AppLocalizations strings) {
    switch (role) {
      case AppUserRole.coach:
        return strings.translate('dashboard.team.headline_coach');
      case AppUserRole.teamOwner:
        return strings.translate('dashboard.team.headline_owner');
      case AppUserRole.admin:
        return strings.translate('dashboard.team.headline_admin');
      default:
        return strings.translate('dashboard.team.headline_generic');
    }
  }
}

class _BuildStats extends StatelessWidget {
  const _BuildStats({required this.stats});

  final List<DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 3 : 1;
        final childAspectRatio = isWide ? 1.6 : 2.6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat.label,
              value: stat.value,
              delta: stat.delta,
            );
          },
        );
      },
    );
  }
}
