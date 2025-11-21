import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../../../routing/routes.dart';

class PlayerOnboardingScreen extends ConsumerStatefulWidget {
  const PlayerOnboardingScreen({super.key});

  @override
  ConsumerState<PlayerOnboardingScreen> createState() =>
      _PlayerOnboardingScreenState();
}

class _PlayerOnboardingScreenState
    extends ConsumerState<PlayerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _position;
  String? _skillLevel;
  bool _isSubmitting = false;
  bool _completed = false;

  final List<String> _positions = const [
    'Forward',
    'Midfielder',
    'Defender',
    'Goalkeeper',
    'All-rounder',
  ];

  final List<String> _skillLevels = const [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSubmitting = true;
    });

    await ref.read(onboardingProvider.notifier).complete();

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _completed = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Player Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Help us customise drills, matches, and analytics for you.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Preferred Position',
                  ),
                  value: _position,
                  items: _positions
                      .map(
                        (position) => DropdownMenuItem(
                          value: position,
                          child: Text(position),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _position = value),
                  validator: (value) =>
                      value == null ? 'Select your position' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Skill Level',
                  ),
                  value: _skillLevel,
                  items: _skillLevels
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _skillLevel = value),
                  validator: (value) =>
                      value == null ? 'Select your skill level' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Playing'),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _completed
                      ? Container(
                          key: const ValueKey('completed'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You\'re all set! Loading your personalised dashboard.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
