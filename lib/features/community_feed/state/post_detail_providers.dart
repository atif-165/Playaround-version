import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_comment.dart';
import '../models/feed_post.dart';
import 'feed_controller.dart';

final feedPostDetailProvider =
    StreamProvider.autoDispose.family<FeedPost?, String>((ref, postId) {
  final repository = ref.watch(feedRepositoryProvider);

  return repository.watchPost(postId).asyncMap((post) async {
    if (post == null) return null;
    final postsWithState = await repository.attachUserStates([post]);
    return postsWithState.isNotEmpty ? postsWithState.first : post;
  });
});

final feedPostCommentsProvider =
    StreamProvider.autoDispose.family<List<FeedComment>, String>((ref, postId) {
  final repository = ref.watch(feedRepositoryProvider);
  return repository.watchComments(postId);
});

