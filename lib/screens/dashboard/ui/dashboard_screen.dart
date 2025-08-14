import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '/helpers/extensions.dart';
import '/routing/routes.dart';
import '/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../core/widgets/notification_icon.dart';
import '../../../modules/chat/widgets/chat_icon.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../logic/cubit/onboarding_cubit.dart';
import '../../../theming/colors.dart';

import '../../../modules/rating/services/rating_prompt_manager.dart';

import '../../../logic/cubit/dashboard_cubit.dart';

import 'sports_dashboard_screen.dart';

/// Main dashboard screen that displays role-specific dashboards
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Check profile completion status immediately when dashboard screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingCubit>().checkExistingProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (kDebugMode) {
              debugPrint('🏠 DashboardScreen: OnboardingCubit state changed to: ${state.runtimeType}');
            }

            if (state is OnboardingRoleSelectionRequired) {
              if (kDebugMode) {
                debugPrint('🔄 DashboardScreen: Redirecting to role selection screen');
              }
              // User needs to complete onboarding
              context.pushNamedAndRemoveUntil(
                Routes.roleSelectionScreen,
                predicate: (route) => false,
              );
            } else if (state is OnboardingProfileExists) {
              if (kDebugMode) {
                debugPrint('✅ DashboardScreen: Profile exists and is complete, staying on dashboard screen');
              }
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(),
        body: OfflineBuilder(
          connectivityBuilder: (
            BuildContext context,
            List<ConnectivityResult> connectivity,
            Widget child,
          ) {
            final bool connected = !connectivity.contains(ConnectivityResult.none);
            return connected ? _buildDashboardContent(context) : const BuildNoInternet();
          },
          child: const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.primary,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard'),
      backgroundColor: ColorsManager.surface,
      foregroundColor: ColorsManager.onSurface,
      elevation: 0,
      actions: [
        ChatIcon(),
        NotificationIcon(),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            // Navigate to profile screen
            context.pushNamed(Routes.profileScreen);
          },
        ),
        BlocConsumer<AuthCubit, AuthState>(
          buildWhen: (previous, current) => previous != current,
          listenWhen: (previous, current) => previous != current,
          listener: (context, state) async {
            if (state is AuthLoading) {
              AppProgressIndicator.showProgressIndicator(context);
            } else if (state is UserSignedOut) {
              context.pop();
              context.pushNamedAndRemoveUntil(
                Routes.loginScreen,
                predicate: (route) => false,
              );
            } else if (state is AuthError) {
              await AwesomeDialog(
                context: context,
                dialogType: DialogType.info,
                animType: AnimType.rightSlide,
                title: 'Sign out error',
                desc: state.message,
              ).show();
            }
          },
          builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _showSignOutDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        // Show loading while checking profile
        if (state is OnboardingInitial ||
            state is OnboardingLoading ||
            state is OnboardingCheckingProfile) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.primary,
            ),
          );
        }

        // Show error if profile check failed
        if (state is OnboardingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading dashboard',
                  style: TextStyles.font18DarkBlue600Weight,
                ),
                const SizedBox(height: 16),
                AppTextButton(
                  buttonText: 'Retry',
                  textStyle: TextStyles.font16White600Weight,
                  onPressed: () {
                    context.read<OnboardingCubit>().checkExistingProfile();
                  },
                  backgroundColor: ColorsManager.primary,
                ),
              ],
            ),
          );
        }

        // Show role-specific dashboard when profile check is complete
        if (state is OnboardingProfileExists) {
          return AutoRatingPromptChecker(
            child: BlocProvider(
              create: (context) => DashboardCubit(),
              child: SportsDashboardScreen(
                userProfile: state.existingProfile,
              ),
            ),
          );
        }

        // Default loading state
        return const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.primary,
          ),
        );
      },
    );
  }







  void _showSignOutDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Sign Out',
      desc: 'Are you sure you want to sign out?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        try {
          GoogleSignIn.instance.signOut();
        } finally {
          context.read<AuthCubit>().signOut();
        }
      },
    ).show();
  }
}
