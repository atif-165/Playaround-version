import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

/// Quick script to fix coach role field in Firestore
/// Run with: flutter run lib/scripts/run_fix_coach_role.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('═══════════════════════════════════════════════════════');
  print('🔧 Fixing Coach Role Field');
  print('═══════════════════════════════════════════════════════\n');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');
  } catch (e) {
    print('❌ Firebase initialization error: $e\n');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  const coachEmail = 'atif.javied@playaround.com';
  const coachPassword = 'Atif123!@#';
  const coachUid = 'cwzdbRrfjTaC2H61Pkp5QbAI9u73';

  try {
    // Sign in as coach
    print('🔐 Signing in as coach...');
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: coachEmail,
      password: coachPassword,
    );
    print('✅ Signed in as coach\n');

    // Update coach profile to ensure role field is set
    print('📝 Updating coach profile...');
    await firestore.collection('users').doc(coachUid).update({
      'role': 'coach',
      'isProfileComplete': true,
    });

    print('✅ Coach role field updated successfully!');
    print('   UID: $coachUid');
    print('   Email: $coachEmail');
    print('   Role: coach');
    print('   isProfileComplete: true\n');

    // Verify the update
    print('🔍 Verifying update...');
    final doc = await firestore.collection('users').doc(coachUid).get();
    if (doc.exists) {
      final data = doc.data()!;
      print('📋 Verification:');
      print('   Full Name: ${data['fullName']}');
      print('   Role: ${data['role']}');
      print('   isProfileComplete: ${data['isProfileComplete']}');
    }

    print('\n✅ Fix completed successfully!');
    print('═══════════════════════════════════════════════════════\n');
    print('💡 Coach should now appear in coach listings!\n');
  } catch (e) {
    print('❌ Error: $e');
    print('\n❌❌❌ FIX FAILED ❌❌❌\n');
  } finally {
    await FirebaseAuth.instance.signOut();
  }
  
  // Exit the app
  exit(0);
}

