import 'package:flutter/material.dart';

import '../../core/i18n/localizations.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF283048),
              Color(0xFF859398),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  strings.translate('admin.title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.translate('admin.subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 24),
                StatCard(
                  label: strings.translate('admin.metrics.system_health'),
                  value: '99.98%',
                  delta: 0.01,
                ),
                const SizedBox(height: 16),
                StatCard(
                  label: strings.translate('admin.metrics.active_flags'),
                  value: '6',
                  delta: -0.12,
                ),
                const SizedBox(height: 16),
                StatCard(
                  label: strings.translate('admin.metrics.support_sla'),
                  value: '94%',
                  delta: 0.04,
                ),
                const SizedBox(height: 28),
                Text(
                  strings.translate('admin.actions_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ..._actions(strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(AppLocalizations strings) {
    final items = [
      strings.translate('admin.actions.audit'),
      strings.translate('admin.actions.manage_roles'),
      strings.translate('admin.actions.review_reports'),
    ];

    return items
        .map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        )
        .toList();
  }
}
