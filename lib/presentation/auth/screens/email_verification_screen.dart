import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../../../routing/routes.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  late final ProviderSubscription<AuthState> _subscription;
  Timer? _pollTimer;
  bool _resent = false;
  String? _errorMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _subscription = ref.listenManual<AuthState>(
      authStateProvider,
      _handleAuthChange,
    );
  }

  @override
  void dispose() {
    _subscription.close();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ref.read(authStateProvider.notifier).refreshUser(),
    );
  }

  void _handleAuthChange(AuthState? previous, AuthState next) {
    if (!mounted) return;
    final onboardingState = ref.read(onboardingProvider);
    final onboardingComplete =
        onboardingState.isComplete || next.isOnboardingComplete;

    void navigateTo(String route) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    }

    if (next.status == AuthStatus.authenticatedPlayer ||
        next.status == AuthStatus.authenticatedCoach) {
      final role = next.role;
      if (role == null) {
        navigateTo(Routes.roleSelectionScreen);
        return;
      }
      if (onboardingComplete) {
        navigateTo(Routes.main);
        return;
      }
      final route = role == UserRole.coach
          ? Routes.coachOnboardingScreen
          : Routes.playerOnboardingScreen;
      navigateTo(route);
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resent = false;
      _errorMessage = null;
    });
    try {
      await ref.read(authStateProvider.notifier).sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _resent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
    });
    await ref.read(authStateProvider.notifier).refreshUser();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve sent a verification email to ${authState.user?.email ?? 'your email address'}.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkStatus,
                child: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I\'ve verified my email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendVerification,
                child: const Text('Resend verification email'),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _errorMessage != null
                    ? Container(
                        key: ValueKey(_errorMessage),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : _resent
                        ? Container(
                            key: const ValueKey('resent'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Verification email resent.',
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
    );
  }
}
