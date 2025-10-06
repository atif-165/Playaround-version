// Script to update all white backgrounds to black and text to white
import 'dart:io';

void main() {
  final files = [
    'lib/modules/listing/screens/add_listing_screen.dart',
    'lib/modules/skill_tracking/screens/add_goal_screen.dart',
    'lib/modules/skill_tracking/screens/analytics_dashboard_screen.dart',
    'lib/modules/skill_tracking/screens/coach_logging_screen.dart',
    'lib/modules/skill_tracking/screens/skill_dashboard_screen.dart',
    'lib/modules/team/screens/team_admin_screen.dart',
    'lib/modules/team/screens/team_creation_screen.dart',
    'lib/modules/team/screens/team_management_screen.dart',
    'lib/modules/team/screens/team_performance_screen.dart',
    'lib/modules/team/screens/team_schedule_screen.dart',
    'lib/modules/tournament/screens/create_tournament_screen.dart',
    'lib/modules/tournament/screens/tournament_management_screen.dart',
    'lib/modules/tournament/screens/tournament_preview_screen.dart',
    'lib/modules/venue/screens/add_venue_screen.dart',
    'lib/modules/venue/screens/edit_venue_screen.dart',
    'lib/modules/venue/screens/my_venue_bookings_screen.dart',
    'lib/modules/venue/screens/owner_bookings_screen.dart',
    'lib/modules/venue/screens/venue_booking_detail_screen.dart',
    'lib/modules/venue/screens/venue_reschedule_screen.dart',
    'lib/screens/explore/explore_screen.dart',
    'lib/screens/match_requests/match_requests_screen.dart',
    'lib/screens/notifications/notifications_screen.dart',
    'lib/screens/onboarding/ui/coach_onboarding_screen.dart',
    'lib/screens/onboarding/ui/player_onboarding_screen.dart',
    'lib/screens/profile/profile_screen.dart',
  ];

  for (final file in files) {
    updateFile(file);
  }
}

void updateFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return;
  
  String content = file.readAsStringSync();
  
  // Update white backgrounds to black
  content = content.replaceAll('backgroundColor: Colors.white', 'backgroundColor: Colors.black');
  content = content.replaceAll('color: Colors.white,', 'color: Colors.black,');
  content = content.replaceAll('Colors.white.withValues(alpha:', 'Colors.black.withValues(alpha:');
  content = content.replaceAll('Colors.white.withOpacity(', 'Colors.black.withOpacity(');
  
  // Update text colors to white where needed
  content = content.replaceAll('color: Colors.grey[800]', 'color: Colors.white');
  content = content.replaceAll('color: Colors.grey[700]', 'color: Colors.white');
  content = content.replaceAll('color: Colors.grey[600]', 'color: Colors.white');
  
  file.writeAsStringSync(content);
  print('Updated: $filePath');
}