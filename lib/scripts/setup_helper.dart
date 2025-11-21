import 'create_real_users_setup.dart';

/// Helper class to easily trigger the setup from anywhere in the app
/// 
/// Usage example:
/// ```dart
/// final helper = SetupHelper();
/// final result = await helper.runSetup();
/// if (result['success']) {
///   print('Setup completed!');
///   print('Player email: ${result['credentials']['player']['email']}');
///   print('Coach email: ${result['credentials']['coach']['email']}');
/// }
/// ```
class SetupHelper {
  /// Run the complete setup process
  /// 
  /// Returns a map with:
  /// - success: bool
  /// - playerUid: String
  /// - coachUid: String
  /// - tournamentId: String
  /// - teamId: String
  /// - credentials: Map with player and coach email/password
  /// - error: String (if success is false)
  Future<Map<String, dynamic>> runSetup() async {
    final setup = CreateRealUsersSetup();
    return await setup.execute();
  }

  /// Get the credentials after setup
  /// 
  /// Returns a formatted string with all credentials
  String formatCredentials(Map<String, dynamic> result) {
    if (result['success'] != true) {
      return 'Setup failed: ${result['error']}';
    }

    final creds = result['credentials'] as Map<String, dynamic>;
    final player = creds['player'] as Map<String, dynamic>;
    final coach = creds['coach'] as Map<String, dynamic>;

    return '''
═══════════════════════════════════════════════════════
📧 USER CREDENTIALS
═══════════════════════════════════════════════════════
👤 PLAYER:
   Name: ${player['name']}
   Email: ${player['email']}
   Password: ${player['password']}

👨‍🏫 COACH:
   Name: ${coach['name']}
   Email: ${coach['email']}
   Password: ${coach['password']}
═══════════════════════════════════════════════════════
''';
  }
}

