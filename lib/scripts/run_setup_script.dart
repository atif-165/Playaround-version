import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'create_real_users_setup.dart';

/// Main entry point to run the setup script
/// 
/// This script creates:
/// - Player: "wahaj bin rasheed" with fully populated profile
/// - Coach: "Atif javied" with fully populated profile
/// - A tournament both are part of
/// - A team both are members of
/// 
/// To run this script:
/// 1. Make sure Firebase is initialized
/// 2. Run: flutter run lib/scripts/run_setup_script.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('═══════════════════════════════════════════════════════');
  print('🚀 Real Users Setup Script');
  print('═══════════════════════════════════════════════════════\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');

    // Run the setup
    final setup = CreateRealUsersSetup();
    final result = await setup.execute();

    if (result['success'] == true) {
      print('\n✅✅✅ SETUP COMPLETED SUCCESSFULLY ✅✅✅\n');
      print('All users, profiles, tournament, and team have been created!');
    } else {
      print('\n❌❌❌ SETUP FAILED ❌❌❌\n');
      print('Error: ${result['error']}');
    }
  } catch (e, stackTrace) {
    print('\n❌❌❌ FATAL ERROR ❌❌❌\n');
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
  
  // Exit after completion
  exit(0);
}

