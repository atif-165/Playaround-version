# Community Feed Architecture

This document describes the production-grade architecture for the rebuilt Reddit-style community feed. It aligns with the requested clean layering, feature set, and platform constraints.

## High-Level Overview

- **Frontend:** Flutter (Android first, iOS-ready), structured with feature-driven folders
- **Backend:** Firebase (Firestore, Auth), Cloudinary for rich media
- **State Management:** Riverpod with `StateNotifier` controllers and immutable state objects
- **Offline & Caching:** Firestore offline persistence + Hive-backed local caches

```
lib/
 └─ features/
     └─ community_feed/
         ├─ models/
         ├─ services/
         ├─ repositories/
         ├─ state/
         └─ ui/
             ├─ components/
             └─ pages/
```

## Data Model

- `FeedPost`
  - identifiers, author metadata, title/body, `PostType` (text/link/image/video/gif/poll)
  - `List<FeedMedia>` with Cloudinary URLs, thumbnails, dimensions, duration
  - moderation flags (`nsfw`, `spoiler`, `sensitive`), `blurHash` for preview blur
  - aggregated counts (votes, comments, shares, awards map)
  - `PostMetadata` for link preview + poll configuration
- `FeedComment`
  - threaded via `parentId`, aggregated reply counts
- `UserPostState`
  - stored per user (`user_post_states/{userId}/posts/{postId}`)
  - vote, saved flag, awarded badges, report state

Serialization implemented via `json_serializable`.

## Firestore Collections

- `community_posts`
  - documents keyed by post id
  - subcollections:
    - `comments` (ordered by `createdAt`)
    - `awards` (aggregate definitions)
    - `reports` (moderator queue)
- `user_post_states/{userId}/posts/{postId}`
  - stores `vote`, `saved`, `awardsGiven`, timestamps
- `users` (existing)

### Indexes

Required composite indexes (added to `firestore.indexes.json`):

- `community_posts` ordered by `createdAt` (descending) with `isActive`
- `community_posts` filtered by `sport` + ordered by `createdAt`
- `community_posts` filtered by `authorId` + ordered by `createdAt`
- `community_posts` filtered by `nsfw`/`spoiler`

## Services

- `FirestoreFeedService`
  - CRUD for posts, comments, votes, reports
  - real-time queries (`Stream<Page<FeedPost>>`) using query cursors
- `CloudinaryMediaService`
  - resumable uploads with progress callbacks
  - client-side compression via `flutter_image_compress` & `video_compress`
  - thumbnail generation (`video_thumbnail`)
- `FeedCacheService`
  - Hive box per feed filter, TTL invalidation
- `PermissionService`
  - camera, storage, microphone runtime permissions

## Repositories

- `FeedRepository`
  - orchestrates Firestore service + cache
  - merges live snapshots with cached pages, deduplicates
- `UserPostStateRepository`
  - handles `user_post_states` collection for reactive personal data
- `CommentRepository`
  - streams comment threads and paged replies

## State Management

- `feedControllerProvider`
  - exposes `FeedState` (status, filters, paginated list, errors)
  - supports pull-to-refresh, `fetchNextPage`, and live snapshot merging
- `postDetailControllerProvider`
  - loads single post + live updates, comment summary
- `postEditorControllerProvider`
  - manages draft state, media uploads, validation, Cloudinary progress
- `commentThreadControllerProvider`
  - paged comments, optimistic updates
- `userPostStateProvider(postId)`
  - combines real-time vote/save state with aggregator updates

## UI Composition

- `FeedPage`
  - `CustomScrollView` with `SliverList` + `PagedChildBuilderDelegate`
  - `RefreshIndicator`, filter chips, `FloatingActionButton`
  - integrates `AnimatedSwitcher` for loading/error/empty states
- `FeedPostCard`
  - dynamic layout per post type
  - media carousel (`PageView` with lazy `FadeInImage` or `VideoPlayer`)
  - moderation overlays (blur + badges)
  - `VoteSaveBar`, `PostMetadataRow`, `CommentPreview`
- `PostDetailPage`
  - `NestedScrollView`, comment composer, replies accordion
- `PostEditorPage`
  - segmented controls for type selection
  - media pickers (camera/gallery), link preview fetcher
  - progress modals, validation feedback via toasts/snackbars
- `ReportSheet`, `AwardPickerSheet`, `ShareSheet`

## Media Handling

- **Images:** compressed via `flutter_image_compress` (max dimension 2048px)
- **Videos/GIFs:** transcoded via `video_compress`, thumbnails via `video_thumbnail`
- **Uploads:** progress stream piped to UI; supports cancel/retry

## Permissions & Platform

- `permission_handler` used before camera/gallery/mic access
- separate service ensures rationale dialogs on Android 13+
- video playback uses `video_player` with visibility detector to pause off-screen

## Moderation Workflow

- Flags (`nsfw`, `spoiler`, `sensitive`) stored per post; UI blurs media until tapped
- Reporting creates document in `community_posts/{postId}/reports`
- Security rules enforce author/admin operations only

## Caching & Offline

- Firestore persistence already enabled in `main.dart`
- Feed cache stores last 50 posts per filter; invalidated on soft refresh
- Editor drafts persisted locally (Hive) keyed by user

## Seeding & Tooling

- `scripts/seed_community_feed.py`
  - creates 200+ sports posts with Cloudinary placeholder media links
  - ensures coverage across cricket/football/basketball/tennis
- README instructions for running seed script & configuring Cloudinary/Firebase
- Firestore rules updated to support new collections, role-based access
- Manual QA test plan covering CRUD, media upload, real-time behaviour

## Next Steps

1. Update `pubspec.yaml` with required dependencies (`hooks_riverpod`, `flutter_image_compress`, `video_compress`, `video_player`, `visibility_detector`, `hive_generator`, etc.)
2. Scaffold feature directories & core utilities
3. Implement services and repositories with proper error handling
4. Build state controllers and UI pages
5. Integrate navigation & theming
6. Prepare seed script, indexes, security rules, documentation


