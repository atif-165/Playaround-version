import 'package:flutter/material.dart';

import '../../theming/colors.dart';

/// App-wide progress indicator utilities
/// Use AppProgressIndicator.showProgressIndicator(context) to display a blocking loader.
class AppProgressIndicator {
  /// Shows a modal progress indicator dialog that prevents user interaction.
  /// Returns a Future that completes when the dialog is dismissed (Navigator.pop).
  static Future<void> showProgressIndicator(BuildContext context) {
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

/// Backward-compatibility shim for the previously misspelled class name.
/// TODO: Migrate all references to AppProgressIndicator and remove this class.
// ignore: camel_case_types
class ProgressIndicaror {
  static Future<void> showProgressIndicator(BuildContext context) =>
      AppProgressIndicator.showProgressIndicator(context);
}

/// Custom progress indicator widget for inline use in UIs
class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: ColorsManager.mainBlue,
    );
  }
}
