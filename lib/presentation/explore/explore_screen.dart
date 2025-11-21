import 'package:flutter/material.dart';

import '../../core/i18n/localizations.dart';
import '../widgets/stat_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  strings.translate('explore.title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.translate('explore.subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 24),
                StatCard(
                  label: strings.translate('explore.metrics.sessions'),
                  value: '48',
                  delta: 0.21,
                ),
                const SizedBox(height: 16),
                StatCard(
                  label: strings.translate('explore.metrics.new_connections'),
                  value: '132',
                  delta: 0.35,
                ),
                const SizedBox(height: 16),
                StatCard(
                  label: strings.translate('explore.metrics.trending_events'),
                  value: '9',
                  delta: -0.05,
                ),
                const SizedBox(height: 32),
                Text(
                  strings.translate('explore.insights_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ..._insights(strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _insights(AppLocalizations strings) {
    final items = [
      strings.translate('explore.insights.network'),
      strings.translate('explore.insights.events'),
      strings.translate('explore.insights.content'),
    ];

    return [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.lightBlueAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
