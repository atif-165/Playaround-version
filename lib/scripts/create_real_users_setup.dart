import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/player_profile.dart';
import '../models/coach_profile.dart';
import '../repositories/user_repository.dart';
import '../modules/tournament/services/tournament_service.dart';
import '../modules/tournament/models/tournament_model.dart';
import '../modules/tournament/models/tournament_match_model.dart';
import '../modules/tournament/models/player_match_stats.dart';
import '../modules/tournament/services/tournament_match_service.dart';
import '../modules/team/services/team_service.dart';
import '../modules/team/models/team_model.dart';
import '../modules/tournament/services/tournament_team_service.dart';
import '../modules/skill_tracking/services/automated_skill_service.dart';

/// Script to create real users with fully populated profiles, tournament, and team
/// 
/// Creates:
/// - Player: "wahaj bin rasheed" with fully populated profile
/// - Coach: "Atif javied" with fully populated profile
/// - A tournament both are part of
/// - A team both are members of
class CreateRealUsersSetup {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();
  final TournamentService _tournamentService = TournamentService();
  final TeamService _teamService = TeamService();
  final TournamentTeamService _tournamentTeamService = TournamentTeamService();
  final TournamentMatchService _matchService = TournamentMatchService();
  final AutomatedSkillService _skillService = AutomatedSkillService();

  // User credentials
  static const String playerEmail = 'wahaj.bin.rasheed@playaround.com';
  static const String playerPassword = 'Wahaj123!@#';
  static const String playerName = 'wahaj bin rasheed';
  
  static const String coachEmail = 'atif.javied@playaround.com';
  static const String coachPassword = 'Atif123!@#';
  static const String coachName = 'Atif javied';

