import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'firebase_options.dart';
import 'logic/cubit/auth_cubit.dart';
import 'logic/cubit/onboarding_cubit.dart';
import 'repositories/user_repository.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';
import 'theming/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper error handling
  try {
    // Try to initialize Firebase, but handle the case where it's already initialized
    // by the Google Services plugin (common in Android)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('Firebase initialized successfully');
    }

    // Configure Firebase Auth settings for better reCAPTCHA handling
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: false,
    );

  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      if (kDebugMode) {
        debugPrint('Firebase already initialized by Google Services plugin');
      }
    } else {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
      // Re-throw critical initialization errors
      rethrow;
    }
  }

  await Future.wait([
    ScreenUtil.ensureScreenSize(),
    preloadSVGs(['assets/svgs/google_logo.svg']),
  ]);

  runApp(const MyApp());
}

Future<void> preloadSVGs(List<String> paths) async {
  for (final path in paths) {
    final loader = SvgAssetLoader(path);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => OnboardingCubit(
          userRepository: UserRepository(),
        )),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            title: 'PlayAround - Sports Social App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            initialRoute: _getInitialRoute(),
          );
        },
      ),
    );
  }

  String _getInitialRoute() {
    final user = FirebaseAuth.instance.currentUser;

    // If no user or email not verified, go to login
    if (user == null || !user.emailVerified) {
      return Routes.loginScreen;
    }

    // If user is authenticated and verified, we need to check if profile exists
    // This will be handled by the dashboard screen that checks profile and shows role-specific dashboard
    return Routes.dashboardScreen;
  }
}