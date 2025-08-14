import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../lib/screens/profile/services/profile_data_service.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockQuery extends Mock implements Query {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  group('ProfileDataService', () {
    late ProfileDataService profileDataService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      profileDataService = ProfileDataService();
    });

    test('getUserConnections returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getUserConnections();

      // Assert
      expect(result, isEmpty);
    });

    test('getUserTeams returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getUserTeams();

      // Assert
      expect(result, isEmpty);
    });

    test('getUserPastTournaments returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getUserPastTournaments();

      // Assert
      expect(result, isEmpty);
    });

    test('getUserUpcomingTournaments returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getUserUpcomingTournaments();

      // Assert
      expect(result, isEmpty);
    });

    test('getConnectedCoaches returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getConnectedCoaches();

      // Assert
      expect(result, isEmpty);
    });

    test('getAllConnectedUsers returns empty list when user is null', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = await profileDataService.getAllConnectedUsers();

      // Assert
      expect(result, isEmpty);
    });
  });
}
