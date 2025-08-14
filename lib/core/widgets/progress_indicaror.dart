import 'package:flutter/material.dart';

import '../../theming/colors.dart';

class ProgressIndicaror {
  static showProgressIndicator(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.mainBlue,
          ),
        );
      },
    );
  }
}

/// Custom progress indicator widget
class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: ColorsManager.mainBlue,
    );
  }
}
