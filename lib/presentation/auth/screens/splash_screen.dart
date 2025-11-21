import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../../../routing/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), _handleNavigation);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleNavigation() {
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    final onboardingState = ref.read(onboardingProvider);

    final onboardingComplete =
        authState.isOnboardingComplete || onboardingState.isComplete;

    String nextRoute;
    switch (authState.status) {
      case AuthStatus.unauthenticated:
        nextRoute = Routes.authLogin;
        break;
      case AuthStatus.emailUnverified:
        nextRoute = Routes.emailVerificationScreen;
        break;
      case AuthStatus.authenticatedCoach:
      case AuthStatus.authenticatedPlayer:
        if (authState.role == null) {
          nextRoute = Routes.roleSelectionScreen;
        } else if (!onboardingComplete) {
          nextRoute = authState.role == UserRole.coach
              ? Routes.coachOnboardingScreen
              : Routes.playerOnboardingScreen;
        } else {
          nextRoute = Routes.main;
        }
        break;
    }

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'PlayAround',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
