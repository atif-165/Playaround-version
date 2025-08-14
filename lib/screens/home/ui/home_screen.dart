import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '/helpers/extensions.dart';
import '/routing/routes.dart';
import '/theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../logic/cubit/onboarding_cubit.dart';
import '../../../theming/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check profile completion status immediately when home screen loads
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
              debugPrint('🏠 HomeScreen: OnboardingCubit state changed to: ${state.runtimeType}');
            }

            if (state is OnboardingRoleSelectionRequired) {
              if (kDebugMode) {
                debugPrint('🔄 HomeScreen: Redirecting to role selection screen');
              }
              // User needs to complete onboarding
              context.pushNamedAndRemoveUntil(
                Routes.roleSelectionScreen,
                predicate: (route) => false,
              );
            } else if (state is OnboardingProfileExists) {
              if (kDebugMode) {
                debugPrint('✅ HomeScreen: Profile exists and is complete, staying on home screen');
              }
            }
          },
        ),
      ],
      child: Scaffold(
        body: OfflineBuilder(
          connectivityBuilder: (
            BuildContext context,
            List<ConnectivityResult> connectivity,
            Widget child,
          ) {
            final bool connected = !connectivity.contains(ConnectivityResult.none);
            return connected ? _buildHomeContent(context) : const BuildNoInternet();
          },
          child: const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        // Show loading while checking profile
        if (state is OnboardingInitial ||
            state is OnboardingLoading ||
            state is OnboardingCheckingProfile) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
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
                  'Error checking profile',
                  style: TextStyles.font18DarkBlue600Weight,
                ),
                const SizedBox(height: 16),
                AppTextButton(
                  buttonText: 'Retry',
                  textStyle: TextStyles.font16White600Weight,
                  onPressed: () {
                    context.read<OnboardingCubit>().checkExistingProfile();
                  },
                  backgroundColor: ColorsManager.mainBlue,
                ),
              ],
            ),
          );
        }

        // Show home page content only when profile check is complete
        if (state is OnboardingProfileExists) {
          return _homePage(context);
        }

        // Default loading state
        return const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.mainBlue,
          ),
        );
      },
    );
  }

  SafeArea _homePage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 200.h,
                width: 200.w,
                child: FirebaseAuth.instance.currentUser?.photoURL != null
                    ? CachedNetworkImage(
                        imageUrl: FirebaseAuth.instance.currentUser!.photoURL!,
                        placeholder: (context, url) =>
                            Image.asset('assets/images/loading.gif'),
                        errorWidget: (context, url, error) =>
                            Image.asset('assets/images/placeholder.png'),
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/images/placeholder.png'),
              ),
              Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                style: TextStyles.font15DarkBlue500Weight
                    .copyWith(fontSize: 30.sp),
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
                  return AppTextButton(
                    buttonText: 'Sign Out',
                    textStyle: TextStyles.font15DarkBlue500Weight,
                    onPressed: () {
                      try {
                        GoogleSignIn.instance.signOut();
                      } finally {
                        context.read<AuthCubit>().signOut();
                      }
                    },
                  );
                },
              ),

              // Debug buttons (only show in debug mode)
              if (kDebugMode) ...[
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.roleSelectionScreen);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Go to Role Selection (Test)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10.h),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<OnboardingCubit>().checkExistingProfile();
                  },
                  icon: const Icon(Icons.person_search),
                  label: const Text('Check Profile Status (Debug)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
