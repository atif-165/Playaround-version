import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Quick script to fix coach role field in Firestore
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('═══════════════════════════════════════════════════════');
  print('🔧 Fixing Coach Role Field');
  print('═══════════════════════════════════════════════════════\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  const coachEmail = 'atif.javied@playaround.com';
  const coachPassword = 'Atif123!@#';
  const coachUid = 'cwzdbRrfjTaC2H61Pkp5QbAI9u73';

  try {
    // Sign in as coach
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: coachEmail,
      password: coachPassword,
    );

    print('✅ Signed in as coach\n');

    // Update coach profile to ensure role field is set
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
  } catch (e) {
    print('❌ Error: $e');
    print('\n❌❌❌ FIX FAILED ❌❌❌\n');
  } finally {
    await FirebaseAuth.instance.signOut();
  }
}