  /// Main execution method
  Future<Map<String, dynamic>> execute() async {
    print('🚀 Starting real users setup...\n');

    try {
      // Step 1: Create Firebase authentication accounts
      print('📝 Step 1: Creating Firebase authentication accounts...');
      final playerUser = await _createAuthAccount(playerEmail, playerPassword, playerName);
      final coachUser = await _createAuthAccount(coachEmail, coachPassword, coachName);
      print('✅ Authentication accounts created\n');

      // Step 2: Create fully populated profiles
      print('📝 Step 2: Creating fully populated profiles...');
      await _createPlayerProfile(playerUser.uid, playerEmail, playerPassword);
      await _createCoachProfile(coachUser.uid, coachEmail, coachPassword);
      print('✅ Profiles created\n');

      // Step 3: Create tournament
      print('📝 Step 3: Creating tournament...');
      final tournamentId = await _createTournament(coachUser.uid, coachName);
      print('✅ Tournament created: $tournamentId\n');

      // Step 4: Create team with both users
      print('📝 Step 4: Creating team with both users...');
      final teamId = await _createTeam(
        playerUser.uid,
        playerName,
        coachUser.uid,
        coachName,
        tournamentId,
      );
      print('✅ Team created: $teamId\n');

      // Step 5: Register team in tournament
      print('📝 Step 5: Registering team in tournament...');
      await _registerTeamInTournament(tournamentId, teamId, playerUser.uid);
      print('✅ Team registered in tournament\n');

      // Step 6: Update user profiles with teamId (must be authenticated as each user)
      print('📝 Step 6: Updating user profiles with teamId...');
      await _updateUserProfileWithTeamId(playerUser.uid, teamId, playerEmail, playerPassword);
      await _updateUserProfileWithTeamId(coachUser.uid, teamId, coachEmail, coachPassword);
      print('✅ User profiles updated\n');

      // Step 7: Add more team members (around 20 total)
      print('📝 Step 7: Adding team members...');
      await _addTeamMembers(teamId, playerUser.uid, playerEmail, playerPassword);
      print('✅ Team members added\n');

      // Step 8: Create tournament matches with player stats for Wahaj
      print('📝 Step 8: Creating tournament matches with player stats...');
      await _createTournamentMatchesWithStats(tournamentId, teamId, playerUser.uid, coachUser.uid, playerEmail, playerPassword);
      print('✅ Tournament matches created with stats\n');

      // Step 9: Update Wahaj's skills based on tournament performance
      print('📝 Step 9: Updating Wahaj\'s skills based on tournament performance...');
      await _updatePlayerSkillsFromTournament(tournamentId, playerUser.uid);
      print('✅ Skills updated\n');

      print('🎉 Setup completed successfully!\n');
      print('═══════════════════════════════════════════════════════');
      print('📧 USER CREDENTIALS:');
      print('═══════════════════════════════════════════════════════');
      print('👤 PLAYER:');
      print('   Name: $playerName');
      print('   Email: $playerEmail');
      print('   Password: $playerPassword');
      print('');
      print('👨‍🏫 COACH:');
      print('   Name: $coachName');
      print('   Email: $coachEmail');
      print('   Password: $coachPassword');
      print('═══════════════════════════════════════════════════════\n');

      return {
        'success': true,
        'playerUid': playerUser.uid,
        'coachUid': coachUser.uid,
        'tournamentId': tournamentId,
        'teamId': teamId,
        'credentials': {
          'player': {
            'email': playerEmail,
            'password': playerPassword,
            'name': playerName,
          },
          'coach': {
            'email': coachEmail,
            'password': coachPassword,
            'name': coachName,
          },
        },
      };
    } catch (e, stackTrace) {
      print('❌ Error during setup: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create Firebase authentication account
  Future<User> _createAuthAccount(String email, String password, String displayName) async {
    try {
      // Check if user already exists
      try {
        final existingUser = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _auth.signOut();
        print('   ℹ️  User already exists: $email');
        return existingUser.user!;
      } catch (_) {
        // User doesn't exist, create new one
      }

      // Create new user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(displayName);
      await user.reload();

      // Verify email (for testing purposes, we'll mark as verified)
      // Note: In production, users should verify their own emails
      print('   ✅ Created auth account: $email');
      return user;
    } catch (e) {
      // If user exists, try to sign in
      if (e.toString().contains('already-in-use')) {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCredential.user!;
      }
      rethrow;
    }
  }

  /// Create fully populated player profile
  Future<void> _createPlayerProfile(String uid, String email, String password) async {
    // Sign in as player to create/update profile (required for authentication)
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      // Check if profile already exists and is complete
      final existingProfile = await _userRepository.getUserProfile(uid);
      if (existingProfile != null && existingProfile.isProfileComplete && existingProfile.teamId != null) {
        print('   ℹ️  Player profile already exists and is complete: $playerName');
        // Update public profile even for existing profiles
        await _createPublicProfile(uid, existingProfile);
        return;
      }
      final now = DateTime.now();
      
      final playerProfile = PlayerProfile(
      uid: uid,
      fullName: playerName,
      nickname: 'Wahaj',
      bio: 'Passionate football player with 5+ years of experience. Love playing as a forward and scoring goals. Always looking to improve my skills and contribute to team success.',
      gender: Gender.male,
      age: 25,
      location: 'Lahore, Pakistan',
      latitude: 31.5204,
      longitude: 74.3587,
      profilePictureUrl: null, // Can be added later
      profilePhotos: [],
      isProfileComplete: true,
      teamId: null, // Will be updated after team creation
      createdAt: now,
      updatedAt: now,
      sportsOfInterest: ['Football', 'Cricket', 'Basketball'],
      skillLevel: SkillLevel.intermediate,
      availability: [
        TimeSlot(day: 'Monday', startTime: '18:00', endTime: '20:00'),
        TimeSlot(day: 'Wednesday', startTime: '18:00', endTime: '20:00'),
        TimeSlot(day: 'Friday', startTime: '17:00', endTime: '19:00'),
        TimeSlot(day: 'Saturday', startTime: '10:00', endTime: '12:00'),
        TimeSlot(day: 'Sunday', startTime: '10:00', endTime: '12:00'),
      ],
      preferredTrainingType: TrainingType.both,
      );

      await _userRepository.saveUserProfile(playerProfile);
      
      // Create/update public_profiles document
      await _createPublicProfile(uid, playerProfile);
      
      print('   ✅ Player profile created for $playerName');
    } finally {
      // Sign out after profile creation
      await _auth.signOut();
    }
  }

  /// Create fully populated coach profile
  Future<void> _createCoachProfile(String uid, String email, String password) async {
    // Sign in as coach to create/update profile (required for authentication)
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      // Check if profile already exists and is complete
      final existingProfile = await _userRepository.getUserProfile(uid);
      if (existingProfile != null && existingProfile.isProfileComplete && existingProfile.teamId != null) {
        print('   ℹ️  Coach profile already exists and is complete: $coachName');
        // Ensure role field is set even for existing profiles
        await _firestore.collection('users').doc(uid).update({
          'role': 'coach',
          'isProfileComplete': true,
        });
        // Update public profile even for existing profiles
        await _createPublicProfile(uid, existingProfile);
        print('   ✅ Coach role field and public profile updated');
        return;
      }
      final now = DateTime.now();
      
      final coachProfile = CoachProfile(
      uid: uid,
      fullName: coachName,
      nickname: 'Coach Atif',
      gender: Gender.male,
      age: 35,
      location: 'Lahore, Pakistan',
      latitude: 31.5204,
      longitude: 74.3587,
      profilePictureUrl: null, // Can be added later
      profilePhotos: [],
      isProfileComplete: true,
      teamId: null, // Will be updated after team creation
      createdAt: now,
      updatedAt: now,
      specializationSports: ['Football', 'Cricket', 'Basketball'],
      experienceYears: 12,
      certifications: [
        'FIFA Licensed Coach',
        'Advanced Football Tactics Certificate',
        'Sports Psychology Diploma',
        'Youth Development Specialist',
      ],
      hourlyRate: 2500.0,
      availableTimeSlots: [
        TimeSlot(day: 'Monday', startTime: '16:00', endTime: '20:00'),
        TimeSlot(day: 'Tuesday', startTime: '16:00', endTime: '20:00'),
        TimeSlot(day: 'Wednesday', startTime: '16:00', endTime: '20:00'),
        TimeSlot(day: 'Thursday', startTime: '16:00', endTime: '20:00'),
        TimeSlot(day: 'Friday', startTime: '15:00', endTime: '19:00'),
        TimeSlot(day: 'Saturday', startTime: '09:00', endTime: '13:00'),
        TimeSlot(day: 'Sunday', startTime: '09:00', endTime: '13:00'),
      ],
      coachingType: TrainingType.both,
      bio: 'Experienced football coach with over 12 years of professional coaching experience. Specialized in youth development, tactical analysis, and team management. Former professional player with extensive knowledge of modern football strategies. Committed to developing players both on and off the field.',
      );

      await _userRepository.saveUserProfile(coachProfile);
      
      // Ensure role field is explicitly set in Firestore
      await _firestore.collection('users').doc(uid).update({
        'role': 'coach',
        'isProfileComplete': true,
      });
      
      // Create/update public_profiles document
      await _createPublicProfile(uid, coachProfile);
      
      print('   ✅ Coach profile created for $coachName');
    } finally {
      // Sign out after profile creation
      await _auth.signOut();
    }
  }

  /// Create or get existing tournament
  Future<String> _createTournament(String organizerId, String organizerName) async {
    // Sign in as coach to create/get tournament (required for authentication)
    await _auth.signInWithEmailAndPassword(
      email: coachEmail,
      password: coachPassword,
    );

    try {
      // Check if tournament already exists
      const tournamentName = 'Lahore Premier Football Championship 2024';
      final query = await _firestore
          .collection('tournaments')
          .where('name', isEqualTo: tournamentName)
          .where('sportType', isEqualTo: SportType.football.name)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final tournamentId = query.docs.first.id;
        print('   ℹ️  Tournament already exists: $tournamentName (ID: $tournamentId)');
        return tournamentId;
      }

      // Create new tournament if it doesn't exist
      final now = DateTime.now();
      
      final tournamentId = await _tournamentService.createTournament(
      name: 'Lahore Premier Football Championship 2024',
      description: 'Elite football tournament featuring the best teams from Lahore. Experience thrilling matches with top-class football action! This tournament brings together skilled players and experienced coaches to compete for the championship title.',
      sportType: SportType.football,
      format: TournamentFormat.league,
      registrationStartDate: now.subtract(const Duration(days: 7)),
      registrationEndDate: now.add(const Duration(days: 7)),
      startDate: now.add(const Duration(days: 14)),
      endDate: now.add(const Duration(days: 60)),
      maxTeams: 16,
      minTeams: 8,
      location: 'Lahore Sports Complex, Lahore, Pakistan',
      imageUrl: null,
      rules: [
        'Each team must have minimum 11 players and maximum 20 players',
        'Standard FIFA rules apply',
        'Match duration: 90 minutes (2 × 45 minutes)',
        'Substitutions: Maximum 5 substitutions per match',
        'Yellow card: Warning, Red card: Ejection',
        'Fair play and sportsmanship are mandatory',
        'Teams must arrive 30 minutes before scheduled match time',
        'Proper football gear and cleats required',
      ],
      prizes: {
        'first': 'PKR 500,000 + Trophy',
        'second': 'PKR 250,000 + Trophy',
        'third': 'PKR 100,000 + Trophy',
        'bestPlayer': 'PKR 25,000',
        'topScorer': 'PKR 25,000',
        'bestGoalkeeper': 'PKR 25,000',
      },
      isPublic: true,
      entryFee: 15000.0,
      winningPrize: 500000.0,
      qualifyingQuestions: [
        'What is your team\'s average age?',
        'How many years of experience does your team have?',
        'What is your team\'s preferred playing style?',
      ],
      );

      print('   ✅ Tournament created: Lahore Premier Football Championship 2024');
      return tournamentId;
    } finally {
      // Sign out after tournament creation
      await _auth.signOut();
    }
  }

