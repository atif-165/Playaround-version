import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../helpers/extensions.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResendEnabled = true;
  int _resendCountdown = 0;

  void _startResendCountdown() {
    setState(() {
      _isResendEnabled = false;
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _isResendEnabled = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Email',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pushNamedAndRemoveUntil(
            Routes.loginScreen,
            predicate: (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state is AuthLoading) {
                AppProgressIndicator.showProgressIndicator(context);
              } else if (state is AuthError) {
                context.pop();
                await AwesomeDialog(
                  context: context,
                  dialogType: DialogType.error,
                  animType: AnimType.rightSlide,
                  title: 'Error',
                  desc: state.message,
                ).show();
              } else if (state is EmailVerificationResent) {
                context.pop();
                _startResendCountdown();
                await AwesomeDialog(
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.rightSlide,
                  title: 'Email Sent',
                  desc:
                      'Verification email has been sent. Please check your inbox and spam folder.',
                ).show();
              } else if (state is AuthenticatedWithProfile) {
                context.pop();
                await AwesomeDialog(
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.rightSlide,
                  title: 'Email Verified',
                  desc: 'Your email has been successfully verified!',
                ).show();
                if (!context.mounted) return;
                context.pushNamedAndRemoveUntil(
                  Routes.dashboardScreen,
                  predicate: (route) => false,
                );
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 100.w,
                    color: ColorsManager.mainBlue,
                  ),
                  Gap(32.h),
                  Text(
                    'Check Your Email',
                    style: TextStyles.font24Blue700Weight,
                    textAlign: TextAlign.center,
                  ),
                  Gap(16.h),
                  Text(
                    'We\'ve sent a verification link to your email address. Please click the link to verify your account.',
                    style: TextStyles.font14Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                  Gap(32.h),
                  AppTextButton(
                    buttonText: 'Check Verification Status',
                    textStyle: TextStyles.font16White600Weight,
                    onPressed: () {
                      context.read<AuthCubit>().checkEmailVerification();
                    },
                  ),
                  // Development bypass for test accounts (only in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product', defaultValue: false) == false)
                    Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: TextButton(
                        onPressed: () {
                          context.read<AuthCubit>().skipEmailVerificationForTesting();
                        },
                        child: Text(
                          'Skip Verification (Test Only)',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.8),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  Gap(16.h),
                  AppTextButton(
                    buttonText: _isResendEnabled
                        ? 'Resend Verification Email'
                        : 'Resend in ${_resendCountdown}s',
                    textStyle: _isResendEnabled
                        ? TextStyles.font16Blue600Weight
                        : TextStyles.font16Grey400Weight,
                    backgroundColor: Colors.transparent,
                    onPressed: _isResendEnabled
                        ? () {
                            context.read<AuthCubit>().resendEmailVerification();
                          }
                        : () {}, // Empty function instead of null
                  ),
                  Gap(32.h),
                  Text(
                    'Didn\'t receive the email?',
                    style: TextStyles.font14Grey400Weight,
                  ),
                  Gap(8.h),
                  Text(
                    '• Check your spam/junk folder\n• Make sure the email address is correct\n• Try resending the verification email',
                    style: TextStyles.font12Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                  Gap(32.h),
                  TextButton(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                      context.pushNamedAndRemoveUntil(
                        Routes.loginScreen,
                        predicate: (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyles.font14Blue400Weight,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
