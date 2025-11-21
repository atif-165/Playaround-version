import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/onboarding_cubit.dart';
import '../../../models/models.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';

/// Screen for selecting user role (Player or Coach)
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),

                      Gap(30.h),

                      // Role options
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRoleOption(
                              role: UserRole.player,
                              title: 'I\'m a Player',
                              subtitle:
                                  'Looking for coaches and training opportunities',
                              icon: Icons.sports_basketball,
                              isSelected: _selectedRole == UserRole.player,
                            ),
                            Gap(20.h),
                            _buildRoleOption(
                              role: UserRole.coach,
                              title: 'I\'m a Coach',
                              subtitle: 'Ready to train and mentor players',
                              icon: Icons.sports,
                              isSelected: _selectedRole == UserRole.coach,
                            ),
                          ],
                        ),
                      ),

                      Gap(30.h),

                      // Continue button
                      _buildContinueButton(),

                      Gap(20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Welcome!',
          style: TextStyles.font24Blue700Weight,
          textAlign: TextAlign.center,
        ),
        Gap(6.h),
        Text(
          'Let\'s get started by selecting your role',
          style: TextStyles.font16Grey400Weight,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.mainBlue.withValues(alpha: 0.1)
              : ColorsManager.lightShadeOfGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? ColorsManager.mainBlue : ColorsManager.gray93Color,
            width: isSelected ? 2.w : 1.3.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorsManager.mainBlue
                    : ColorsManager.gray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(35.w),
              ),
              child: Icon(
                icon,
                size: 35.sp,
                color: isSelected ? Colors.white : ColorsManager.gray,
              ),
            ),

            Gap(12.h),

            // Title
            Text(
              title,
              style: TextStyles.font18DarkBlue600Weight.copyWith(
                color: isSelected
                    ? ColorsManager.mainBlue
                    : ColorsManager.darkBlue,
              ),
              textAlign: TextAlign.center,
            ),

            Gap(8.h),

            // Subtitle
            Text(
              subtitle,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),

            // Selection indicator
            if (isSelected) ...[
              Gap(8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                    Gap(4.w),
                    Text(
                      'Selected',
                      style: TextStyles.font11DarkBlue500Weight.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingComplete) {
          // Navigate directly to main app after saving role
          context.pushNamedAndRemoveUntil(
            Routes.mainNavigation,
            predicate: (route) => false,
          );
        } else if (state is OnboardingError) {
          // Show error if profile save fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AppTextButton(
        buttonText: 'Continue',
        textStyle: TextStyles.font16White600Weight,
        onPressed: _selectedRole != null
            ? () {
                // Save minimal profile with role and navigate to app
                context.read<OnboardingCubit>().saveMinimalProfileWithRole(_selectedRole!);
              }
            : () {}, // Provide empty function instead of null
        backgroundColor: _selectedRole != null
            ? ColorsManager.mainBlue
            : ColorsManager.gray.withValues(alpha: 0.5),
      ),
    );
  }
}
