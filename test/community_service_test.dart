import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playaround/modules/community/services/community_service.dart';

void main() {
  group('CommunityService', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'admin', email: 'admin@test.com');
      auth = MockFirebaseAuth(mockUser: mockUser);
      await auth.signInWithEmailAndPassword(
          email: 'admin@test.com', password: 'password');
      CommunityService.overrideFirebase(firestore: firestore, auth: auth);
    });

    tearDown(() {
      CommunityService.reset();
    });

    Future<void> _seedPosts(int count) async {
      final now = DateTime(2024, 1, 1);
      for (int i = 0; i < count; i++) {
        await firestore.collection('posts').doc('post_$i').set({
          'id': 'post_$i',
          'authorId': 'user_$i',
          'authorName': 'User $i',
          'authorNickname': 'user$i',
          'content': 'Post number $i',
          'images': const [],
          'tags': ['tag$i'],
          'createdAt': Timestamp.fromDate(now.add(Duration(minutes: i))),
          'updatedAt': Timestamp.fromDate(now.add(Duration(minutes: i))),
          'likesCount': 0,
          'dislikesCount': 0,
          'commentsCount': 0,
          'sharesCount': 0,
          'metadata': const {},
          'isActive': true,
          'isFlagged': false,
          'flaggedBy': const [],
        });
      }
    }

    test('fetchPostsPage returns paginated results', () async {
      await _seedPosts(25);

      final firstPage = await CommunityService.fetchPostsPage(limit: 20);
      expect(firstPage.posts.length, 20);
      expect(firstPage.hasMore, true);
      expect(firstPage.lastDocument, isNotNull);

      final secondPage = await CommunityService.fetchPostsPage(
        limit: 20,
        startAfter: firstPage.lastDocument,
      );
      expect(secondPage.posts.length, 5);
      expect(secondPage.hasMore, false);
    });

    test('flag and unflag post toggles fields correctly', () async {
      await _seedPosts(1);
      await CommunityService.flagPost(
        postId: 'post_0',
        userId: 'reporter',
        reason: 'Spam',
      );

      final flaggedDoc =
          await firestore.collection('posts').doc('post_0').get();
      expect(flaggedDoc.data()?['isFlagged'], true);
      expect(flaggedDoc.data()?['flaggedBy'], contains('reporter'));
      expect(flaggedDoc.data()?['flaggedReason'], 'Spam');

      await CommunityService.unflagPost('post_0');
      final unflaggedDoc =
          await firestore.collection('posts').doc('post_0').get();
      expect(unflaggedDoc.data()?['isFlagged'], false);
      expect(unflaggedDoc.data()?['flaggedBy'], isEmpty);
    });

    test('adminRemovePost marks post inactive', () async {
      await _seedPosts(1);
      await CommunityService.adminRemovePost(
        postId: 'post_0',
        adminId: 'admin',
        note: 'Violation',
      );
      final doc = await firestore.collection('posts').doc('post_0').get();
      expect(doc.data()?['isActive'], false);
      expect(doc.data()?['metadata']['status'], 'removed');
    });

    test('warnUser increments warnings and blocks posting', () async {
      await firestore
          .collection('users')
          .doc('user123')
          .set({'fullName': 'Test User'});

      await CommunityService.warnUser(
        userId: 'user123',
        adminId: 'admin',
        reason: 'Guideline violation',
      );

      final userDoc = await firestore.collection('users').doc('user123').get();
      final data = userDoc.data()!;

      expect(data['communityWarningsCount'], 1);
      expect(data['communityPostingBlocked'], true);
      expect(data['communityBlockedReason'], 'Guideline violation');

      await CommunityService.setUserPostingBlocked(
        userId: 'user123',
        blocked: false,
      );

      final updated = await firestore.collection('users').doc('user123').get();
      final updatedData = updated.data()!;
      expect(updatedData['communityPostingBlocked'], false);
      expect(updatedData.containsKey('communityBlockedReason'), false);
    });
  });
}
