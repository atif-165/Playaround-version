import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class PasswordValidations extends StatelessWidget {
  final String password;
  const PasswordValidations({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildValidationRow('At least 8 characters', password.length >= 8),
        Gap(2.h),
        buildValidationRow('One uppercase letter', RegExp(r'(?=.*[A-Z])').hasMatch(password)),
        Gap(2.h),
        buildValidationRow('One lowercase letter', RegExp(r'(?=.*[a-z])').hasMatch(password)),
        Gap(2.h),
        buildValidationRow('One digit', RegExp(r'(?=.*\d)').hasMatch(password)),
        Gap(2.h),
        buildValidationRow('One special character (@\$!%*?&)', RegExp(r'(?=.*[@$!%*?&])').hasMatch(password)),
      ],
    );
  }

  Widget buildValidationRow(String text, bool hasValidated) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 2.5,
          backgroundColor: ColorsManager.gray,
        ),
        Gap(6.w),
        Text(
          text,
          style: TextStyles.font14DarkBlue500Weight.copyWith(
            decoration: hasValidated ? TextDecoration.lineThrough : null,
            decorationColor: Colors.green,
            decorationThickness: 2,
            color: hasValidated ? ColorsManager.gray : ColorsManager.darkBlue,
          ),
        )
      ],
    );
  }
}
