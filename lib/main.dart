import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'firebase_options.dart';
import 'logic/cubit/auth_cubit.dart';
import 'logic/cubit/onboarding_cubit.dart';
import 'logic/cubit/dashboard_cubit.dart';
import 'modules/team/cubit/team_cubit.dart';
import 'modules/tournament/cubit/tournament_cubit.dart';
import 'repositories/user_repository.dart';
import 'modules/team/services/team_service.dart';
import 'modules/tournament/services/tournament_service.dart';
import 'routing/app_router.dart';
import 'theming/app_theme.dart';
import 'data/local/sync_manager.dart';
import 'core/i18n/localizations.dart';
import 'services/mock_push_generator.dart';
import 'services/local_notification_service.dart';
import 'services/firestore_cache_service.dart';

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

    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);

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
    SyncManager.instance.init(),
    FirestoreCacheService.instance.init(),
    AppLocalizations.load(),
    LocalNotificationService().initialize(),
  ]);

  if (kDebugMode) {
    MockPushGenerator().start();
  }

  runApp(const ProviderScope(child: MyApp()));
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
        BlocProvider(
            create: (context) => OnboardingCubit(
                  userRepository: UserRepository(),
                )),
        BlocProvider(create: (context) => DashboardCubit()),
        BlocProvider(create: (context) => TeamCubit(TeamService())),
        BlocProvider(create: (context) => TournamentCubit(TournamentService())),
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
            initialRoute: AppRouter.initialRoute,
          );
        },
      ),
    );
  }
}
