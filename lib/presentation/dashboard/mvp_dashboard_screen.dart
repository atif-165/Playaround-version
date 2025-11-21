import 'package:flutter/material.dart';

import '../../core/i18n/localizations.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../widgets/action_chip.dart';
import '../widgets/event_card.dart';
import '../widgets/stat_card.dart';

class MvpDashboardScreen extends StatelessWidget {
  const MvpDashboardScreen({
    required this.data,
    super.key,
  });

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF270F34),
              Color(0xFF161A31),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                        strings.translate('dashboard.mvp.headline'),
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
                      _StatsRow(stats: data.stats),
                      const SizedBox(height: 28),
                      Text(
                        strings.translate('dashboard.mvp.events_title'),
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
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.translate('dashboard.mvp.actions_title'),
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
                      const SizedBox(height: 28),
                      Text(
                        strings.translate('dashboard.mvp.highlights_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...data.highlights.map(
                        (highlight) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Colors.orangeAccent),
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
                      ),
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
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: StatCard(
                    label: stat.label,
                    value: stat.value,
                    delta: stat.delta,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
