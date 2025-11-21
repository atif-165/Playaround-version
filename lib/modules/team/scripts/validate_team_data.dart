// ignore_for_file: avoid_print

/// Script to validate and fix corrupted team data in Firestore
///
/// This script checks all team documents for null values in required fields
/// and optionally fixes them by setting default values or removing invalid entries.
///
/// Usage:
/// - Run this script from your main.dart or a dedicated admin screen
/// - Review the output to see which teams have issues
/// - Optionally enable autoFix to automatically correct the issues

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TeamDataValidator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate all teams and return a report
  Future<TeamValidationReport> validateAllTeams({bool autoFix = false}) async {
    final report = TeamValidationReport();

    try {
      final teamsSnapshot = await _firestore.collection('teams').get();

      print('📊 Validating ${teamsSnapshot.docs.length} teams...\n');

      for (final doc in teamsSnapshot.docs) {
        final teamId = doc.id;
        final data = doc.data();

        final issues = _validateTeamDocument(teamId, data);

        if (issues.isNotEmpty) {
          report.teamsWithIssues++;
          report.addIssues(teamId, issues);

          if (autoFix) {
            await _fixTeamDocument(doc.reference, data, issues);
            report.teamsFixed++;
          }
        } else {
          report.teamsValid++;
        }
      }

      print(report.toString());
      return report;
    } catch (e) {
      print('❌ Error validating teams: $e');
      rethrow;
    }
  }

  /// Validate a single team document
  List<String> _validateTeamDocument(String teamId, Map<String, dynamic> data) {
    final issues = <String>[];

    // Check required String fields
    if (data['name'] == null || data['name'].toString().isEmpty) {
      issues.add('❌ Missing or empty "name" field');
    }

    if (data['nameLowercase'] == null) {
      issues.add('⚠️  Missing "nameLowercase" field');
    }

    if (data['createdBy'] == null || data['createdBy'].toString().isEmpty) {
      issues.add('❌ Missing or empty "createdBy" field');
    }

    if (data['sportType'] == null) {
      issues.add('❌ Missing "sportType" field');
    }

    // Check players array
    if (data['players'] is List) {
      final players = data['players'] as List;
      final invalidPlayers = <int>[];

      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        if (player is! Map<String, dynamic>) {
          invalidPlayers.add(i);
          continue;
        }

        if (player['id'] == null || player['id'].toString().isEmpty) {
          invalidPlayers.add(i);
        }

        if (player['name'] == null || player['name'].toString().isEmpty) {
          invalidPlayers.add(i);
        }
      }

      if (invalidPlayers.isNotEmpty) {
        issues.add(
            '❌ ${invalidPlayers.length} players with null/empty id or name (indices: ${invalidPlayers.join(", ")})');
      }
    }

    // Check coaches array
    if (data['coaches'] is List) {
      final coaches = data['coaches'] as List;
      final invalidCoaches = <int>[];

      for (int i = 0; i < coaches.length; i++) {
        final coach = coaches[i];
        if (coach is! Map<String, dynamic>) {
          invalidCoaches.add(i);
          continue;
        }

        if (coach['id'] == null || coach['id'].toString().isEmpty) {
          invalidCoaches.add(i);
        }

        if (coach['name'] == null || coach['name'].toString().isEmpty) {
          invalidCoaches.add(i);
        }
      }

      if (invalidCoaches.isNotEmpty) {
        issues.add(
            '❌ ${invalidCoaches.length} coaches with null/empty id or name (indices: ${invalidCoaches.join(", ")})');
      }
    }

    return issues;
  }

  /// Fix a team document by setting default values or removing invalid entries
  Future<void> _fixTeamDocument(
    DocumentReference docRef,
    Map<String, dynamic> data,
    List<String> issues,
  ) async {
    final updates = <String, dynamic>{};

    // Fix missing required fields
    if (data['name'] == null || data['name'].toString().isEmpty) {
      updates['name'] = 'Unknown Team';
      updates['nameLowercase'] = 'unknown team';
    }

    if (data['nameLowercase'] == null) {
      final name = data['name']?.toString() ?? 'Unknown Team';
      updates['nameLowercase'] = name.toLowerCase();
    }

    if (data['createdBy'] == null || data['createdBy'].toString().isEmpty) {
      updates['createdBy'] = 'unknown';
    }

    if (data['sportType'] == null) {
      updates['sportType'] = 'football';
    }

    if (data['nameInitial'] == null) {
      final name = data['name']?.toString() ?? 'Unknown Team';
      updates['nameInitial'] = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    }

    // Fix players array
    if (data['players'] is List) {
      final players = data['players'] as List;
      final validPlayers = players.where((player) {
        if (player is! Map<String, dynamic>) return false;
        return player['id'] != null &&
            player['id'].toString().isNotEmpty &&
            player['name'] != null &&
            player['name'].toString().isNotEmpty;
      }).toList();

      if (validPlayers.length != players.length) {
        updates['players'] = validPlayers;
      }
    }

    // Fix coaches array
    if (data['coaches'] is List) {
      final coaches = data['coaches'] as List;
      final validCoaches = coaches.where((coach) {
        if (coach is! Map<String, dynamic>) return false;
        return coach['id'] != null &&
            coach['id'].toString().isNotEmpty &&
            coach['name'] != null &&
            coach['name'].toString().isNotEmpty;
      }).toList();

      if (validCoaches.length != coaches.length) {
        updates['coaches'] = validCoaches;
      }
    }

    // Apply updates if any
    if (updates.isNotEmpty) {
      await docRef.update(updates);
      print('✅ Fixed team ${docRef.id}: ${updates.keys.join(", ")}');
    }
  }

  /// Validate team join requests
  Future<int> validateJoinRequests({bool autoFix = false}) async {
    int issuesFound = 0;

    try {
      final requestsSnapshot =
          await _firestore.collection('team_join_requests').get();

      print('📊 Validating ${requestsSnapshot.docs.length} join requests...\n');

      for (final doc in requestsSnapshot.docs) {
        final data = doc.data();
        final issues = <String>[];

        if (data['teamId'] == null || data['teamId'].toString().isEmpty) {
          issues.add('Missing teamId');
        }
        if (data['userId'] == null || data['userId'].toString().isEmpty) {
          issues.add('Missing userId');
        }
        if (data['userName'] == null || data['userName'].toString().isEmpty) {
          issues.add('Missing userName');
        }
        if (data['requestedRole'] == null) {
          issues.add('Missing requestedRole');
        }

        if (issues.isNotEmpty) {
          issuesFound++;
          print('❌ Join Request ${doc.id}: ${issues.join(", ")}');

          if (autoFix) {
            // For join requests with critical issues, it's better to delete them
            // rather than trying to fix with dummy data
            await doc.reference.delete();
            print('🗑️  Deleted invalid join request ${doc.id}');
          }
        }
      }

      print('\n✅ Found $issuesFound invalid join requests');
      return issuesFound;
    } catch (e) {
      print('❌ Error validating join requests: $e');
      rethrow;
    }
  }

  /// Validate team matches
  Future<int> validateTeamMatches({bool autoFix = false}) async {
    int issuesFound = 0;

    try {
      final matchesSnapshot = await _firestore.collection('team_matches').get();

      print('📊 Validating ${matchesSnapshot.docs.length} team matches...\n');

      for (final doc in matchesSnapshot.docs) {
        final data = doc.data();
        final issues = <String>[];

        if (data['homeTeamId'] == null ||
            data['homeTeamId'].toString().isEmpty) {
          issues.add('Missing homeTeamId');
        }
        if (data['awayTeamId'] == null ||
            data['awayTeamId'].toString().isEmpty) {
          issues.add('Missing awayTeamId');
        }

        // Check homeTeam object
        if (data['homeTeam'] is Map) {
          final homeTeam = data['homeTeam'] as Map<String, dynamic>;
          if (homeTeam['teamId'] == null || homeTeam['teamName'] == null) {
            issues.add('homeTeam missing teamId or teamName');
          }
        } else {
          issues.add('Missing or invalid homeTeam object');
        }

        // Check awayTeam object
        if (data['awayTeam'] is Map) {
          final awayTeam = data['awayTeam'] as Map<String, dynamic>;
          if (awayTeam['teamId'] == null || awayTeam['teamName'] == null) {
            issues.add('awayTeam missing teamId or teamName');
          }
        } else {
          issues.add('Missing or invalid awayTeam object');
        }

        if (issues.isNotEmpty) {
          issuesFound++;
          print('❌ Team Match ${doc.id}: ${issues.join(", ")}');

          if (autoFix) {
            // Matches with critical issues should probably be reviewed manually
            // For now, just log them
            print('⚠️  Manual review recommended for match ${doc.id}');
          }
        }
      }

      print('\n✅ Found $issuesFound invalid team matches');
      return issuesFound;
    } catch (e) {
      print('❌ Error validating team matches: $e');
      rethrow;
    }
  }

  /// Run full validation on all team-related collections
  Future<void> runFullValidation({bool autoFix = false}) async {
    print('🔍 Starting full team data validation...\n');
    print('Auto-fix: ${autoFix ? "ENABLED" : "DISABLED"}\n');
    print('=' * 60);
    print('\n');

    // Validate teams
    print('📋 VALIDATING TEAMS\n');
    await validateAllTeams(autoFix: autoFix);
    print('\n' + '=' * 60 + '\n');

    // Validate join requests
    print('📋 VALIDATING JOIN REQUESTS\n');
    await validateJoinRequests(autoFix: autoFix);
    print('\n' + '=' * 60 + '\n');

    // Validate matches
    print('📋 VALIDATING TEAM MATCHES\n');
    await validateTeamMatches(autoFix: autoFix);
    print('\n' + '=' * 60 + '\n');

    print('✅ Validation complete!\n');
  }
}

/// Report class for team validation results
class TeamValidationReport {
  int teamsValid = 0;
  int teamsWithIssues = 0;
  int teamsFixed = 0;
  final Map<String, List<String>> issues = {};

  void addIssues(String teamId, List<String> teamIssues) {
    issues[teamId] = teamIssues;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('\n📊 VALIDATION REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('✅ Valid teams: $teamsValid');
    buffer.writeln('❌ Teams with issues: $teamsWithIssues');
    if (teamsFixed > 0) {
      buffer.writeln('🔧 Teams fixed: $teamsFixed');
    }
    buffer.writeln('');

    if (issues.isNotEmpty) {
      buffer.writeln('DETAILED ISSUES:\n');
      issues.forEach((teamId, teamIssues) {
        buffer.writeln('Team: $teamId');
        for (final issue in teamIssues) {
          buffer.writeln('  $issue');
        }
        buffer.writeln('');
      });
    }

    buffer.writeln('=' * 60);
    return buffer.toString();
  }
}

/// Example usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   final validator = TeamDataValidator();
///
///   // Dry run (just check, don't fix)
///   await validator.runFullValidation(autoFix: false);
///
///   // Uncomment to actually fix the issues
///   // await validator.runFullValidation(autoFix: true);
/// }
/// ```
