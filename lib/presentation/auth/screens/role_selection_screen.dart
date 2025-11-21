import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../../../routing/routes.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);

    Future<void> handleSelection(UserRole role) async {
      await ref.read(onboardingProvider.notifier).selectRole(role);
      await ref.read(authStateProvider.notifier).setRole(role);
      if (!context.mounted) return;
      final route = role == UserRole.coach
          ? Routes.coachOnboardingScreen
          : Routes.playerOnboardingScreen;
      Navigator.of(context).pushReplacementNamed(route);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us how you\'ll use PlayAround so we can tailor your experience.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              RoleCard(
                title: 'Player',
                description:
                    'Track your skills, find venues, and connect with coaches.',
                icon: Icons.sports_soccer,
                isSelected: onboardingState.selectedRole == UserRole.player,
                onTap: () => handleSelection(UserRole.player),
              ),
              const SizedBox(height: 16),
              RoleCard(
                title: 'Coach',
                description:
                    'Manage sessions, monitor players, and grow your coaching business.',
                icon: Icons.sports,
                isSelected: onboardingState.selectedRole == UserRole.coach,
                onTap: () => handleSelection(UserRole.coach),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surface,
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