  /// Create team with both users
  Future<String> _createTeam(
    String playerId,
    String playerName,
    String coachId,
    String coachName,
    String tournamentId,
  ) async {
    // Sign in as player to create team (since team owner must be authenticated)
    final playerUser = await _auth.signInWithEmailAndPassword(
      email: playerEmail,
      password: playerPassword,
    );

    try {
      // Check if team already exists
      const teamName = 'Lahore United FC';
      final teamQuery = await _firestore
          .collection('teams')
          .where('name', isEqualTo: teamName)
          .where('sportType', isEqualTo: SportType.football.name)
          .limit(1)
          .get();

      if (teamQuery.docs.isNotEmpty) {
        final teamId = teamQuery.docs.first.id;
        print('   ℹ️  Team already exists: $teamName (ID: $teamId)');
        
        // Verify both users are members
        final teamData = teamQuery.docs.first.data();
        final members = (teamData['members'] as List<dynamic>?) ?? [];
        final playerInTeam = members.any((m) => m['userId'] == playerId);
        final coachInTeam = members.any((m) => m['userId'] == coachId);
        
        if (playerInTeam && coachInTeam) {
          print('   ✅ Both users are already members of the team');
          return teamId;
        } else {
          print('   ⚠️  Team exists but not all members are present, continuing with creation...');
        }
      }

      // Get profiles for proper member details
      final playerProfile = await _userRepository.getUserProfile(playerId);
      final coachProfile = await _userRepository.getUserProfile(coachId);

      final teamId = await _teamService.createTeam(
        name: 'Lahore United FC',
        description: 'Elite football team from Lahore competing in the Premier Football Championship. We focus on teamwork, discipline, and excellence both on and off the field.',
        bio: 'Founded in 2023, Lahore United FC has quickly become one of the most competitive teams in the region. Under the expert guidance of Coach Atif Javied, we focus on developing skilled athletes while promoting sportsmanship and community engagement. Our mission is to win championships while building character and fostering a love for the beautiful game.',
        sportType: SportType.football,
        maxMembers: 20,
        isPublic: true,
        location: 'Lahore, Pakistan',
        coachId: coachId,
        coachName: coachName,
        initialMemberIds: [coachId], // Add coach as initial member
        metadata: {
          'founded': '2023',
          'homeGround': 'Lahore Sports Complex',
          'teamColors': ['Blue', 'White'],
          'motto': 'Unity, Strength, Victory',
        },
      );

      // Update player member details (owner is already added, but we need to update role and details)
      final team = await _teamService.getTeam(teamId);
      if (team != null) {
        // Update owner to captain with proper details
        final ownerMember = team.members.firstWhere((m) => m.userId == playerId);
        if (ownerMember.role != TeamRole.captain) {
          final updatedMembers = team.members.map((m) {
            if (m.userId == playerId) {
              return TeamMember(
                userId: m.userId,
                userName: m.userName,
                userEmail: m.userEmail,
                profileImageUrl: m.profileImageUrl,
                role: TeamRole.captain,
                joinedAt: m.joinedAt,
                isActive: m.isActive,
                position: 'Forward',
                jerseyNumber: 10,
                trophies: 3,
                rating: 4.5,
              );
            }
            return m;
          }).toList();

          await _firestore.collection('teams').doc(teamId).update({
            'members': updatedMembers.map((m) => m.toMap()).toList(),
            'players': updatedMembers.where((m) => m.role != TeamRole.coach).map((m) => m.toMap()).toList(),
            'updatedAt': Timestamp.now(),
          });
        }

        // Ensure coach is properly added as coach role
        final coachMember = team.members.firstWhere(
          (m) => m.userId == coachId,
          orElse: () => throw Exception('Coach not found in team'),
        );
        
        if (coachMember.role != TeamRole.coach) {
          final updatedMembers = team.members.map((m) {
            if (m.userId == coachId) {
              return TeamMember(
                userId: m.userId,
                userName: m.userName,
                userEmail: m.userEmail,
                profileImageUrl: m.profileImageUrl,
                role: TeamRole.coach,
                joinedAt: m.joinedAt,
                isActive: m.isActive,
              );
            }
            return m;
          }).toList();

          await _firestore.collection('teams').doc(teamId).update({
            'members': updatedMembers.map((m) => m.toMap()).toList(),
            'coaches': updatedMembers.where((m) => m.role == TeamRole.coach).map((m) => m.toMap()).toList(),
            'updatedAt': Timestamp.now(),
          });
        }
      }

      // Update team with tournament participation
      await _firestore.collection('teams').doc(teamId).update({
        'tournamentsParticipated': FieldValue.arrayUnion([tournamentId]),
        'tournamentIds': FieldValue.arrayUnion([tournamentId]),
        'updatedAt': Timestamp.now(),
      });

      print('   ✅ Team created: Lahore United FC');
      return teamId;
    } finally {
      // Sign out after team creation
      await _auth.signOut();
    }
  }

