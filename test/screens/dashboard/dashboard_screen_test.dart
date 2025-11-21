import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playaround/screens/dashboard/ui/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard screen renders profile hero and sections',
      (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: child,
        ),
        child: const DashboardScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Ayaan Malik'), findsOneWidget);
    expect(find.text('Performance snapshot'), findsOneWidget);
    expect(find.text('About'), findsWidgets); // Tab label + heading
    expect(find.text('Skills'), findsWidgets);
  });
}