  /// Register team in tournament
  Future<void> _registerTeamInTournament(String tournamentId, String teamId, String playerUid) async {
    // Sign in as player to register team (required for authentication)
    await _auth.signInWithEmailAndPassword(
      email: playerEmail,
      password: playerPassword,
    );

    try {
      // Check if team is already registered in tournament
      const teamName = 'Lahore United FC';
      final existingRegistration = await _firestore
          .collection('tournament_teams')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('name', isEqualTo: teamName)
          .limit(1)
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        print('   ℹ️  Team already registered in tournament: $teamName');
        return;
      }

      // Get team details
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Get player and coach profiles
      final captainMember = team.members.firstWhere(
        (m) => m.role == TeamRole.captain || m.role == TeamRole.owner,
        orElse: () => team.members.firstWhere((m) => m.role == TeamRole.member),
      );
      final coachProfile = team.coachId != null 
          ? await _userRepository.getUserProfile(team.coachId!)
          : null;

      // Create tournament team
      await _tournamentTeamService.createTeam(
        tournamentId: tournamentId,
        name: team.name,
        logoUrl: team.teamImageUrl,
        playerIds: team.players.map((p) => p.userId).toList(),
        playerNames: team.players.map((p) => p.userName).toList(),
        coachId: team.coachId,
        coachName: team.coachName,
        coachImageUrl: coachProfile?.profilePictureUrl,
      );

      // Update tournament currentTeamsCount
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'currentTeamsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      print('   ✅ Team registered in tournament');
    } finally {
      // Sign out after registration
      await _auth.signOut();
    }
  }

  /// Create/update public_profiles document
  Future<void> _createPublicProfile(String uid, UserProfile profile) async {
    try {
      // Get sports list based on profile type
      List<String> sports = [];
      String bio = profile.bio ?? '';
      String position = '';
      
      if (profile is PlayerProfile) {
        sports = profile.sportsOfInterest;
        position = profile.skillLevel.displayName;
      } else if (profile is CoachProfile) {
        sports = profile.specializationSports;
        position = '${profile.experienceYears} years experience';
      }

      // Create public_profiles document
      await _firestore.collection('public_profiles').doc(uid).set({
        'identity': {
          'fullName': profile.fullName,
          'role': profile.role.value,
          'tagline': profile.nickname ?? '',
          'city': profile.location,
          'age': profile.age,
          'profilePictureUrl': profile.profilePictureUrl ?? '',
          'coverMediaUrl': null,
          'badges': [],
          'isVerified': false,
        },
        'about': {
          'bio': bio,
          'sports': sports,
          'position': position,
          'availability': profile is PlayerProfile 
              ? profile.availability.map((slot) => '${slot.day}: ${slot.startTime}-${slot.endTime}').join(', ')
              : profile is CoachProfile
                  ? profile.availableTimeSlots.map((slot) => '${slot.day}: ${slot.startTime}-${slot.endTime}').join(', ')
                  : '',
          'highlights': [],
          'attributes': {},
          'statusMessage': '',
        },
        'skillPerformance': {
          'overallRating': 0,
          'metrics': [],
          'trends': [],
          'achievements': [],
        },
        'associations': {
          'teams': [],
          'tournaments': [],
          'venues': [],
          'coaches': [],
        },
        'followers': [],
        'following': [],
        'mutualConnections': [],
        'postsCount': 0,
        'matchesCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'matchmaking': {
          'tagline': bio.isNotEmpty ? bio.substring(0, bio.length > 100 ? 100 : bio.length) : '',
          'about': bio,
          'images': profile.profilePhotos,
          'age': profile.age,
          'city': profile.location,
          'sports': sports,
          'seeking': [],
          'distanceKm': null,
          'distanceLink': null,
          'featuredTeam': null,
          'featuredVenue': null,
          'featuredCoach': null,
          'featuredTournament': null,
          'allowMessagesFromFriendsOnly': false,
        },
        'contact': {
          'primaryActionLabel': 'Start chat',
          'allowMessagesFromFriendsOnly': false,
          'links': [],
        },
        'availableAssociations': {},
        'matchmakingLibrary': [],
        'featuredPostIds': [],
        'reviews': [],
      }, SetOptions(merge: true));
      
      print('   ✅ Public profile created/updated for ${profile.fullName}');
    } catch (e) {
      print('   ⚠️  Warning: Failed to create public profile: $e');
      // Don't throw - public profile is optional
    }
  }

  /// Update user profile with teamId (requires authentication)
  Future<void> _updateUserProfileWithTeamId(
    String uid,
    String teamId,
    String email,
    String password,
  ) async {
    // Sign in as the user to update their own profile
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      // Update the profile
      await _userRepository.updateUserProfile(uid, {'teamId': teamId});
      
      // Also update public_profiles if team association exists
      final team = await _teamService.getTeam(teamId);
      if (team != null) {
        await _firestore.collection('public_profiles').doc(uid).update({
          'associations.teams': FieldValue.arrayUnion([{
            'id': team.id,
            'name': team.name,
            'sportType': team.sportType.name,
            'imageUrl': team.teamImageUrl,
            'role': 'member',
          }]),
        });
      }
      
      print('   ✅ Updated profile for $email with teamId');
    } finally {
      // Sign out after update
      await _auth.signOut();
    }
  }

  /// Add more team members (around 20 total including wahaj and coach)
  Future<void> _addTeamMembers(String teamId, String playerUid, String email, String password) async {
    // Sign in as player (captain/owner) to add members
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Dummy team member names with realistic Pakistani names
      final dummyMembers = [
        {'name': 'Ahmed Ali', 'position': 'Goalkeeper', 'jersey': 1},
        {'name': 'Hassan Malik', 'position': 'Defender', 'jersey': 2},
        {'name': 'Usman Khan', 'position': 'Defender', 'jersey': 3},
        {'name': 'Bilal Ahmed', 'position': 'Defender', 'jersey': 4},
        {'name': 'Faisal Shah', 'position': 'Defender', 'jersey': 5},
        {'name': 'Hamza Rauf', 'position': 'Midfielder', 'jersey': 6},
        {'name': 'Zain Ali', 'position': 'Midfielder', 'jersey': 7},
        {'name': 'Saad Malik', 'position': 'Midfielder', 'jersey': 8},
        {'name': 'Haris Iqbal', 'position': 'Midfielder', 'jersey': 11},
        {'name': 'Yousuf Ahmed', 'position': 'Forward', 'jersey': 9},
        {'name': 'Amir Khan', 'position': 'Forward', 'jersey': 12},
        {'name': 'Tariq Hussain', 'position': 'Defender', 'jersey': 13},
        {'name': 'Waseem Akram', 'position': 'Midfielder', 'jersey': 14},
        {'name': 'Imran Ali', 'position': 'Forward', 'jersey': 15},
        {'name': 'Rashid Mehmood', 'position': 'Defender', 'jersey': 16},
        {'name': 'Adnan Sheikh', 'position': 'Midfielder', 'jersey': 17},
        {'name': 'Salman Butt', 'position': 'Forward', 'jersey': 18},
        {'name': 'Nadeem Aslam', 'position': 'Goalkeeper', 'jersey': 22},
      ];

      int addedCount = 0;
      final existingMemberIds = team.members.map((m) => m.userId).toSet();

      for (final member in dummyMembers) {
        // Create a dummy UID for each member
        final memberUid = 'member_${member['name']!.toLowerCase().replaceAll(' ', '_')}_${teamId.substring(0, 8)}';
        
        // Skip if already exists
        if (existingMemberIds.contains(memberUid)) {
          continue;
        }

        // Add member directly to Firestore (since they don't have auth accounts)
        final newMember = TeamMember(
          userId: memberUid,
          userName: member['name'] as String,
          userEmail: '${member['name']!.toLowerCase().replaceAll(' ', '.')}@playaround.com',
          role: TeamRole.member,
          joinedAt: DateTime.now(),
          isActive: true,
          position: member['position'] as String,
          jerseyNumber: member['jersey'] as int,
          trophies: 0,
          rating: 3.5 + (addedCount % 3) * 0.5, // Rating between 3.5 and 5.0
        );

        final updatedMembers = [...team.members, newMember];
        
        await _firestore.collection('teams').doc(teamId).update({
          'members': updatedMembers.map((m) => m.toMap()).toList(),
          'players': updatedMembers.where((m) => m.role != TeamRole.coach).map((m) => m.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });

        // Update team object for next iteration
        team.members.add(newMember);
        existingMemberIds.add(memberUid);
        addedCount++;

        print('   ✅ Added member: ${member['name']} (${member['position']}, #${member['jersey']})');
      }

      print('   ✅ Added $addedCount team members (Total: ${team.members.length + addedCount})');
    } finally {
      await _auth.signOut();
    }
  }

  /// Create tournament matches with player stats for Wahaj
  Future<void> _createTournamentMatchesWithStats(
    String tournamentId,
    String teamId,
    String playerUid,
    String coachUid,
    String email,
    String password,
  ) async {
    // Sign in as coach to create matches (tournament organizer)
    await _auth.signInWithEmailAndPassword(
      email: coachEmail,
      password: coachPassword,
    );

    try {
      // Get tournament and team details
      final tournamentDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (!tournamentDoc.exists) throw Exception('Tournament not found');
      
      final tournamentData = tournamentDoc.data()!;
      final tournamentName = tournamentData['name'] as String;
      final teamName = tournamentData['teamName'] ?? 'Lahore United FC';

      // Get team members
      final team = await _teamService.getTeam(teamId);
      if (team == null) throw Exception('Team not found');

      // Create 3 completed matches with stats for Wahaj
      final matches = [
        {
          'matchNumber': 'Match 1',
          'round': 'Group Stage',
          'opponent': 'Karachi Stars FC',
          'opponentScore': 1,
          'ourScore': 3,
          'wahajGoals': 2,
          'wahajAssists': 1,
          'scheduledTime': DateTime.now().subtract(const Duration(days: 14)),
        },
        {
          'matchNumber': 'Match 2',
          'round': 'Group Stage',
          'opponent': 'Islamabad United',
          'opponentScore': 0,
          'ourScore': 2,
          'wahajGoals': 1,
          'wahajAssists': 1,
          'scheduledTime': DateTime.now().subtract(const Duration(days: 10)),
        },
        {
          'matchNumber': 'Quarter Final',
          'round': 'Quarter Finals',
          'opponent': 'Faisalabad Falcons',
          'opponentScore': 2,
          'ourScore': 4,
          'wahajGoals': 3,
          'wahajAssists': 0,
          'scheduledTime': DateTime.now().subtract(const Duration(days: 6)),
        },
      ];

      for (final matchData in matches) {
        final opponentTeamId = 'opponent_${matchData['opponent']}'.toLowerCase().replaceAll(' ', '_');
        final opponentTeamName = matchData['opponent'] as String;

        // Create match with stats
        final team1Score = TeamMatchScore(
          teamId: teamId,
          teamName: teamName,
          score: matchData['ourScore'] as int,
          playerIds: team.members.where((m) => m.role != TeamRole.coach).map((m) => m.userId).toList(),
        );

        final team2Score = TeamMatchScore(
          teamId: opponentTeamId,
          teamName: opponentTeamName,
          score: matchData['opponentScore'] as int,
        );

        // Create player stats for our team - Wahaj has goals and assists
        final ourPlayerStats = <PlayerMatchStats>[];
        
        // Add Wahaj with goals and assists
        ourPlayerStats.add(PlayerMatchStats(
          playerId: playerUid,
          playerName: playerName,
          goals: matchData['wahajGoals'] as int,
          assists: matchData['wahajAssists'] as int,
        ));

        // Add a few other players with some stats
        final otherPlayers = team.members.where((m) => m.userId != playerUid && m.role != TeamRole.coach).take(5).toList();
        for (var i = 0; i < otherPlayers.length; i++) {
          if (i < 2) {
            // First 2 players get 1 goal each
            ourPlayerStats.add(PlayerMatchStats(
              playerId: otherPlayers[i].userId,
              playerName: otherPlayers[i].userName,
              goals: 1,
              assists: 0,
            ));
          } else {
            // Others get some assists
            ourPlayerStats.add(PlayerMatchStats(
              playerId: otherPlayers[i].userId,
              playerName: otherPlayers[i].userName,
              goals: 0,
              assists: 1,
            ));
          }
        }

        // Create opponent team player stats (just basic)
        final opponentPlayerStats = <PlayerMatchStats>[
          PlayerMatchStats(
            playerId: 'opponent_player_1',
            playerName: 'Opponent Player 1',
            goals: matchData['opponentScore'] as int > 0 ? 1 : 0,
            assists: 0,
          ),
        ];

        // Create match
        final matchId = await _matchService.createMatch(
          tournamentId: tournamentId,
          tournamentName: tournamentName,
          sportType: SportType.football,
          team1: team1Score,
          team2: team2Score,
          matchNumber: matchData['matchNumber'] as String,
          round: matchData['round'] as String,
          scheduledTime: matchData['scheduledTime'] as DateTime,
          venueName: 'Lahore Sports Complex',
          venueLocation: 'Lahore, Pakistan',
        );

        // Update match with player stats and mark as completed
        final actualStartTime = (matchData['scheduledTime'] as DateTime).add(const Duration(minutes: 5));
        final actualEndTime = actualStartTime.add(const Duration(minutes: 90));

        await _matchService.updatePlayerStats(
          matchId: matchId,
          team1PlayerStats: ourPlayerStats,
          team2PlayerStats: opponentPlayerStats,
        );

        // Mark match as completed
        await _firestore.collection('tournament_matches').doc(matchId).update({
          'status': 'completed',
          'actualStartTime': Timestamp.fromDate(actualStartTime),
          'actualEndTime': Timestamp.fromDate(actualEndTime),
          'winnerTeamId': teamId,
          'result': '${teamName} won ${matchData['ourScore']} - ${matchData['opponentScore']}',
          'manOfTheMatch': playerUid, // Wahaj is man of the match
          'team1CoachId': coachUid,
          'team1CoachName': coachName,
          'updatedAt': Timestamp.now(),
        });

        print('   ✅ Created match: ${matchData['matchNumber']} vs ${matchData['opponent']} (Wahaj: ${matchData['wahajGoals']} goals, ${matchData['wahajAssists']} assists)');
      }

      print('   ✅ Created ${matches.length} tournament matches with player stats');
    } finally {
      await _auth.signOut();
    }
  }

  /// Update Wahaj's skills based on tournament performance
  Future<void> _updatePlayerSkillsFromTournament(String tournamentId, String playerUid) async {
    try {
      // Get tournament details
      final tournamentDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (!tournamentDoc.exists) return;

      final tournamentData = tournamentDoc.data()!;
      final tournamentName = tournamentData['name'] as String;
      final sportType = SportType.values.firstWhere(
        (e) => e.name == (tournamentData['sportType'] as String? ?? 'football'),
        orElse: () => SportType.football,
      );

      // Get completed matches for this tournament and team
      final matchesQuery = await _firestore
          .collection('tournament_matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: 'completed')
          .get();

      int totalGoals = 0;
      int totalAssists = 0;
      int matchesWon = 0;
      int totalMatches = matchesQuery.docs.length;

      for (final matchDoc in matchesQuery.docs) {
        final matchData = matchDoc.data();
        final team1PlayerStats = matchData['team1PlayerStats'] as List<dynamic>? ?? [];
        
        // Find Wahaj's stats in this match
        for (final statData in team1PlayerStats) {
          if (statData['playerId'] == playerUid) {
            totalGoals += (statData['goals'] as num?)?.toInt() ?? 0;
            totalAssists += (statData['assists'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        // Check if our team won
        final winnerTeamId = matchData['winnerTeamId'] as String?;
        final team1Id = matchData['team1']?['teamId'] as String?;
        if (winnerTeamId == team1Id) {
          matchesWon++;
        }
      }

      final didWin = matchesWon > totalMatches / 2; // Won majority of matches

      // Update skills based on tournament performance
      await _skillService.onTournamentCompleted(
        tournamentId: tournamentId,
        userId: playerUid,
        sportType: sportType,
        isTeamTournament: true,
        didWin: didWin,
        tournamentName: tournamentName,
        additionalMetadata: {
          'totalMatches': totalMatches,
          'matchesWon': matchesWon,
          'totalGoals': totalGoals,
          'totalAssists': totalAssists,
        },
      );

      print('   ✅ Updated skills for Wahaj (Goals: $totalGoals, Assists: $totalAssists, Matches: $totalMatches, Won: $matchesWon)');
    } catch (e) {
      print('   ⚠️  Error updating skills: $e');
      // Don't throw - skills update is optional
    }
  }
}

