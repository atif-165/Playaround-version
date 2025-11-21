import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../models/coach_profile.dart';
import '../../../models/venue_model.dart';
import '../../../modules/community/models/community_post.dart';
import '../../../modules/community/models/user_like_status.dart';
import '../../../modules/community/services/community_service.dart';
import '../../../modules/community/services/community_user_service.dart';
import '../../../modules/community/widgets/community_post_card.dart';
import '../../../modules/chat/models/chat_room.dart';
import '../../../modules/chat/services/chat_service.dart';
import '../../../models/coach_associations.dart';
import '../../../modules/coach/services/coach_associations_service.dart';
import '../../../modules/coach/services/coach_service.dart';
import '../../../modules/team/models/team_model.dart';
import '../../../modules/team/services/team_service.dart';
import '../../../modules/tournament/models/tournament_model.dart';
import '../../../modules/tournament/services/tournament_service.dart';
import '../../../routing/routes.dart';
import '../../../services/cloudinary_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/user_profile_dashboard_models.dart';
import '../services/user_profile_dashboard_service.dart';

/// Public profile experience replacing the legacy dashboard screen.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userId});

  final String? userId;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final PublicProfileService _service = PublicProfileService();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final CoachAssociationsService _coachAssociationsService =
      CoachAssociationsService();
  final TeamService _teamService = TeamService();
  final TournamentService _tournamentService = TournamentService();
  final CoachService _coachService = CoachService();
  final ChatService _chatService = ChatService();

  late TabController _tabController;

  bool _loading = true;
  bool _error = false;
  bool _uploadingImage = false;
  bool _isHeroMediaUploading = false;

  ProfileIdentity? _identity;
  List<ProfileStat> _stats = [];
  ProfileAboutData? _about;
  SkillPerformanceSummary? _skillPerformance;
  List<AssociationCardData> _teams = [];
  List<AssociationCardData> _tournaments = [];
  List<AssociationCardData> _venues = [];
  List<AssociationCardData> _coaches = [];
  List<CommunityPost> _posts = [];
  MatchmakingShowcase? _matchmaking;
  List<ReviewEntry> _reviews = [];
  ContactPreferences? _contactPreferences;

  Map<String, List<AssociationCardData>> _availableAssociations = {};
  List<CommunityPost> _availablePosts = [];
  List<String> _matchmakingLibrary = [];
  final Map<String, UserLikeStatus> _postLikeStatuses = {};
  StreamSubscription<List<CommunityPost>>? _postsSubscription;
  StreamSubscription<DocumentSnapshot>? _associationsSubscription;
  StreamSubscription<QuerySnapshot>? _associationRequestsSubscription;
  final NumberFormat _decimalNumberFormat = NumberFormat.decimalPattern();
  final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');

  int _postsCount = 0;
  int _matchesCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isFollowedByViewer = false;
  bool _isLaunchingChat = false;
  List<ProfileConnection> _followers = [];
  List<ProfileConnection> _following = [];
  List<ProfileConnection> _mutualConnections = [];

  Set<String> _selectedTeamIds = {};
  Set<String> _selectedTournamentIds = {};
  Set<String> _selectedVenueIds = {};
  Set<String> _selectedCoachIds = {};
  Set<String> _selectedPostIds = {};
  List<String> _matchmakingImages = [];

  final PageController _carouselController =
      PageController(viewportFraction: 0.82);
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: PublicProfileTab.values.length, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _carouselController.dispose();
    _postsSubscription?.cancel();
    _associationsSubscription?.cancel();
    _associationRequestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfile({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final uid = widget.userId ??
          FirebaseAuth.instance.currentUser?.uid ??
          'demo-player';
      final data = await _service.fetchProfile(uid);
      if (!mounted) return;
      _applyData(data);
    } catch (error, stack) {
      debugPrint('Failed to load public profile: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyData(PublicProfileData data) {
    setState(() {
      _identity = data.identity;
      _about = data.about;
      _skillPerformance = data.skillPerformance;
      _teams = List<AssociationCardData>.from(data.teams);
      _tournaments = List<AssociationCardData>.from(data.tournaments);
      _venues = List<AssociationCardData>.from(data.venues);
      _coaches = List<AssociationCardData>.from(data.coaches);
      _posts = List<CommunityPost>.from(data.communityPosts);
      _matchmaking = data.matchmaking;
      _reviews = List<ReviewEntry>.from(data.reviews);
      _contactPreferences = data.contactPreferences;
      _postsCount = data.postsCount;
      _matchesCount = data.matchesCount;
      _followersCount = data.followersCount;
      _followingCount = data.followingCount;
      _isFollowing = data.isFollowing;
      _isFollowedByViewer = data.isFollowedByViewer;
      _followers = List<ProfileConnection>.from(data.followers);
      _following = List<ProfileConnection>.from(data.following);
      _mutualConnections = List<ProfileConnection>.from(data.mutualConnections);
      _availableAssociations = data.availableAssociations.map(
        (key, value) => MapEntry(key, List<AssociationCardData>.from(value)),
      );
      _availablePosts = List<CommunityPost>.from(data.availablePosts);
      _matchmakingLibrary = List<String>.from(data.matchmakingLibrary);

      _selectedTeamIds = _teams.map((e) => e.id).toSet();
      _selectedTournamentIds = _tournaments.map((e) => e.id).toSet();
      _selectedVenueIds = _venues.map((e) => e.id).toSet();
      _selectedCoachIds = _coaches.map((e) => e.id).toSet();
      _selectedPostIds = data.featuredPostIds.toSet();
      _matchmakingImages = List<String>.from(_matchmaking?.images ?? []);
      _stats = _buildStatsFromCounts();
    });

    _listenToCommunityPosts(data.identity.userId);
    _loadPostLikeStatuses(_posts);
    _listenToAssociationStatusChanges(data.identity.userId);
    _listenToAssociationRequests(data.identity.userId);
  }

  List<ProfileStat> _buildStatsFromCounts() {
    return [
      ProfileStat(
        label: 'Posts',
        value: _postsCount.toString(),
        icon: Icons.article_outlined,
      ),
      ProfileStat(
        label: 'Swipe matches',
        value: _matchesCount.toString(),
        icon: Icons.link_rounded,
      ),
      ProfileStat(
        label: 'Following',
        value: _formatCount(_followingCount),
        icon: Icons.favorite_outline,
      ),
      ProfileStat(
        label: 'Followers',
        value: _formatCount(_followersCount),
        icon: Icons.groups_3_outlined,
      ),
    ];
  }

  String _formatCount(int count) => _decimalNumberFormat.format(count);

  List<String> _parseListInput(String input) {
    return input
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  VoidCallback? _statTapHandler(ProfileStat stat) {
    switch (stat.label) {
      case 'Following':
        return () => _showConnectionsSheet(
              'Following',
              _following,
              showFollowAction: true,
            );
      case 'Followers':
        return () => _showConnectionsSheet(
              'Followers',
              _followers,
              showFollowAction: true,
            );
      case 'Swipe matches':
        return () => _showConnectionsSheet(
              'Swipe matches',
              _mutualConnections,
            );
      default:
        return null;
    }
  }

  void _listenToCommunityPosts(String userId) {
    if (userId.isEmpty) return;
    _postsSubscription?.cancel();
    _postsSubscription =
        CommunityService.getUserPostsStream(userId).listen((posts) {
      if (!mounted) return;
      setState(() {
        final postIds = posts.map((post) => post.id).toSet();
        if (_selectedPostIds.isNotEmpty) {
          _selectedPostIds.removeWhere((id) => !postIds.contains(id));
        }
        final selectedIds = _selectedPostIds;
        final visiblePosts = selectedIds.isEmpty
            ? posts
            : posts.where((post) => selectedIds.contains(post.id)).toList();
        _posts = List<CommunityPost>.from(visiblePosts);
        _availablePosts = List<CommunityPost>.from(posts);
        _postLikeStatuses.removeWhere(
          (postId, _) => !postIds.contains(postId),
        );
        _postsCount = posts.length;
        _stats = _buildStatsFromCounts();
      });
      _loadPostLikeStatuses(posts);
    }, onError: (error) {
      debugPrint('Failed to stream community posts for $userId: $error');
    });
  }

  void _listenToAssociationStatusChanges(String userId) {
    if (userId.isEmpty) return;
    _associationsSubscription?.cancel();
    
    // Listen to coach_associations document for status changes (teams and venues)
    _associationsSubscription = FirebaseFirestore.instance
        .collection('coach_associations')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;
      
      try {
        final data = snapshot.data();
        if (data == null) return;
        
        // Check for newly approved associations
        final teams = (data['teams'] as List<dynamic>?) ?? [];
        final venues = (data['venues'] as List<dynamic>?) ?? [];
        
        // Find approved associations that aren't in availableAssociations yet
        final newlyApprovedTeams = <String>[];
        final newlyApprovedVenues = <String>[];
        
        for (final teamData in teams) {
          final teamMap = teamData as Map<String, dynamic>;
          final status = teamMap['status'] as String?;
          final teamId = teamMap['teamId'] as String?;
          
          if (status == 'approved' && teamId != null) {
            final isAlreadyAvailable = _availableAssociations['teams']
                ?.any((item) => item.id == teamId) ?? false;
            if (!isAlreadyAvailable) {
              newlyApprovedTeams.add(teamId);
            }
          }
        }
        
        for (final venueData in venues) {
          final venueMap = venueData as Map<String, dynamic>;
          final status = venueMap['status'] as String?;
          final venueId = venueMap['venueId'] as String?;
          
          if (status == 'approved' && venueId != null) {
            final isAlreadyAvailable = _availableAssociations['venues']
                ?.any((item) => item.id == venueId) ?? false;
            if (!isAlreadyAvailable) {
              newlyApprovedVenues.add(venueId);
            }
          }
        }
        
        // If there are newly approved associations, refresh the profile
        if (newlyApprovedTeams.isNotEmpty || newlyApprovedVenues.isNotEmpty) {
          _fetchProfile(refresh: true);
        }
      } catch (e) {
        debugPrint('Error listening to association status changes: $e');
      }
    }, onError: (error) {
      debugPrint('Failed to stream association status changes: $error');
    });
  }

  void _listenToAssociationRequests(String userId) {
    if (userId.isEmpty) return;
    _associationRequestsSubscription?.cancel();
    
    // Listen to profile_association_requests for tournaments and coaches
    _associationRequestsSubscription = FirebaseFirestore.instance
        .collection('profile_association_requests')
        .where('requesterId', isEqualTo: userId)
        .where('type', whereIn: ['tournament', 'coach'])
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      try {
        bool shouldRefresh = false;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;
          final type = data['type'] as String?;
          final associationId = data['associationId'] as String?;
          
          // Check if request was approved
          if (status == 'approved' && associationId != null && type != null) {
            final typeKey = type == 'tournament' ? 'tournaments' : 'coaches';
            final isAlreadyAvailable = _availableAssociations[typeKey]
                ?.any((item) => item.id == associationId) ?? false;
            
            if (!isAlreadyAvailable) {
              shouldRefresh = true;
              break;
            }
          }
        }
        
        // If there are newly approved associations, refresh the profile
        if (shouldRefresh) {
          _fetchProfile(refresh: true);
        }
      } catch (e) {
        debugPrint('Error listening to association requests: $e');
      }
    }, onError: (error) {
      debugPrint('Failed to stream association requests: $error');
    });
  }

  Future<void> _loadPostLikeStatuses(List<CommunityPost> posts) async {
    if (posts.isEmpty) return;
    final futures = posts.map((post) async {
      final status = await CommunityService.getUserLikeStatus(post.id);
      return MapEntry(post.id, status);
    }).toList();

    final results = await Future.wait(futures);
    if (!mounted) return;

    setState(() {
      for (final entry in results) {
        _postLikeStatuses[entry.key] = entry.value;
      }
    });
  }

  Future<void> _toggleCommunityReaction(CommunityPost post, bool isLike) async {
    try {
      final nickname = await CommunityUserService.getCurrentUserNickname();
      final status =
          await CommunityService.toggleLike(post.id, isLike, nickname);
      if (!mounted) return;
      setState(() {
        _postLikeStatuses[post.id] = status;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reaction: $error')),
      );
    }
  }

  void _openCommunityPostDetail(CommunityPost post) {
    Navigator.pushNamed(
      context,
      Routes.communityPostDetail,
      arguments: post,
    );
  }

  void _openCommunityAuthorProfile(String userId) {
    Navigator.pushNamed(
      context,
      Routes.profileScreen,
      arguments: userId,
    );
  }

  void _handleCommunityPostOptions(CommunityPost post) {
    final isOwner = CommunityUserService.isCurrentUserPostOwner(post.authorId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                gradient: PublicProfileTheme.panelGradient,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.open_in_new,
                        color: PublicProfileTheme.panelAccentColor,
                      ),
                      title: Text(
                        'View post details',
                        style: TextStyles.font14DarkBlue600Weight
                            .copyWith(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _openCommunityPostDetail(post);
                      },
                    ),
                    if (isOwner)
                      ListTile(
                        leading: Icon(Icons.delete, color: ColorsManager.error),
                        title: Text(
                          'Delete post',
                          style: TextStyles.font14DarkBlue600Weight
                              .copyWith(color: ColorsManager.error),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeletePost(post);
                        },
                      ),
                    if (!isOwner)
                      ListTile(
                        leading: Icon(Icons.report,
                            color: Colors.white.withOpacity(0.7)),
                        title: Text(
                          'Report post',
                          style: TextStyles.font14DarkBlue600Weight
                              .copyWith(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _reportPost(post);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text('Delete post'),
        content: const Text(
          'Are you sure you want to delete this community post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: ColorsManager.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CommunityService.deletePost(post.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $error')),
        );
      }
    }
  }

  Future<void> _reportPost(CommunityPost post) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report posts.')),
      );
      return;
    }

    try {
      await CommunityService.flagPost(
        postId: post.id,
        userId: userId,
        reason: 'Reported from profile screen',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported for review')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report post: $error')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    final identity = _identity;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (identity == null) return;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to follow players.')),
        );
      }
      return;
    }
    if (_isViewingOwnProfile) {
      return;
    }

    final viewerConnection = _createViewerConnection();
    final viewerId = viewerConnection.userId;
    final shouldFollow = !_isFollowing;

    // Validate required fields
    if (identity.userId.isEmpty || viewerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user data. Please try again.')),
        );
      }
      return;
    }

    final targetUserName = identity.fullName.trim();
    final viewerName = viewerConnection.name.trim();
    
    if (targetUserName.isEmpty || viewerName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User name is missing. Please update your profile.')),
        );
      }
      return;
    }

    final previousFollowingState = _isFollowing;
    final previousFollowersCount = _followersCount;
    final previousFollowers = List<ProfileConnection>.from(_followers);
    final previousMutualConnections =
        List<ProfileConnection>.from(_mutualConnections);
    final previousMatchesCount = _matchesCount;

    setState(() {
      if (shouldFollow) {
        _isFollowing = true;
        _followersCount += 1;
        if (!_followers.any((conn) => conn.userId == viewerId)) {
          _followers.insert(0, viewerConnection);
        }
        if (_isFollowedByViewer &&
            !_mutualConnections.any((conn) => conn.userId == viewerId)) {
          _mutualConnections.insert(0, viewerConnection);
          _matchesCount += 1;
        }
      } else {
        _isFollowing = false;
        if (_followersCount > 0) {
          _followersCount -= 1;
        }
        _followers.removeWhere((conn) => conn.userId == viewerId);

        if (_isFollowedByViewer) {
          var removedMutual = false;
          _mutualConnections.removeWhere((conn) {
            final shouldRemove = conn.userId == viewerId;
            if (shouldRemove) removedMutual = true;
            return shouldRemove;
          });
          if (removedMutual && _matchesCount > 0) {
            _matchesCount -= 1;
          }
        }
      }
      _stats = _buildStatsFromCounts();
    });

    try {
      await _service.updateFollowStatus(
        targetUserId: identity.userId,
        targetUserName: targetUserName,
        targetAvatarUrl: identity.profilePictureUrl,
        viewerId: viewerId,
        viewerName: viewerName,
        viewerAvatarUrl: viewerConnection.avatarUrl,
        follow: shouldFollow,
      );

      if (shouldFollow && _isFollowedByViewer) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Connection matched! You can now message each other.'),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isFollowing = previousFollowingState;
        _followersCount = previousFollowersCount;
        _followers = List<ProfileConnection>.from(previousFollowers);
        _mutualConnections =
            List<ProfileConnection>.from(previousMutualConnections);
        _matchesCount = previousMatchesCount;
        _stats = _buildStatsFromCounts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow: $error')),
      );
    }
  }

  Future<void> _handleMessageTap() async {
    if (_isLaunchingChat) return;

    final identity = _identity;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (identity == null) return;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send messages.')),
        );
      }
      return;
    }
    if (identity.userId == currentUser.uid) {
      return;
    }

    setState(() {
      _isLaunchingChat = true;
    });

    try {
      ChatRoom? chatRoom;
      final fallbackName = identity.fullName.trim().isNotEmpty
          ? identity.fullName
          : 'Player';
      final fallbackAvatar = identity.profilePictureUrl.isNotEmpty
          ? identity.profilePictureUrl
          : null;

      if (_hasMutualConnection) {
        chatRoom = await _chatService.getOrCreateDirectChat(
          identity.userId,
          otherUserName: fallbackName,
          otherUserImageUrl: fallbackAvatar,
        );
      } else {
        chatRoom = await _chatService.startNonConnectionChat(
          identity.userId,
          otherUserName: fallbackName,
          otherUserImageUrl: fallbackAvatar,
        );
      }

      if (!mounted) return;

      if (chatRoom != null) {
        Navigator.pushNamed(
          context,
          Routes.chatScreen,
          arguments: chatRoom,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open chat right now. Please try again.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingChat = false;
        });
      }
    }
  }

  Future<bool> _submitAssociationRequest(
    AssociationCardData association,
    String type,
  ) async {
    final identity = _identity;
    if (identity == null) return false;
    try {
      // Create the association request
      await _service.createAssociationRequest(
        requesterId: identity.userId,
        requesterName: identity.fullName,
        association: association,
        type: type,
      );
      
      // Save pending association to public_profiles document
      await _service.savePendingAssociation(
        userId: identity.userId,
        association: association,
        type: type,
      );
      
      if (!mounted) return false;
      _showAssociationRequestDialog(association);
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $error'),
        ),
      );
      return false;
    }
  }

  Future<void> _announceAssociationUpdate({
    required String type,
    required AssociationCardData association,
  }) async {
    final identity = _identity;
    if (identity == null) return;
    try {
      await _service.notifyFollowersOfUpdate(
        profileUserId: identity.userId,
        title: '${identity.fullName} updated their profile',
        message: '${identity.fullName} added a new $type: ${association.title}',
        data: {
          'type': type,
          'entityId': association.id,
        },
      );
    } catch (error) {
      debugPrint('Failed to notify followers of $type update: $error');
    }
  }

  void _showAssociationRequestDialog(AssociationCardData association) {
    final recipient = association.ownerName ?? association.title;
    final entity = association.title;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text('Request sent'),
        content: Text(
          'Request sent to $recipient. $entity will appear on your public profile once approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  bool get _isViewingOwnProfile {
    final profileId = _identity?.userId;
    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    return profileId != null && viewerId != null && profileId == viewerId;
  }

  ProfileConnection _createViewerConnection() {
    final user = FirebaseAuth.instance.currentUser;
    final viewerId = user?.uid ?? 'viewer';
    final viewerName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'You';
    final viewerAvatar = user?.photoURL ?? '';
    return ProfileConnection(
      userId: viewerId,
      name: viewerName,
      avatarUrl: viewerAvatar,
      isFollowing: true,
    );
  }

  bool get _hasMutualConnection => _isFollowing && _isFollowedByViewer;

  bool get _canMessageViewer {
    final restrictToFriends =
        _contactPreferences?.allowMessagesFromFriendsOnly ?? false;
    if (restrictToFriends) {
      return _hasMutualConnection;
    }
    return true;
  }

  void _showMessageRestriction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Follow each other to unlock direct messages.'),
      ),
    );
  }

  Future<void> _showConnectionsSheet(
    String title,
    List<ProfileConnection> connections, {
    bool showFollowAction = false,
  }) async {
    if (connections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $title yet.')),
      );
      return;
    }

    final viewerId = FirebaseAuth.instance.currentUser?.uid ?? 'viewer';
    final localConnections = List<ProfileConnection>.from(connections);
    final viewerFollowingIds =
        await _service.getFollowingUserIds(viewerId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: PublicProfileTheme.panelGradient,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: TextStyles.font16DarkBlue600Weight
                                    .copyWith(color: Colors.white),
                              ),
                              Text(
                                connections.length.toString(),
                                style: TextStyles.font12Grey400Weight,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: localConnections.length,
                            itemBuilder: (context, index) {
                              final connection = localConnections[index];
                              final isViewer = connection.userId == viewerId;
                              final isFollowersList = title == 'Followers';
                              final isFollowingList = title == 'Following';
                              final bool isOwn = _isViewingOwnProfile;
                              final bool isViewerFollowing =
                                  viewerFollowingIds.contains(connection.userId);

                              return ListTile(
                                onTap: () {
                                  Navigator.pop(context);
                                  _openConnectionProfile(connection);
                                },
                                leading: CircleAvatar(
                                  backgroundImage:
                                      connection.avatarUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              connection.avatarUrl)
                                          : null,
                                  child: connection.avatarUrl.isEmpty
                                      ? Text(
                                          connection.name.isNotEmpty
                                              ? connection.name[0].toUpperCase()
                                              : '?',
                                          style:
                                              TextStyles.font14White600Weight,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  connection.name,
                                  style: TextStyles.font14DarkBlue600Weight
                                      .copyWith(color: Colors.white),
                                ),
                                trailing: showFollowAction && !isViewer
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isOwn) ...[
                                            // Viewing another user's profile: only Follow or label "Following"
                                            if (isViewerFollowing)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 6.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.r),
                                                ),
                                                child: const Text('Following'),
                                              )
                                            else
                                              TextButton(
                                                onPressed: () async {
                                                  final viewer = FirebaseAuth
                                                      .instance.currentUser;
                                                  final viewerName = (viewer
                                                                  ?.displayName
                                                                  ?.trim()
                                                                  .isNotEmpty ??
                                                              false)
                                                          ? viewer!
                                                              .displayName!
                                                              .trim()
                                                          : 'Someone';
                                                  await _service
                                                      .updateFollowStatus(
                                                    targetUserId:
                                                        connection.userId,
                                                    targetUserName:
                                                        connection.name,
                                                    targetAvatarUrl:
                                                        connection.avatarUrl,
                                                    viewerId: viewerId,
                                                    viewerName: viewerName,
                                                    viewerAvatarUrl:
                                                        viewer?.photoURL,
                                                    follow: true,
                                                  );
                                                  setSheetState(() {
                                                    viewerFollowingIds.add(
                                                        connection.userId);
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      PublicProfileTheme
                                                          .panelAccentColor,
                                                  foregroundColor: Colors.black,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                    vertical: 8.h,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                ),
                                                child: const Text('Follow'),
                                              ),
                                          ] else ...[
                                            // Viewing own profile
                                            if (isFollowingList) ...[
                                              TextButton(
                                                onPressed: () async {
                                                  final viewer = FirebaseAuth
                                                      .instance.currentUser;
                                                  final viewerName = (viewer
                                                                  ?.displayName
                                                                  ?.trim()
                                                                  .isNotEmpty ??
                                                              false)
                                                          ? viewer!
                                                              .displayName!
                                                              .trim()
                                                          : 'You';
                                                  await _service
                                                      .updateFollowStatus(
                                                    targetUserId:
                                                        connection.userId,
                                                    targetUserName:
                                                        connection.name,
                                                    targetAvatarUrl:
                                                        connection.avatarUrl,
                                                    viewerId: viewerId,
                                                    viewerName: viewerName,
                                                    viewerAvatarUrl:
                                                        viewer?.photoURL,
                                                    follow: false,
                                                  );
                                                  setSheetState(() {
                                                    localConnections
                                                        .removeAt(index);
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  backgroundColor: Colors.red
                                                      .withOpacity(0.08),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 8.h,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                ),
                                                child: const Text('Unfollow'),
                                              ),
                                            ] else if (isFollowersList) ...[
                                              if (isViewerFollowing)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 12.w,
                                                      vertical: 6.h),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                  child:
                                                      const Text('Following'),
                                                )
                                              else
                                                TextButton(
                                                  onPressed: () async {
                                                    final viewer =
                                                        FirebaseAuth.instance
                                                            .currentUser;
                                                    final viewerName = (viewer
                                                                    ?.displayName
                                                                    ?.trim()
                                                                    .isNotEmpty ??
                                                                false)
                                                            ? viewer!
                                                                .displayName!
                                                                .trim()
                                                            : 'You';
                                                    await _service
                                                        .updateFollowStatus(
                                                      targetUserId:
                                                          connection.userId,
                                                      targetUserName:
                                                          connection.name,
                                                      targetAvatarUrl:
                                                          connection.avatarUrl,
                                                      viewerId: viewerId,
                                                      viewerName: viewerName,
                                                      viewerAvatarUrl:
                                                          viewer?.photoURL,
                                                      follow: true,
                                                    );
                                                    setSheetState(() {
                                                      viewerFollowingIds.add(
                                                          connection.userId);
                                                    });
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        PublicProfileTheme
                                                            .panelAccentColor,
                                                    foregroundColor:
                                                        Colors.black,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 8.h,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.r),
                                                    ),
                                                  ),
                                                  child:
                                                      const Text('Follow Back'),
                                                ),
                                              Gap(8.w),
                                              TextButton(
                                                onPressed: () async {
                                                  // Remove follower: invert roles
                                                  await _service
                                                      .updateFollowStatus(
                                                    targetUserId:
                                                        _identity!.userId,
                                                    targetUserName:
                                                        _identity!.fullName,
                                                    targetAvatarUrl: _identity!
                                                        .profilePictureUrl,
                                                    viewerId: connection.userId,
                                                    viewerName:
                                                        connection.name,
                                                    viewerAvatarUrl:
                                                        connection.avatarUrl,
                                                    follow: false,
                                                  );
                                                  setSheetState(() {
                                                    localConnections
                                                        .removeAt(index);
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  backgroundColor: Colors.red
                                                      .withOpacity(0.08),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 8.h,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                ),
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ],
                                        ],
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openConnectionProfile(ProfileConnection connection) {
    if (connection.userId == _identity?.userId) {
      return;
    }
    DetailNavigator.openPlayer(context, userId: connection.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error || _identity == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: ColorsManager.error, size: 48.sp),
              Gap(12.h),
              Text(
                'We couldn\'t load this profile.',
                style: TextStyles.font16DarkBlue600Weight,
              ),
              Gap(12.h),
              ElevatedButton(
                onPressed: () => _fetchProfile(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Locked profile: restrict content for non-followed-back viewers
    final bool isLocked =
        _contactPreferences?.allowMessagesFromFriendsOnly ?? false;
    if (isLocked && !_isViewingOwnProfile && !_isFollowedByViewer) {
      return Scaffold(
        backgroundColor: PublicProfileTheme.backgroundColor,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: PublicProfileTheme.backgroundGradient,
          ),
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildHeroAppBar(),
              _buildStatsSection(),
            ],
            body: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white70, size: 18.sp),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          'This profile is currently locked.',
                          style: TextStyles.font14Grey400Weight,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(16.h),
                // About section only
                _buildAboutTab(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      floatingActionButton: _buildFloatingButton(),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: () => _fetchProfile(refresh: true),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildHeroAppBar(),
              _buildStatsSection(),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarHeaderDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelStyle: TextStyles.font14DarkBlue600Weight
                        .copyWith(color: PublicProfileTheme.panelAccentColor),
                    unselectedLabelStyle: TextStyles.font14Grey400Weight
                        .copyWith(color: Colors.white.withOpacity(0.6)),
                    labelColor: PublicProfileTheme.panelAccentColor,
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
                    indicatorColor: PublicProfileTheme.panelAccentColor,
                    indicatorWeight: 3,
                    tabs: PublicProfileTab.values
                        .map((tab) => Tab(text: _tabLabel(tab)))
                        .toList(),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildSkillsTab(),
                _buildTeamsTab(),
                _buildVenuesTab(),
                _buildCommunityTab(),
                _buildMatchmakingTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HERO ---------------------------------------------------------------------

  SliverAppBar _buildHeroAppBar() {
    final identity = _identity!;
    final coverUrl = _hasMedia(identity.coverMediaUrl)
        ? identity.coverMediaUrl
        : (_hasMedia(identity.profilePictureUrl)
            ? identity.profilePictureUrl
            : null);

    return SliverAppBar(
      expandedHeight: 380.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final percentage = (constraints.maxHeight - kToolbarHeight) /
              (380.h - kToolbarHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onLongPress: _isViewingOwnProfile
                    ? () => _showHeroMediaOptions(isCover: true)
                    : null,
                child: _buildHeroBackground(coverUrl),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PublicProfileTheme.backgroundColor.withOpacity(0.88),
                      Colors.transparent,
                      PublicProfileTheme.backgroundColor,
                    ],
                  ),
                ),
              ),
              if (_isHeroMediaUploading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.h,
                right: 16.w,
                child: Row(
                  children: [
                    _HeroActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: _shareProfile,
                    ),
                    Gap(12.w),
                    if (_isViewingOwnProfile)
                      _HeroActionButton(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'Admin',
                        onTap: _openAdminPanel,
                      )
                    else
                      _HeroOverflowButton(onPressed: _openViewerActions),
                    if (_isViewingOwnProfile) ...[
                      Gap(12.w),
                      _HeroIconButton(
                        icon: Icons.logout,
                        onTap: _confirmLogout,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 20.w,
                right: 20.w,
                bottom: 20.h,
                child: Opacity(
                  opacity: percentage.clamp(0, 1),
                  child: _buildHeroIdentity(identity),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroIdentity(ProfileIdentity identity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onLongPress: _isViewingOwnProfile
              ? () => _showHeroMediaOptions(isCover: false)
              : null,
          child: _buildProfileAvatar(identity),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      identity.fullName,
                      style: TextStyles.font32White700Weight,
                    ),
                  ),
                  if (identity.isVerified) ...[
                    Gap(8.w),
                    Icon(
                      Icons.verified,
                      color: PublicProfileTheme.panelAccentColor,
                      size: 24.sp,
                    ),
                  ],
                ],
              ),
              Gap(4.h),
              Text(
                identity.tagline.trim().isEmpty
                    ? 'Add a headline from your admin panel'
                    : identity.tagline,
                style: TextStyles.font14White400Weight.copyWith(
                  color: identity.tagline.trim().isEmpty
                      ? Colors.white70
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBackground(String? coverUrl) {
    if (_hasMedia(coverUrl)) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: PublicProfileTheme.panelOverlayColor),
        errorWidget: (_, __, ___) =>
            Container(color: PublicProfileTheme.panelOverlayColor),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: PublicProfileTheme.backgroundGradient,
      ),
    );
  }

  Widget _buildProfileAvatar(ProfileIdentity identity) {
    final hasImage = _hasMedia(identity.profilePictureUrl);
    final initials = _initialsFromName(identity.fullName);

    return CircleAvatar(
      radius: 48.r,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 44.r,
        backgroundColor:
            hasImage ? Colors.transparent : Colors.white.withOpacity(0.1),
        backgroundImage: hasImage
            ? CachedNetworkImageProvider(identity.profilePictureUrl)
            : null,
        child: hasImage
            ? null
            : Text(
                initials,
                style: TextStyles.font24WhiteBold,
              ),
      ),
    );
  }

  bool _hasMedia(String? value) => value != null && value.trim().isNotEmpty;

  String _initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    String initials = '';
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      initials += parts.first[0];
    }
    if (parts.length > 1 && parts.last.isNotEmpty) {
      initials += parts.last[0];
    }
    if (initials.isEmpty && trimmed.isNotEmpty) {
      initials = trimmed[0];
    }
    return initials.toUpperCase();
  }

  void _showHeroMediaOptions({required bool isCover}) {
    final identity = _identity;
    if (identity == null) return;
    final hasMedia = isCover
        ? _hasMedia(identity.coverMediaUrl)
        : _hasMedia(identity.profilePictureUrl);
    final mediaLabel = isCover ? 'background' : 'profile photo';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PublicProfileTheme.panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: Text(
                'Change $mediaLabel',
                style: TextStyles.font14White400Weight,
              ),
              onTap: () {
                Navigator.pop(context);
                _changeIdentityMedia(isCover: isCover);
              },
            ),
            if (hasMedia)
              ListTile(
                leading:
                    const Icon(Icons.visibility_outlined, color: Colors.white),
                title: Text(
                  'View $mediaLabel',
                  style: TextStyles.font14White400Weight,
                ),
                onTap: () {
                  Navigator.pop(context);
                  final url = isCover
                      ? identity.coverMediaUrl!
                      : identity.profilePictureUrl;
                  _viewIdentityMedia(url);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeIdentityMedia({required bool isCover}) async {
    final identity = _identity;
    if (identity == null) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() => _isHeroMediaUploading = true);
      final file = File(picked.path);
      final folder =
          'public_profiles/${identity.userId}/${isCover ? 'cover' : 'avatar'}';
      final uploadedUrl =
          await _cloudinaryService.uploadImage(file, folder: folder);

      await _service.updateProfileMedia(
        userId: identity.userId,
        profilePictureUrl: isCover ? null : uploadedUrl,
        coverMediaUrl: isCover ? uploadedUrl : null,
      );

      if (!isCover) {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await authUser.updatePhotoURL(uploadedUrl);
        }
        unawaited(
          CommunityService.updateUserProfileMedia(
            userId: identity.userId,
            profilePictureUrl: uploadedUrl,
            nickname: identity.fullName,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        if (isCover) {
          _identity = _identity?.copyWith(coverMediaUrl: uploadedUrl);
        } else {
          _identity = _identity?.copyWith(profilePictureUrl: uploadedUrl);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isCover ? 'Background' : 'Profile photo'} updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update image: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isHeroMediaUploading = false);
      }
    }
  }

  void _viewIdentityMedia(String url) {
    if (!_hasMedia(url)) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(24.w),
                child: const CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(24.w),
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _associationToJson(AssociationCardData association) {
    return {
      'id': association.id,
      'title': association.title,
      'subtitle': association.subtitle,
      'role': association.role,
      'imageUrl': association.imageUrl,
      'tags': association.tags,
      if (association.location != null) 'location': association.location,
      if (association.status != null) 'status': association.status,
      if (association.description != null)
        'description': association.description,
      if (association.since != null)
        'since': association.since!.toIso8601String(),
      if (association.ownerName != null) 'ownerName': association.ownerName,
      if (association.ownerId != null) 'ownerId': association.ownerId,
    };
  }

  List<ContactLink> _buildContactLinksFromMap(Map<String, String> links) {
    final result = <ContactLink>[];
    void add(String key, String label, IconData icon) {
      final value = links[key];
      if (value == null || value.isEmpty) return;
      result.add(
        ContactLink(
          key: key,
          label: label,
          icon: icon,
          url: value,
        ),
      );
    }

    add('instagram', 'Instagram', Icons.camera_alt_outlined);
    add('facebook', 'Facebook', Icons.facebook);
    add('snapchat', 'Snapchat', Icons.snapchat);
    add('youtube', 'YouTube', Icons.ondemand_video);
    return result;
  }

  SliverToBoxAdapter _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: PublicProfileTheme.panelGradient,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildProfileActions(),
                  ),
                  Gap(18.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 420.w;
                      return Wrap(
                        spacing: 16.w,
                        runSpacing: 16.h,
                        alignment: WrapAlignment.spaceBetween,
                        children: _stats
                            .map(
                              (stat) => _StatTile(
                                stat: stat,
                                width: isWide
                                    ? (constraints.maxWidth - 16.w * 3) / 4
                                    : constraints.maxWidth / 2 - 12.w,
                                onTap: _statTapHandler(stat),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    if (_isViewingOwnProfile) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: [
        _buildFollowButton(),
        _buildMessageButton(),
      ],
    );
  }

  Widget _buildFollowButton() {
    if (_isViewingOwnProfile) {
      return const SizedBox.shrink();
    }
    final isFollowing = _isFollowing;
    return ElevatedButton.icon(
      onPressed: () => _toggleFollow(),
      icon: Icon(
        isFollowing ? Icons.check : Icons.person_add_alt_1_outlined,
        color: Colors.black,
      ),
      label: Text(isFollowing ? 'Following' : 'Follow'),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor:
            isFollowing ? Colors.white : PublicProfileTheme.panelAccentColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    if (_isViewingOwnProfile) {
      return const SizedBox.shrink();
    }

    final bool isLoading = _isLaunchingChat;
    final Widget icon = isLoading
        ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Icon(
            Icons.chat_bubble_outline,
            color: PublicProfileTheme.panelAccentColor,
          );

    final String label = isLoading ? 'Opening...' : 'Message';

    return OutlinedButton.icon(
      onPressed: isLoading ? null : _handleMessageTap,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: PublicProfileTheme.panelAccentColor.withOpacity(0.8),
        ),
        backgroundColor: Colors.white.withOpacity(0.06),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
      ),
    );
  }

  // TABS ---------------------------------------------------------------------

  Widget _buildAboutTab() {
    final about = _about;
    final contact = _contactPreferences;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _SectionCard(
          title: 'Bio',
          child: Text(
            about?.bio ??
                'Add a short introduction that highlights your strengths and mindset.',
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: ColorsManager.textSecondary, height: 1.5),
          ),
        ),
        Gap(16.h),
        if (about != null) ...[
          _SectionCard(
            title: 'Quick facts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: about.attributes.entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyles.font14DarkBlue600Weight,
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyles.font14Grey400Weight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Gap(16.h),
          _SectionCard(
            title: 'Highlights',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: about.highlights
                  .map(
                    (highlight) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              highlight,
                              style: TextStyles.font14Grey400Weight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (contact != null) ...[
          Gap(16.h),
          _SectionCard(
            title: 'Contact & links',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.primaryActionLabel,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
                Gap(12.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: contact.links
                      .map(
                        (link) => ActionChip(
                          avatar: Icon(link.icon, size: 18.sp),
                          label: Text(link.label),
                          onPressed: () => _openExternalLink(link.url),
                        ),
                      )
                      .toList(),
                ),
                Gap(16.h),
                Row(
                  children: [
                    Icon(
                      contact.allowMessagesFromFriendsOnly
                          ? Icons.lock_person
                          : Icons.chat_bubble_outline,
                      color: PublicProfileTheme.panelAccentColor,
                    ),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        contact.allowMessagesFromFriendsOnly
                            ? 'Messages restricted to approved connections.'
                            : 'Open to new conversations and matchups.',
                        style: TextStyles.font12Grey400Weight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsTab() {
    final summary = _skillPerformance;
    if (summary == null) {
      return const Center(child: Text('No skill data available yet.'));
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < summary.recentTrends.length; i++) {
      spots.add(FlSpot(i.toDouble(), summary.recentTrends[i].value));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _SectionCard(
          title: 'Performance trend',
          child: SizedBox(
            height: 220.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < summary.recentTrends.length) {
                          return Text(
                            summary.recentTrends[index].label,
                            style: TextStyles.font10Grey400Weight,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    color: PublicProfileTheme.panelAccentColor,
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          PublicProfileTheme.panelAccentColor.withOpacity(0.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Gap(16.h),
        _SectionCard(
          title: 'Key metrics',
          child: Column(
            children: summary.skillMetrics
                .map(
                  (metric) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _SkillProgressTile(metric: metric),
                  ),
                )
                .toList(),
          ),
        ),
        Gap(16.h),
        _SectionCard(
          title: 'Achievements',
          child: Column(
            children: summary.achievements
                .map(
                  (achievement) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          PublicProfileTheme.panelAccentColor.withOpacity(0.2),
                      child: Icon(
                        achievement.icon,
                        color: PublicProfileTheme.panelAccentColor,
                      ),
                    ),
                    title: Text(
                      achievement.title,
                      style: TextStyles.font14DarkBlue600Weight,
                    ),
                    subtitle: Text(
                      achievement.subtitle,
                      style: TextStyles.font12Grey400Weight,
                    ),
                    trailing: Text(
                      '${achievement.date.day}/${achievement.date.month}/${achievement.date.year}',
                      style: TextStyles.font10Grey400Weight,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _AssociationSection(
          title: 'Teams',
          description:
              'Squads I currently represent or have been invited to guest for.',
          items: _teams,
          onItemTap: (item) => DetailNavigator.openTeam(
            context,
            teamId: item.id,
          ),
        ),
        Gap(20.h),
        _AssociationSection(
          title: 'Tournaments',
          description: 'Competitive stages showcasing recent form.',
          items: _tournaments,
          onItemTap: (item) => DetailNavigator.openTournament(
            context,
            tournamentId: item.id,
          ),
        ),
      ],
    );
  }

  Widget _buildVenuesTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        _AssociationSection(
          title: 'Venues & check-ins',
          description:
              'High-performance facilities and training grounds I trust.',
          items: _venues,
          onItemTap: (item) => DetailNavigator.openVenue(
            context,
            venueId: item.id,
          ),
        ),
        Gap(20.h),
        _AssociationSection(
          title: 'Coaching network',
          description:
              'Mentors and specialists guiding my physical and mental game.',
          items: _coaches,
          onItemTap: (item) => DetailNavigator.openCoach(
            context,
            coachId: item.id,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityTab() {
    if (_posts.isEmpty) {
      return const Center(child: Text('No community posts yet.'));
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return CommunityPostCard(
          post: post,
          onTap: () => _openCommunityPostDetail(post),
          onLike: (isLike) => _toggleCommunityReaction(post, isLike),
          onComment: () => _openCommunityPostDetail(post),
          onUserTap: () => _openCommunityAuthorProfile(post.authorId),
          onMoreOptions: () => _handleCommunityPostOptions(post),
          hasLiked: _postLikeStatuses[post.id]?.hasLiked,
          hasDisliked: _postLikeStatuses[post.id]?.hasDisliked,
        );
      },
      separatorBuilder: (_, __) => Gap(16.h),
      itemCount: _posts.length,
    );
  }

  Widget _buildMatchmakingTab() {
    final matchmaking = _matchmaking;
    if (matchmaking == null) {
      return const Center(child: Text('Matchmaking profile not configured.'));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        if (_matchmakingImages.isNotEmpty)
          SizedBox(
            height: 260.h,
            child: PageView.builder(
              controller: _carouselController,
              onPageChanged: (index) => setState(() => _carouselIndex = index),
              itemCount: _matchmakingImages.length,
              itemBuilder: (context, index) {
                final image = _matchmakingImages[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: PublicProfileTheme.panelOverlayColor),
                      errorWidget: (_, __, ___) => Container(
                          color: PublicProfileTheme.panelOverlayColor),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_matchmakingImages.isNotEmpty) ...[
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _matchmakingImages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 6.h,
                width: index == _carouselIndex ? 26.w : 8.w,
                decoration: BoxDecoration(
                  color: index == _carouselIndex
                      ? PublicProfileTheme.panelAccentColor
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
        Gap(16.h),
        _SectionCard(
          title: matchmaking.tagline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matchmaking.about,
                style: TextStyles.font14Grey400Weight.copyWith(height: 1.5),
              ),
              Gap(12.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pin_drop_outlined,
                          color: PublicProfileTheme.panelAccentColor),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          '${matchmaking.city} • ${matchmaking.age} yrs',
                          style: TextStyles.font12Grey400Weight,
                        ),
                      ),
                    ],
                  ),
                  if (matchmaking.distanceKm != null) ...[
                    Gap(8.h),
                    Row(
                      children: [
                        Icon(Icons.map_outlined,
                            color: PublicProfileTheme.panelAccentColor),
                        Gap(4.w),
                        Expanded(
                          child: Text(
                            '${matchmaking.distanceKm!.toStringAsFixed(1)} km away',
                            style: TextStyles.font12Grey400Weight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Gap(16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: matchmaking.sports
                    .map(
                      (sport) => Chip(
                        label: Text(sport),
                        backgroundColor: PublicProfileTheme.panelAccentColor
                            .withOpacity(0.22),
                        labelStyle: TextStyles.font12DarkBlue600Weight.copyWith(
                            color: PublicProfileTheme.panelAccentColor),
                      ),
                    )
                    .toList(),
              ),
              if (matchmaking.seeking.isNotEmpty) ...[
                Gap(16.h),
                Text(
                  'Looking for',
                  style: TextStyles.font12Grey400Weight
                      .copyWith(color: Colors.white),
                ),
                Gap(8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: matchmaking.seeking
                      .map(
                        (item) => Chip(
                          label: Text(item),
                          backgroundColor: Colors.white.withOpacity(0.12),
                          labelStyle: TextStyles.font12Grey400Weight
                              .copyWith(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (matchmaking.distanceLink != null &&
                  matchmaking.distanceLink!.isNotEmpty) ...[
                Gap(16.h),
                InkWell(
                  onTap: () => _openExternalLink(matchmaking.distanceLink!),
                  child: Row(
                    children: [
                      Icon(Icons.link,
                          color: PublicProfileTheme.panelAccentColor),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          'Open distance link',
                          style: TextStyles.font12DarkBlue600Weight.copyWith(
                              color: PublicProfileTheme.panelAccentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Gap(16.h),
        _SectionCard(
          title: 'Featured links',
          child: Column(
            children: [
              if (matchmaking.featuredTeam != null)
                _MiniAssociationTile(
                  title: 'Featured team',
                  data: matchmaking.featuredTeam!,
                ),
              if (matchmaking.featuredVenue != null) Gap(10.h),
              if (matchmaking.featuredVenue != null)
                _MiniAssociationTile(
                  title: 'Preferred venue',
                  data: matchmaking.featuredVenue!,
                ),
              if (matchmaking.featuredCoach != null) Gap(10.h),
              if (matchmaking.featuredCoach != null)
                _MiniAssociationTile(
                  title: 'Primary coach',
                  data: matchmaking.featuredCoach!,
                ),
              if (matchmaking.featuredTournament != null) Gap(10.h),
              if (matchmaking.featuredTournament != null)
                _MiniAssociationTile(
                  title: 'Upcoming tournament',
                  data: matchmaking.featuredTournament!,
                ),
            ],
          ),
        ),
        Gap(24.h),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, Routes.playerMatchmakingScreen),
          icon: const Icon(Icons.swipe),
          label: const Text('Swipe to challenge'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PublicProfileTheme.panelAccentColor,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        FilledButton.icon(
          onPressed: _handleAddReview,
          style: FilledButton.styleFrom(
            backgroundColor: PublicProfileTheme.panelAccentColor,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Add review'),
        ),
        Gap(20.h),
        if (_reviews.isEmpty)
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No reviews yet',
                  style: TextStyles.font14DarkBlue600Weight
                      .copyWith(color: Colors.white),
                ),
                Gap(8.h),
                Text(
                  'Be the first to share feedback about this profile.',
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          )
        else
          ..._reviews.map(
            (review) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _ReviewTile(review: review),
            ),
          ),
      ],
    );
  }

  // ACTIONS ------------------------------------------------------------------

  Widget _buildFloatingButton() {
    final isOwnProfile = _isViewingOwnProfile;

    if (isOwnProfile) {
      return FloatingActionButton.extended(
        onPressed: _shareProfile,
        backgroundColor: PublicProfileTheme.panelAccentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.share),
        label: const Text('Share profile'),
      );
    }

    // Message FAB removed - user doesn't want it to show on mutual follow
    return const SizedBox.shrink();
  }

  Future<void> _handleAddReview() async {
    final profileIdentity = _identity;
    if (profileIdentity == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to leave a review.'),
          ),
        );
      }
      return;
    }

    final result = await showDialog<_ReviewFormResult>(
      context: context,
      builder: (context) => _AddReviewDialog(
        reviewerName: (currentUser.displayName?.trim().isNotEmpty ?? false)
            ? currentUser.displayName!.trim()
            : 'Anonymous player',
        reviewerAvatarUrl: currentUser.photoURL,
      ),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();
    final review = ReviewEntry(
      id: 'review_${now.millisecondsSinceEpoch}',
      authorName: result.reviewerName ??
          (currentUser.displayName?.trim().isNotEmpty ?? false
              ? currentUser.displayName!.trim()
              : 'Anonymous player'),
      authorAvatarUrl: currentUser.photoURL ?? '',
      rating: result.rating.toDouble(),
      comment: result.comment,
      relationship: result.relationship,
      createdAt: now,
    );

    try {
      await _service.addProfileReview(
        profileUserId: profileIdentity.userId,
        reviewerId: currentUser.uid,
        review: review,
      );

      setState(() {
        _reviews = [review, ..._reviews];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $error'),
        ),
      );
    }
  }

  void _handleConnect() {
    if (!_canMessageViewer) {
      _showMessageRestriction();
      return;
    }
    Navigator.pushNamed(context, Routes.chatListScreen);
  }

  void _shareProfile() {
    final profileUrl = _shareUrl;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                gradient: PublicProfileTheme.panelGradient,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share profile',
                      style: TextStyles.font16DarkBlue600Weight
                          .copyWith(color: Colors.white),
                    ),
                    Gap(16.h),
                    ListTile(
                      leading: Icon(Icons.share,
                          color: PublicProfileTheme.panelAccentColor),
                      title: Text(
                        'Share link',
                        style: TextStyles.font14DarkBlue600Weight
                            .copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        profileUrl,
                        style: TextStyles.font12Grey400Weight,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Share.share(
                          'Check out ${_identity?.fullName} on PlayAround: $profileUrl',
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.qr_code,
                          color: PublicProfileTheme.panelAccentColor),
                      title: Text(
                        'Show QR code',
                        style: TextStyles.font14DarkBlue600Weight
                            .copyWith(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showQrCode(profileUrl);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQrCode(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PublicProfileTheme.panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Text(
            'Scan to view profile',
            style: TextStyles.font16DarkBlue600Weight,
          ),
          content: SizedBox(
            width: 240.w,
            height: 260.h,
            child: Column(
              children: [
                Expanded(
                  child: QrImageView(
                    data: url,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                Gap(12.h),
                Text(
                  url,
                  style: TextStyles.font10Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAdminPanel() async {
    if (!_isViewingOwnProfile) {
      _openViewerActions();
      return;
    }
    final identity = _identity;
    final about = _about;
    if (identity == null || about == null) return;

    final matchmaking = _matchmaking ??
        MatchmakingShowcase(
          tagline: '',
          about: '',
          images: const [],
          age: identity.age,
          city: identity.city,
          sports: const [],
          seeking: const [],
          distanceKm: null,
          distanceLink: null,
          featuredTeam: null,
          featuredVenue: null,
          featuredCoach: null,
          featuredTournament: null,
          allowMessagesFromFriendsOnly: false,
        );

    final taglineController = TextEditingController(text: identity.tagline);
    final statusController =
        TextEditingController(text: about.statusMessage ?? '');
    final bioController = TextEditingController(text: about.bio);
    final matchmakingTaglineController =
        TextEditingController(text: matchmaking.tagline);
    final matchmakingAboutController =
        TextEditingController(text: matchmaking.about);
    final matchmakingCityController =
        TextEditingController(text: matchmaking.city);
    final matchmakingAgeController =
        TextEditingController(text: matchmaking.age.toString());
    final matchmakingSportsController =
        TextEditingController(text: matchmaking.sports.join(', '));
    final matchmakingSeekingController =
        TextEditingController(text: matchmaking.seeking.join(', '));
    final matchmakingDistanceController = TextEditingController(
      text: matchmaking.distanceKm != null
          ? matchmaking.distanceKm!.toString()
          : '',
    );
    final matchmakingDistanceLinkController =
        TextEditingController(text: matchmaking.distanceLink ?? '');
    final quickFactFields = about.attributes.entries
        .map(
          (entry) => _QuickFactField(
            key: entry.key,
            value: entry.value,
          ),
        )
        .toList();
    if (quickFactFields.isEmpty) {
      quickFactFields.add(_QuickFactField());
    }
    final highlightControllers = about.highlights
        .map((highlight) => TextEditingController(text: highlight))
        .toList();
    if (highlightControllers.isEmpty) {
      highlightControllers.add(TextEditingController());
    }
    final contact = _contactPreferences;
    final existingLinks = contact?.links ?? const <ContactLink>[];
    String resolveLink(String key) {
      final normalizedKey = key.toLowerCase();
      for (final link in existingLinks) {
        final normalized =
            (link.key ?? link.label).toLowerCase().replaceAll(' ', '');
        if (normalized == normalizedKey) {
          return link.url;
        }
      }
      return '';
    }

    final instagramController =
        TextEditingController(text: resolveLink('instagram'));
    final facebookController =
        TextEditingController(text: resolveLink('facebook'));
    final snapchatController =
        TextEditingController(text: resolveLink('snapchat'));
    final youtubeController =
        TextEditingController(text: resolveLink('youtube'));

    final contactLabel = contact?.primaryActionLabel ?? 'Start chat';

    bool allowMessages = contact?.allowMessagesFromFriendsOnly ??
        matchmaking.allowMessagesFromFriendsOnly;
    List<String> tempMatchmakingImages = _matchmakingImages.isNotEmpty
        ? List<String>.from(_matchmakingImages)
        : List<String>.from(matchmaking.images);
    String teamsSearch = '';
    String tournamentsSearch = '';
    String venuesSearch = '';
    String coachesSearch = '';
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void addQuickFact() {
              setSheetState(() {
                quickFactFields.add(_QuickFactField());
              });
            }

            void removeQuickFact(int index) {
              if (index < 0 || index >= quickFactFields.length) return;
              final removed = quickFactFields[index];
              setSheetState(() {
                quickFactFields.removeAt(index);
                if (quickFactFields.isEmpty) {
                  quickFactFields.add(_QuickFactField());
                }
              });
              removed.dispose();
            }

            void addHighlight() {
              setSheetState(() {
                highlightControllers.add(TextEditingController());
              });
            }

            void removeHighlight(int index) {
              if (index < 0 || index >= highlightControllers.length) return;
              final controller = highlightControllers[index];
              setSheetState(() {
                highlightControllers.removeAt(index);
                if (highlightControllers.isEmpty) {
                  highlightControllers.add(TextEditingController());
                }
              });
              controller.dispose();
            }

            return DraggableScrollableSheet(
              maxChildSize: 0.92,
              initialChildSize: 0.88,
              minChildSize: 0.65,
              builder: (context, controller) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: PublicProfileTheme.panelGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 28,
                        offset: const Offset(0, -14),
                      ),
                    ],
                  ),
                  child: DefaultTabController(
                    length: 7,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 56.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              ),
                              Gap(12.h),
                              Text(
                                'Public profile admin',
                                style: TextStyles.font18DarkBlueBold,
                              ),
                              Gap(4.h),
                              Text(
                                'Select what appears on your public profile, matchmaking card, and activity feed.',
                                style: TextStyles.font12Grey400Weight,
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                          isScrollable: true,
                          labelStyle: TextStyles.font14DarkBlue600Weight
                              .copyWith(
                                  color: PublicProfileTheme.panelAccentColor),
                          unselectedLabelStyle: TextStyles.font14Grey400Weight
                              .copyWith(color: Colors.white.withOpacity(0.6)),
                          labelColor: PublicProfileTheme.panelAccentColor,
                          unselectedLabelColor: Colors.white.withOpacity(0.6),
                          indicatorColor: PublicProfileTheme.panelAccentColor,
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Teams'),
                            Tab(text: 'Tournaments'),
                            Tab(text: 'Venues'),
                            Tab(text: 'Coaches'),
                            Tab(text: 'Posts'),
                            Tab(text: 'Matchmaking'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAdminOverviewTab(
                                controller: controller,
                                taglineController: taglineController,
                                bioController: bioController,
                                statusController: statusController,
                                allowMessages: allowMessages,
                                onAllowMessagesChanged: (value) {
                                  setSheetState(() => allowMessages = value);
                                },
                                instagramController: instagramController,
                                facebookController: facebookController,
                                snapchatController: snapchatController,
                                youtubeController: youtubeController,
                                quickFactFields: quickFactFields,
                                onAddQuickFact: addQuickFact,
                                onRemoveQuickFact: removeQuickFact,
                                highlightControllers: highlightControllers,
                                onAddHighlight: addHighlight,
                                onRemoveHighlight: removeHighlight,
                              ),
                              _AdminAssociationsTab(
                                key: const ValueKey('admin-teams'),
                                controller: controller,
                                title: 'Curate featured teams',
                                searchPlaceholder: 'Type team name',
                                available:
                                    _availableAssociations['teams'] ?? const [],
                                selectedIds: _selectedTeamIds,
                                selectedAssociations: _teams,
                                initialQuery: teamsSearch,
                                onQueryChanged: (value) => teamsSearch = value,
                                onSearch: _searchTeamAssociations,
                                emptyLabel:
                                    'No teams available yet. Search to send requests.',
                                onToggle: (association, isSelected) async {
                                  final approvedAssociations =
                                      _availableAssociations['teams'] ??
                                          const [];
                                  final isApproved = approvedAssociations
                                      .any((item) => item.id == association.id);

                                  if (isSelected && !isApproved) {
                                    final success = await _submitAssociationRequest(
                                      association,
                                      'team',
                                    );
                                    if (mounted && success) {
                                      // Add to selected list after successful request (but NOT to available - it's pending)
                                      setState(() {
                                        if (_selectedTeamIds.add(association.id)) {
                                          _teams.add(association);
                                          // Don't call _cacheAssociation here - it should only be in selectedIds, not available
                                        }
                                      });
                                      setSheetState(() {});
                                    } else if (mounted) {
                                      setState(() {});
                                      setSheetState(() {});
                                    }
                                    return;
                                  }

                                  setState(() {
                                    if (isSelected) {
                                      if (_selectedTeamIds
                                          .add(association.id)) {
                                        _teams.add(association);
                                        _cacheAssociation(
                                          'teams',
                                          association,
                                        );
                                      }
                                    } else {
                                      _selectedTeamIds.remove(association.id);
                                      _teams.removeWhere(
                                          (item) => item.id == association.id);
                                    }
                                  });
                                  setSheetState(() {});
                                  if (isSelected) {
                                    await _announceAssociationUpdate(
                                      type: 'team',
                                      association: association,
                                    );
                                  }
                                },
                              ),
                              _AdminAssociationsTab(
                                key: const ValueKey('admin-tournaments'),
                                controller: controller,
                                title: 'Highlight tournaments',
                                searchPlaceholder: 'Type tournament name',
                                available:
                                    _availableAssociations['tournaments'] ??
                                        const [],
                                selectedIds: _selectedTournamentIds,
                                selectedAssociations: _tournaments,
                                initialQuery: tournamentsSearch,
                                onQueryChanged: (value) =>
                                    tournamentsSearch = value,
                                onSearch: _searchTournamentAssociations,
                                emptyLabel:
                                    'No tournaments available yet. Search to send requests.',
                                onToggle: (association, isSelected) async {
                                  final approvedAssociations =
                                      _availableAssociations['tournaments'] ??
                                          const [];
                                  final isApproved = approvedAssociations
                                      .any((item) => item.id == association.id);

                                  if (isSelected && !isApproved) {
                                    final success = await _submitAssociationRequest(
                                      association,
                                      'tournament',
                                    );
                                    if (mounted && success) {
                                      // Add to selected list after successful request (but NOT to available - it's pending)
                                      setState(() {
                                        if (_selectedTournamentIds.add(association.id)) {
                                          _tournaments.add(association);
                                          // Don't call _cacheAssociation here - it should only be in selectedIds, not available
                                        }
                                      });
                                      setSheetState(() {});
                                    } else if (mounted) {
                                      setState(() {});
                                      setSheetState(() {});
                                    }
                                    return;
                                  }

                                  setState(() {
                                    if (isSelected) {
                                      if (_selectedTournamentIds
                                          .add(association.id)) {
                                        _tournaments.add(association);
                                        _cacheAssociation(
                                          'tournaments',
                                          association,
                                        );
                                      }
                                    } else {
                                      _selectedTournamentIds
                                          .remove(association.id);
                                      _tournaments.removeWhere(
                                          (item) => item.id == association.id);
                                    }
                                  });
                                  setSheetState(() {});
                                  if (isSelected) {
                                    await _announceAssociationUpdate(
                                      type: 'tournament',
                                      association: association,
                                    );
                                  }
                                },
                              ),
                              _AdminAssociationsTab(
                                key: const ValueKey('admin-venues'),
                                controller: controller,
                                title: 'Venues & check-ins',
                                searchPlaceholder: 'Type venue name',
                                available: _availableAssociations['venues'] ??
                                    const [],
                                selectedIds: _selectedVenueIds,
                                selectedAssociations: _venues,
                                initialQuery: venuesSearch,
                                onQueryChanged: (value) => venuesSearch = value,
                                onSearch: _searchVenueAssociations,
                                emptyLabel:
                                    'No venues available yet. Search to send requests.',
                                onToggle: (association, isSelected) async {
                                  final approvedAssociations =
                                      _availableAssociations['venues'] ??
                                          const [];
                                  final isApproved = approvedAssociations
                                      .any((item) => item.id == association.id);

                                  if (isSelected && !isApproved) {
                                    final success = await _submitAssociationRequest(
                                      association,
                                      'venue',
                                    );
                                    if (mounted && success) {
                                      // Add to selected list after successful request (but NOT to available - it's pending)
                                      setState(() {
                                        if (_selectedVenueIds.add(association.id)) {
                                          _venues.add(association);
                                          // Don't call _cacheAssociation here - it should only be in selectedIds, not available
                                        }
                                      });
                                      setSheetState(() {});
                                    } else if (mounted) {
                                      setState(() {});
                                      setSheetState(() {});
                                    }
                                    return;
                                  }

                                  setState(() {
                                    if (isSelected) {
                                      if (_selectedVenueIds
                                          .add(association.id)) {
                                        _venues.add(association);
                                        _cacheAssociation(
                                          'venues',
                                          association,
                                        );
                                      }
                                    } else {
                                      _selectedVenueIds.remove(association.id);
                                      _venues.removeWhere(
                                          (item) => item.id == association.id);
                                    }
                                  });
                                  setSheetState(() {});
                                  if (isSelected) {
                                    await _announceAssociationUpdate(
                                      type: 'venue',
                                      association: association,
                                    );
                                  }
                                },
                              ),
                              _AdminAssociationsTab(
                                key: const ValueKey('admin-coaches'),
                                controller: controller,
                                title: 'Coaching network',
                                searchPlaceholder: 'Type coach name',
                                available: _availableAssociations['coaches'] ??
                                    const [],
                                selectedIds: _selectedCoachIds,
                                selectedAssociations: _coaches,
                                initialQuery: coachesSearch,
                                onQueryChanged: (value) =>
                                    coachesSearch = value,
                                onSearch: _searchCoachAssociations,
                                emptyLabel:
                                    'No coaches available yet. Search to send requests.',
                                onToggle: (association, isSelected) async {
                                  final approvedAssociations =
                                      _availableAssociations['coaches'] ??
                                          const [];
                                  final isApproved = approvedAssociations
                                      .any((item) => item.id == association.id);

                                  if (isSelected && !isApproved) {
                                    final success = await _submitAssociationRequest(
                                      association,
                                      'coach',
                                    );
                                    if (mounted && success) {
                                      // Add to selected list after successful request (but NOT to available - it's pending)
                                      setState(() {
                                        if (_selectedCoachIds.add(association.id)) {
                                          _coaches.add(association);
                                          // Don't call _cacheAssociation here - it should only be in selectedIds, not available
                                        }
                                      });
                                      setSheetState(() {});
                                    } else if (mounted) {
                                      setState(() {});
                                      setSheetState(() {});
                                    }
                                    return;
                                  }

                                  setState(() {
                                    if (isSelected) {
                                      if (_selectedCoachIds
                                          .add(association.id)) {
                                        _coaches.add(association);
                                        _cacheAssociation(
                                          'coaches',
                                          association,
                                        );
                                      }
                                    } else {
                                      _selectedCoachIds.remove(association.id);
                                      _coaches.removeWhere(
                                          (item) => item.id == association.id);
                                    }
                                  });
                                  setSheetState(() {});
                                  if (isSelected) {
                                    await _announceAssociationUpdate(
                                      type: 'coach',
                                      association: association,
                                    );
                                  }
                                },
                              ),
                              _buildAdminPostsTab(
                                controller: controller,
                                selectedPostIds: _selectedPostIds,
                                onToggle: (post, isSelected) {
                                  setSheetState(() {
                                    if (isSelected) {
                                      _selectedPostIds.add(post.id);
                                      if (!_posts.any((p) => p.id == post.id)) {
                                        _posts.add(post);
                                      }
                                    } else {
                                      _selectedPostIds.remove(post.id);
                                      _posts
                                          .removeWhere((p) => p.id == post.id);
                                    }
                                  });
                                },
                              ),
                              _buildAdminMatchmakingTab(
                                controller: controller,
                                allowMessages: allowMessages,
                                onAllowMessagesChanged: (value) {
                                  setSheetState(() => allowMessages = value);
                                },
                                onUploadImage: () async {
                                  await _uploadMatchmakingImage();
                                  setSheetState(() {
                                    tempMatchmakingImages =
                                        List<String>.from(_matchmakingImages);
                                  });
                                },
                                onSelectLibraryImage: (url) {
                                  setSheetState(() {
                                    if (tempMatchmakingImages.contains(url)) {
                                      tempMatchmakingImages =
                                          tempMatchmakingImages
                                              .where((item) => item != url)
                                              .toList();
                                    } else if (tempMatchmakingImages.length <
                                        5) {
                                      tempMatchmakingImages = [
                                        ...tempMatchmakingImages,
                                        url,
                                      ];
                                    }
                                  });
                                },
                                onRemoveImage: (image) {
                                  setSheetState(() {
                                    tempMatchmakingImages =
                                        tempMatchmakingImages
                                            .where((item) => item != image)
                                            .toList();
                                  });
                                },
                                images: tempMatchmakingImages,
                                taglineController: matchmakingTaglineController,
                                aboutController: matchmakingAboutController,
                                cityController: matchmakingCityController,
                                ageController: matchmakingAgeController,
                                sportsController: matchmakingSportsController,
                                seekingController: matchmakingSeekingController,
                                distanceController:
                                    matchmakingDistanceController,
                                distanceLinkController:
                                    matchmakingDistanceLinkController,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final updatedAge = int.tryParse(
                                          matchmakingAgeController.text.trim());
                                      final updatedCity =
                                          matchmakingCityController.text.trim();
                                      final updatedCityValue =
                                          updatedCity.isNotEmpty
                                              ? updatedCity
                                              : identity.city;
                                      final updatedSports = _parseListInput(
                                          matchmakingSportsController.text);
                                      final updatedSeeking = _parseListInput(
                                          matchmakingSeekingController.text);
                                      final updatedDistance = double.tryParse(
                                          matchmakingDistanceController.text
                                              .trim());
                                      final distanceLinkRaw =
                                          matchmakingDistanceLinkController.text
                                              .trim();
                                      final updatedImages = List<String>.from(
                                          tempMatchmakingImages);

                                      final instagramUrl =
                                          instagramController.text.trim();
                                      final facebookUrl =
                                          facebookController.text.trim();
                                      final snapchatUrl =
                                          snapchatController.text.trim();
                                      final youtubeUrl =
                                          youtubeController.text.trim();

                                      final updatedQuickFacts =
                                          <String, String>{};
                                      for (final field in quickFactFields) {
                                        final key =
                                            field.keyController.text.trim();
                                        final value =
                                            field.valueController.text.trim();
                                        if (key.isEmpty || value.isEmpty) {
                                          continue;
                                        }
                                        updatedQuickFacts[key] = value;
                                      }

                                      final updatedHighlights =
                                          highlightControllers
                                              .map((controller) =>
                                                  controller.text.trim())
                                              .where((text) => text.isNotEmpty)
                                              .toList();

                                      final socialLinksMap = <String, String>{
                                        'instagram': instagramUrl,
                                        'facebook': facebookUrl,
                                        'snapchat': snapchatUrl,
                                        'youtube': youtubeUrl,
                                      }..removeWhere(
                                          (key, value) => value.isEmpty,
                                        );

                                      final updatedContactLinks =
                                          _buildContactLinksFromMap(
                                              socialLinksMap);

                                      setSheetState(() => isSaving = true);

                                      setState(() {
                                        _identity = identity.copyWith(
                                          tagline:
                                              taglineController.text.trim(),
                                          city: updatedCityValue,
                                          age: updatedAge ?? identity.age,
                                        );
                                        _about = about.copyWith(
                                          bio: bioController.text.trim(),
                                          attributes: updatedQuickFacts,
                                          highlights: updatedHighlights,
                                          statusMessage:
                                              statusController.text.trim(),
                                        );
                                        _matchmakingImages = updatedImages;
                                        _matchmaking = matchmaking.copyWith(
                                          tagline: matchmakingTaglineController
                                              .text
                                              .trim(),
                                          about: matchmakingAboutController.text
                                              .trim(),
                                          city: updatedCityValue,
                                          age: updatedAge ?? matchmaking.age,
                                          sports: updatedSports.isNotEmpty
                                              ? updatedSports
                                              : matchmaking.sports,
                                          seeking: updatedSeeking.isNotEmpty
                                              ? updatedSeeking
                                              : matchmaking.seeking,
                                          distanceKm: updatedDistance ??
                                              matchmaking.distanceKm,
                                          distanceLink: distanceLinkRaw.isEmpty
                                              ? null
                                              : distanceLinkRaw,
                                          allowMessagesFromFriendsOnly:
                                              allowMessages,
                                          images: updatedImages,
                                        );
                                        _contactPreferences =
                                            ContactPreferences(
                                          primaryActionLabel: contactLabel,
                                          links: updatedContactLinks,
                                          allowMessagesFromFriendsOnly:
                                              allowMessages,
                                        );
                                      });

                                      final payload = {
                                        'identity': {
                                          'tagline': _identity?.tagline ?? '',
                                          'city': _identity?.city ?? '',
                                          'age': _identity?.age ?? identity.age,
                                        },
                                        'about': {
                                          'bio': _about?.bio ?? '',
                                          'statusMessage':
                                              _about?.statusMessage ?? '',
                                          'attributes': updatedQuickFacts,
                                          'highlights': updatedHighlights,
                                        },
                                        'contact': {
                                          'primaryActionLabel': contactLabel,
                                          'allowMessagesFromFriendsOnly':
                                              allowMessages,
                                          'links': socialLinksMap,
                                        },
                                        'matchmaking': {
                                          'tagline':
                                              _matchmaking?.tagline ?? '',
                                          'about': _matchmaking?.about ?? '',
                                          'city': _matchmaking?.city ?? '',
                                          'age': _matchmaking?.age ?? 0,
                                          'sports': _matchmaking?.sports ?? [],
                                          'seeking':
                                              _matchmaking?.seeking ?? [],
                                          'distanceKm':
                                              _matchmaking?.distanceKm,
                                          'distanceLink':
                                              _matchmaking?.distanceLink,
                                          'allowMessagesFromFriendsOnly':
                                              _matchmaking
                                                      ?.allowMessagesFromFriendsOnly ??
                                                  allowMessages,
                                          'images': updatedImages,
                                        },
                                        'associations': {
                                          'teams': _teams
                                              .map(_associationToJson)
                                              .toList(),
                                          'tournaments': _tournaments
                                              .map(_associationToJson)
                                              .toList(),
                                          'venues': _venues
                                              .map(_associationToJson)
                                              .toList(),
                                          'coaches': _coaches
                                              .map(_associationToJson)
                                              .toList(),
                                        },
                                        'featuredPostIds':
                                            _selectedPostIds.toList(),
                                      };

                                      try {
                                        await _service.updateProfileFields(
                                          identity.userId,
                                          payload,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Profile changes saved'),
                                          ),
                                        );
                                      } catch (error) {
                                        if (!mounted) return;
                                        setSheetState(() => isSaving = false);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to save changes: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                backgroundColor:
                                    PublicProfileTheme.panelAccentColor,
                                foregroundColor: Colors.black,
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save changes'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    taglineController.dispose();
    bioController.dispose();
    statusController.dispose();
    matchmakingTaglineController.dispose();
    matchmakingAboutController.dispose();
    matchmakingCityController.dispose();
    matchmakingAgeController.dispose();
    matchmakingSportsController.dispose();
    matchmakingSeekingController.dispose();
    matchmakingDistanceController.dispose();
    matchmakingDistanceLinkController.dispose();
    instagramController.dispose();
    facebookController.dispose();
    snapchatController.dispose();
    youtubeController.dispose();
    for (final field in quickFactFields) {
      field.dispose();
    }
    for (final controller in highlightControllers) {
      controller.dispose();
    }
  }

  void _openViewerActions() {
    final identity = _identity;
    if (identity == null || _isViewingOwnProfile) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                gradient: PublicProfileTheme.panelGradient,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.block, color: ColorsManager.error),
                    title: Text(
                      'Block user',
                      style: TextStyles.font14DarkBlue600Weight
                          .copyWith(color: ColorsManager.error),
                    ),
                    subtitle: Text(
                      'Stop seeing posts and messages from this user.',
                      style: TextStyles.font12Grey400Weight,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmBlockUser(identity.userId);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined,
                        color: ColorsManager.textSecondary),
                    title: Text(
                      'Report user',
                      style: TextStyles.font14DarkBlue600Weight
                          .copyWith(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Let our moderation team review this profile.',
                      style: TextStyles.font12Grey400Weight,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _reportUser(identity.userId);
                    },
                  ),
                  const Gap(12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmBlockUser(String targetUserId) async {
    final viewerId = FirebaseAuth.instance.currentUser?.uid;
    if (viewerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to block users.')),
      );
      return;
    }

    if (viewerId == targetUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot block your own profile.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Block user',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Blocking hides this user\'s posts and messages. You can unblock them later from settings.',
          style: TextStyle(color: ColorsManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Block',
              style: TextStyle(color: ColorsManager.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _blockUser(targetUserId);
    }
  }

  Future<void> _blockUser(String targetUserId) async {
    final viewer = FirebaseAuth.instance.currentUser;
    if (viewer == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('user_blocks')
          .doc(viewer.uid)
          .collection('blocked')
          .doc(targetUserId)
          .set({
        'blockedUserId': targetUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User blocked. You will no longer see their updates.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $error')),
      );
    }
  }

  Future<void> _reportUser(String targetUserId) async {
    final viewer = FirebaseAuth.instance.currentUser;
    if (viewer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report users.')),
      );
      return;
    }

    if (viewer.uid == targetUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot report your own profile.')),
      );
      return;
    }

    final reason = await _promptReportReason();
    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('user_reports').add({
        'targetUserId': targetUserId,
        'reporterUserId': viewer.uid,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Our team will review it shortly.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $error')),
      );
    }
  }

  Future<String?> _promptReportReason() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Report user',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Describe the issue...',
              hintStyle: TextStyle(color: ColorsManager.textSecondary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a reason.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _confirmLogout() async {
    if (!_isViewingOwnProfile) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Sign out?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You will need to sign in again to access your profile.',
          style: TextStyle(color: ColorsManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: ColorsManager.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.loginScreen,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $error')),
      );
    }
  }

  Widget _buildAdminOverviewTab({
    required ScrollController controller,
    required TextEditingController taglineController,
    required TextEditingController bioController,
    required TextEditingController statusController,
    required bool allowMessages,
    required ValueChanged<bool> onAllowMessagesChanged,
    required TextEditingController instagramController,
    required TextEditingController facebookController,
    required TextEditingController snapchatController,
    required TextEditingController youtubeController,
    required List<_QuickFactField> quickFactFields,
    required VoidCallback onAddQuickFact,
    required void Function(int index) onRemoveQuickFact,
    required List<TextEditingController> highlightControllers,
    required VoidCallback onAddHighlight,
    required void Function(int index) onRemoveHighlight,
  }) {
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: taglineController,
            decoration: const InputDecoration(
              labelText: 'Headline / tagline',
              hintText: 'e.g. Captain • Thunder FC | MVP 2024',
            ),
          ),
          Gap(16.h),
          TextField(
            controller: statusController,
            decoration: const InputDecoration(
              labelText: 'Availability status',
            ),
          ),
          Gap(16.h),
          TextField(
            controller: bioController,
            decoration: const InputDecoration(
              labelText: 'Public bio',
            ),
            maxLines: 5,
          ),
          Gap(16.h),
          SwitchListTile(
            value: allowMessages,
            onChanged: onAllowMessagesChanged,
            title: const Text('Lock My Profile'),
            subtitle: const Text(
              'When enabled, only approved connections can view full profile & start a chat.',
            ),
          ),
          Gap(24.h),
          Text(
            'Social links',
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(12.h),
          _buildSocialLinkField(
            controller: instagramController,
            label: 'Instagram',
            hint: 'https://instagram.com/yourhandle',
            icon: Icons.camera_alt_outlined,
          ),
          Gap(12.h),
          _buildSocialLinkField(
            controller: facebookController,
            label: 'Facebook',
            hint: 'https://facebook.com/yourpage',
            icon: Icons.facebook,
          ),
          Gap(12.h),
          _buildSocialLinkField(
            controller: snapchatController,
            label: 'Snapchat',
            hint: 'https://snapchat.com/add/yourname',
            icon: Icons.chat_bubble_outline,
          ),
          Gap(12.h),
          _buildSocialLinkField(
            controller: youtubeController,
            label: 'YouTube',
            hint: 'https://youtube.com/@yourchannel',
            icon: Icons.ondemand_video,
          ),
          Gap(24.h),
          Text(
            'Quick facts',
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(12.h),
          Column(
            children: List.generate(quickFactFields.length, (index) {
              final field = quickFactFields[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: field.keyController,
                        decoration: const InputDecoration(
                          labelText: 'Fact title',
                          hintText: 'e.g. Dominant Foot',
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: TextField(
                        controller: field.valueController,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          hintText: 'e.g. Right',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white70,
                      tooltip: 'Remove',
                      onPressed: () => onRemoveQuickFact(index),
                    ),
                  ],
                ),
              );
            }),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddQuickFact,
              icon: const Icon(Icons.add),
              label: const Text('Add quick fact'),
            ),
          ),
          Gap(24.h),
          Text(
            'Highlights',
            style: TextStyles.font14DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(12.h),
          Column(
            children: List.generate(highlightControllers.length, (index) {
              final controller = highlightControllers[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Highlight ${index + 1}',
                          hintText: 'e.g. MVP – City League 2024',
                        ),
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white70,
                      tooltip: 'Remove',
                      onPressed: () => onRemoveHighlight(index),
                    ),
                  ],
                ),
              );
            }),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddHighlight,
              icon: const Icon(Icons.add),
              label: const Text('Add highlight'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildAdminMatchmakingTab({
    required ScrollController controller,
    required bool allowMessages,
    required ValueChanged<bool> onAllowMessagesChanged,
    required VoidCallback onUploadImage,
    required ValueChanged<String> onSelectLibraryImage,
    required ValueChanged<String> onRemoveImage,
    required List<String> images,
    required TextEditingController taglineController,
    required TextEditingController aboutController,
    required TextEditingController cityController,
    required TextEditingController ageController,
    required TextEditingController sportsController,
    required TextEditingController seekingController,
    required TextEditingController distanceController,
    required TextEditingController distanceLinkController,
  }) {
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matchmaking gallery (${images.length}/5)',
            style: TextStyles.font14DarkBlue600Weight,
          ),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              ...images.map(
                (image) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        width: 100.w,
                        height: 100.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(image),
                        child: CircleAvatar(
                          radius: 12.r,
                          backgroundColor: Colors.black54,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (images.length < 5)
                GestureDetector(
                  onTap: _uploadingImage ? null : onUploadImage,
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color:
                          PublicProfileTheme.panelOverlayColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Icon(
                      _uploadingImage
                          ? Icons.hourglass_bottom
                          : Icons.add_photo_alternate,
                      color: PublicProfileTheme.panelAccentColor,
                    ),
                  ),
                ),
            ],
          ),
          if (_matchmakingLibrary.isNotEmpty) ...[
            Gap(20.h),
            Text(
              'Library picks',
              style: TextStyles.font14DarkBlue600Weight,
            ),
            Gap(12.h),
            SizedBox(
              height: 110.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _matchmakingLibrary.length,
                itemBuilder: (context, index) {
                  final image = _matchmakingLibrary[index];
                  final isSelected = images.contains(image);
                  return GestureDetector(
                    onTap: () => onSelectLibraryImage(image),
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? PublicProfileTheme.panelAccentColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: CachedNetworkImage(
                          imageUrl: image,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Gap(20.h),
          TextField(
            controller: taglineController,
            decoration: const InputDecoration(
              labelText: 'Matchmaking headline',
              hintText: 'e.g. Looking for elite futsal squads',
            ),
          ),
          Gap(16.h),
          TextField(
            controller: aboutController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Matchmaking bio',
              hintText: 'Share your playstyle, strengths, and expectations.',
            ),
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'Base city'),
                ),
              ),
              Gap(12.w),
              SizedBox(
                width: 120.w,
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
              ),
            ],
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: distanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Default distance (km)',
                    hintText: 'e.g. 4.6',
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: TextField(
                  controller: distanceLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Distance link (Google Cloud)',
                    hintText: 'Paste shared tracking link',
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          TextField(
            controller: sportsController,
            decoration: const InputDecoration(
              labelText: 'Sports played',
              hintText: 'Comma separated e.g. Football, Futsal, Padel',
            ),
          ),
          Gap(16.h),
          TextField(
            controller: seekingController,
            decoration: const InputDecoration(
              labelText: 'Looking for',
              hintText:
                  'Comma separated e.g. Competitive matches, Analytics squads',
            ),
          ),
          Gap(20.h),
          SwitchListTile(
            value: allowMessages,
            onChanged: onAllowMessagesChanged,
            activeColor: PublicProfileTheme.panelAccentColor,
            title: Text(
              'Lock My Profile',
              style: TextStyles.font14DarkBlue600Weight
                  .copyWith(color: Colors.white),
            ),
            subtitle: Text(
              'When enabled, only approved connections can view full profile & start a chat.',
              style: TextStyles.font12Grey400Weight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPostsTab({
    required ScrollController controller,
    required Set<String> selectedPostIds,
    required void Function(CommunityPost post, bool isSelected) onToggle,
  }) {
    if (_availablePosts.isEmpty) {
      return const Center(child: Text('No community posts available yet.'));
    }

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      itemCount: _availablePosts.length,
      itemBuilder: (context, index) {
        final post = _availablePosts[index];
        final isSelected = selectedPostIds.contains(post.id);
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          color: PublicProfileTheme.panelColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          child: CheckboxListTile(
            value: isSelected,
            activeColor: PublicProfileTheme.panelAccentColor,
            checkColor: Colors.black,
            onChanged: (value) => onToggle(post, value ?? false),
            title: Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.font14DarkBlue600Weight
                  .copyWith(color: Colors.white),
            ),
            subtitle: Text(
              timeago.format(post.createdAt),
              style: TextStyles.font12Grey400Weight,
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadMatchmakingImage() async {
    if (_uploadingImage || _matchmakingImages.length >= 5) return;
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() => _uploadingImage = true);

      final imageFile = File(pickedFile.path);
      final secureUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'playaround/matchmaking',
      );

      setState(() {
        _matchmakingImages = List<String>.from(_matchmakingImages)
          ..add(secureUrl);
        _matchmakingImages = _matchmakingImages.take(5).toList();
        _matchmaking = _matchmaking?.copyWith(images: _matchmakingImages);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  // HELPERS ------------------------------------------------------------------

  String _tabLabel(PublicProfileTab tab) {
    switch (tab) {
      case PublicProfileTab.about:
        return 'About';
      case PublicProfileTab.skills:
        return 'Skills';
      case PublicProfileTab.teams:
        return 'Teams';
      case PublicProfileTab.venues:
        return 'Venues';
      case PublicProfileTab.community:
        return 'Posts';
      case PublicProfileTab.matchmaking:
        return 'Matchmaking';
      case PublicProfileTab.reviews:
        return 'Reviews';
    }
  }

  String get _shareUrl =>
      'https://playaround.app/player/${_identity?.userId ?? 'profile'}';

  Future<void> _openExternalLink(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open link. The URL appears to be invalid.'),
        ),
      );
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        Clipboard.setData(ClipboardData(text: trimmed));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to launch link. Link copied to clipboard: $trimmed',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: trimmed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to launch link. Link copied to clipboard: $trimmed',
          ),
        ),
      );
    }
  }

  void _cacheAssociation(
    String key,
    AssociationCardData association,
  ) {
    final current =
        _availableAssociations[key] ?? const <AssociationCardData>[];
    if (current.any((item) => item.id == association.id)) return;
    _availableAssociations = {
      ..._availableAssociations,
      key: [...current, association],
    };
  }

  Future<List<AssociationCardData>> _searchTeamAssociations(
      String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    try {
      final teams = await _teamService.searchTeams(trimmed);
      return teams.map(_teamToAssociation).toList();
    } catch (error) {
      debugPrint('Team search failed: $error');
      throw Exception('Failed to search teams');
    }
  }

  Future<List<AssociationCardData>> _searchTournamentAssociations(
      String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    try {
      final tournaments = await _tournamentService.searchTournaments(trimmed);
      return tournaments.map(_tournamentToAssociation).toList();
    } catch (error) {
      debugPrint('Tournament search failed: $error');
      throw Exception('Failed to search tournaments');
    }
  }

  Future<List<AssociationCardData>> _searchVenueAssociations(
      String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    try {
      final venues = await _coachAssociationsService.searchVenues(trimmed);
      return venues.map(_venueToAssociation).toList();
    } catch (error) {
      debugPrint('Venue search failed: $error');
      throw Exception('Failed to search venues');
    }
  }

  Future<List<AssociationCardData>> _searchCoachAssociations(
      String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (kDebugMode) {
        debugPrint('🔍 Coach search: Query too short: "$trimmed"');
      }
      return [];
    }
    
    if (kDebugMode) {
      debugPrint('🔍 Dashboard: Searching coaches with query: "$trimmed"');
    }
    
    try {
      final coaches = await _coachService.searchCoachesByName(trimmed);
      
      if (kDebugMode) {
        debugPrint('📊 Dashboard: Found ${coaches.length} coaches');
        if (coaches.isNotEmpty) {
          debugPrint('   Coaches: ${coaches.map((c) => c.fullName).join(", ")}');
        }
      }
      
      final associations = coaches.map(_coachToAssociation).toList();
      
      if (kDebugMode) {
        debugPrint('✅ Dashboard: Converted to ${associations.length} associations');
      }
      
      return associations;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Coach search failed: $error');
        debugPrint('   Stack trace: $stackTrace');
      }
      throw Exception('Failed to search coaches: $error');
    }
  }

  AssociationCardData _teamToAssociation(Team team) {
    final ownerName = _extractTeamOwnerName(team);
    final ownerId = _extractTeamOwnerId(team);
    final tags = <String>[
      team.sportType.displayName,
      '${team.members.length}/${team.maxMembers} members',
    ];
    final description =
        team.description.isNotEmpty ? team.description : (team.bio ?? '');

    return AssociationCardData(
      id: team.id,
      title: team.name,
      subtitle: team.location ?? 'Location to be confirmed',
      role: 'Team',
      imageUrl: _resolveAssociationImage(
        team.teamImageUrl ?? team.backgroundImageUrl,
        'team ${team.sportType.displayName}',
      ),
      tags: tags,
      location: team.location,
      status: team.isActive ? 'Active squad' : 'Inactive',
      description: description.isNotEmpty ? description : null,
      since: team.createdAt,
      ownerName: ownerName,
      ownerId: ownerId,
    );
  }

  String _extractTeamOwnerName(Team team) {
    for (final member in team.members) {
      if (member.role == TeamRole.owner) {
        return member.userName;
      }
    }
    if (team.coachName != null && team.coachName!.isNotEmpty) {
      return team.coachName!;
    }
    if (team.members.isNotEmpty) {
      return team.members.first.userName;
    }
    return 'Team Owner';
  }

  String _extractTeamOwnerId(Team team) {
    if (team.ownerId.isNotEmpty) {
      return team.ownerId;
    }

    for (final member in team.members) {
      if (member.role == TeamRole.owner) {
        return member.userId;
      }
    }

    if (team.members.isNotEmpty) {
      return team.members.first.userId;
    }

    return '';
  }

  AssociationCardData _tournamentToAssociation(Tournament tournament) {
    final tags = <String>{
      _titleCase(tournament.sportType.displayName),
      _titleCase(tournament.format.name),
      _titleCase(tournament.status.name),
    }.toList();

    return AssociationCardData(
      id: tournament.id,
      title: tournament.name,
      subtitle: tournament.location ?? tournament.venueName ?? 'Venue TBA',
      role: 'Tournament',
      imageUrl: _resolveAssociationImage(
        tournament.imageUrl,
        'tournament ${tournament.sportType.displayName}',
      ),
      tags: tags,
      location: tournament.location ?? tournament.venueName,
      status: 'Starts ${_shortDateFormat.format(tournament.startDate)}',
      description: tournament.description,
      since: tournament.startDate,
      ownerName: tournament.organizerName,
      ownerId: tournament.organizerId,
    );
  }

  AssociationCardData _venueToAssociation(VenueModel venue) {
    final primaryImage = venue.images.isNotEmpty
        ? venue.images.first
        : venue.ownerProfilePicture;
    final tags = <String>[
      venue.sportType.displayName,
      if (venue.availableDays.isNotEmpty)
        '${venue.availableDays.length} active days',
    ];

    return AssociationCardData(
      id: venue.id,
      title: venue.title,
      subtitle: venue.location,
      role: 'Venue',
      imageUrl: _resolveAssociationImage(
        primaryImage,
        'venue ${venue.sportType.displayName}',
      ),
      tags: tags,
      location: venue.location,
      status:
          'Rating ${venue.averageRating.toStringAsFixed(1)} • ${venue.totalBookings} bookings',
      description: venue.description,
      since: venue.createdAt,
      ownerName: venue.ownerName,
      ownerId: venue.ownerId,
    );
  }

  AssociationCardData _coachToAssociation(CoachProfile coach) {
    final primaryImage = coach.profilePictureUrl ??
        (coach.profilePhotos.isNotEmpty ? coach.profilePhotos.first : null);
    final specialisations = coach.specializationSports.take(2).toList();
    final tags = <String>[
      if (specialisations.isNotEmpty) ...specialisations,
      '${coach.experienceYears}+ yrs experience',
    ];

    return AssociationCardData(
      id: coach.uid,
      title: coach.fullName,
      subtitle: coach.location ?? 'Available globally',
      role: 'Coach',
      imageUrl: _resolveAssociationImage(
        primaryImage,
        'coach ${specialisations.isNotEmpty ? specialisations.first : 'sports'}',
      ),
      tags: tags,
      location: coach.location,
      status: coach.isProfileComplete ? 'Verified coach' : null,
      description: coach.bio,
      since: coach.createdAt,
      ownerName: coach.fullName,
      ownerId: coach.uid,
    );
  }

  String _resolveAssociationImage(String? url, String fallbackKeyword) {
    if (url != null && url.trim().isNotEmpty) {
      return url.trim();
    }
    final encoded = Uri.encodeComponent(fallbackKeyword);
    return 'https://via.placeholder.com/400x400.png?text=$encoded';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final words = value.replaceAll('_', ' ').split(' ');
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

// DELEGATES & WIDGETS --------------------------------------------------------

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarHeaderDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: ColorsManager.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _HeroOverflowButton extends StatelessWidget {
  const _HeroOverflowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.more_vert,
          size: 20.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: PublicProfileTheme.panelAccentColor),
            Gap(6.w),
            Text(
              label,
              style:
                  TextStyles.font12White600Weight.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: PublicProfileTheme.panelAccentColor,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.stat,
    required this.width,
    this.onTap,
  });

  final ProfileStat stat;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: PublicProfileTheme.panelAccentColor),
          Gap(8.h),
          Text(
            stat.value,
            style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
          ),
          Text(
            stat.label,
            style: TextStyles.font12White600Weight.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: content,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16DarkBlue600Weight
                .copyWith(color: Colors.white),
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }
}

class _QuickFactField {
  _QuickFactField({
    String? key,
    String? value,
  })  : keyController = TextEditingController(text: key ?? ''),
        valueController = TextEditingController(text: value ?? '');

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _AssociationSection extends StatelessWidget {
  const _AssociationSection({
    required this.title,
    required this.description,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final String description;
  final List<AssociationCardData> items;
  final void Function(AssociationCardData item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _SectionCard(
        title: title,
        child: Text(
          'Nothing showcased here yet. Head over to the admin panel to add new items.',
          style: TextStyles.font12Grey400Weight,
        ),
      );
    }

    return _SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyles.font12Grey400Weight,
          ),
          Gap(16.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _AssociationCard(
                item: item,
                onTap: onItemTap != null ? () => onItemTap!(item) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationCard extends StatelessWidget {
  const _AssociationCard({required this.item, this.onTap});

  final AssociationCardData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
            gradient: PublicProfileTheme.panelGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 70.w,
                  height: 70.w,
                  fit: BoxFit.cover,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyles.font14DarkBlue600Weight,
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      Gap(4.h),
                      Text(
                        item.subtitle,
                        style: TextStyles.font12Grey400Weight,
                      ),
                    ],
                    Gap(6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: item.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor:
                                  PublicProfileTheme.panelAccentColor
                                      .withOpacity(0.18),
                              labelStyle: TextStyles.font10DarkBlue500Weight
                                  .copyWith(
                                      color:
                                          PublicProfileTheme.panelAccentColor),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAssociationTile extends StatelessWidget {
  const _MiniAssociationTile({required this.title, required this.data});

  final String title;
  final AssociationCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: PublicProfileTheme.panelGradient,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(data.imageUrl),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font12Grey400Weight,
                ),
                Text(
                  data.title,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillProgressTile extends StatelessWidget {
  const _SkillProgressTile({required this.metric});

  final SkillMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(metric.name, style: TextStyles.font14DarkBlue600Weight),
            Text(
              metric.score.toStringAsFixed(0),
              style: TextStyles.font14DarkBlue600Weight,
            ),
          ],
        ),
        Gap(6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: metric.progress,
            minHeight: 10.h,
            backgroundColor:
                PublicProfileTheme.panelOverlayColor.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(
                PublicProfileTheme.panelAccentColor),
          ),
        ),
        Gap(4.h),
        Text(
          metric.description,
          style: TextStyles.font12Grey400Weight,
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewEntry review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  review.authorAvatarUrl,
                ),
              ),
              Gap(12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: TextStyles.font14DarkBlue600Weight,
                  ),
                  Text(
                    review.relationship,
                    style: TextStyles.font12Grey400Weight,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                timeago.format(review.createdAt),
                style: TextStyles.font10Grey400Weight,
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating.round() ? Icons.star : Icons.star_border,
                color: PublicProfileTheme.panelAccentColor,
                size: 18.sp,
              ),
            ),
          ),
          Gap(8.h),
          Text(
            review.comment,
            style: TextStyles.font14Grey400Weight.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ReviewFormResult {
  const _ReviewFormResult({
    required this.rating,
    required this.comment,
    required this.relationship,
    this.reviewerName,
  });

  final int rating;
  final String comment;
  final String relationship;
  final String? reviewerName;
}

class _AddReviewDialog extends StatefulWidget {
  const _AddReviewDialog({
    required this.reviewerName,
    this.reviewerAvatarUrl,
  });

  final String reviewerName;
  final String? reviewerAvatarUrl;

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _relationshipController =
      TextEditingController(text: 'Community member');
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PublicProfileTheme.panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.reviewerAvatarUrl != null &&
                          widget.reviewerAvatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.reviewerAvatarUrl!)
                      : null,
                  child: (widget.reviewerAvatarUrl == null ||
                          widget.reviewerAvatarUrl!.isEmpty)
                      ? Text(
                          widget.reviewerName.isNotEmpty
                              ? widget.reviewerName[0].toUpperCase()
                              : '?',
                          style: TextStyles.font16DarkBlue600Weight
                              .copyWith(color: Colors.white),
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviewing as',
                        style: TextStyles.font12Grey400Weight,
                      ),
                      Text(
                        widget.reviewerName,
                        style: TextStyles.font14DarkBlue600Weight
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            Gap(20.h),
            Text(
              'How was your experience?',
              style: TextStyles.font14DarkBlue600Weight
                  .copyWith(color: Colors.white),
            ),
            Gap(12.h),
            Row(
              children: List.generate(
                5,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() => _rating = index + 1);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: PublicProfileTheme.panelAccentColor,
                      size: 28.sp,
                    ),
                  ),
                ),
              ),
            ),
            Gap(20.h),
            Text(
              'Your review',
              style: TextStyles.font12Grey400Weight
                  .copyWith(color: Colors.white70),
            ),
            Gap(8.h),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share constructive feedback…',
                hintStyle: TextStyles.font12Grey400Weight,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                      color: PublicProfileTheme.panelAccentColor, width: 1.5),
                ),
              ),
            ),
            Gap(16.h),
            Text(
              'Your relationship (optional)',
              style: TextStyles.font12Grey400Weight
                  .copyWith(color: Colors.white70),
            ),
            Gap(8.h),
            TextField(
              controller: _relationshipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Teammate, Coach, Fan',
                hintStyle: TextStyles.font12Grey400Weight,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                      color: PublicProfileTheme.panelAccentColor, width: 1.5),
                ),
              ),
            ),
            Gap(24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: PublicProfileTheme.panelAccentColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _ReviewFormResult(
        rating: _rating,
        comment: comment,
        relationship: _relationshipController.text.trim().isEmpty
            ? 'Community member'
            : _relationshipController.text.trim(),
        reviewerName: widget.reviewerName,
      ),
    );
  }
}

class _AdminAssociationsTab extends StatefulWidget {
  const _AdminAssociationsTab({
    super.key,
    required this.controller,
    required this.title,
    required this.searchPlaceholder,
    required this.available,
    required this.selectedIds,
    required this.onToggle,
    required this.initialQuery,
    required this.onQueryChanged,
    this.emptyLabel,
    this.onSearch,
    this.selectedAssociations,
  });

  final ScrollController controller;
  final String title;
  final String searchPlaceholder;
  final List<AssociationCardData> available;
  final Set<String> selectedIds;
  final List<AssociationCardData>? selectedAssociations; // Pending items
  final Future<void> Function(AssociationCardData association, bool isSelected)
      onToggle;
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;
  final String? emptyLabel;
  final Future<List<AssociationCardData>> Function(String query)? onSearch;

  @override
  State<_AdminAssociationsTab> createState() => _AdminAssociationsTabState();
}

class _AdminAssociationsTabState extends State<_AdminAssociationsTab> {
  late String _query;
  late List<AssociationCardData> _results;
  late final TextEditingController _searchController;
  bool _isSearching = false;
  bool _isProgrammaticSearchUpdate = false;
  String? _error;
  int _searchToken = 0;
  // Keep track of pending items that were added but not yet approved
  final Map<String, AssociationCardData> _pendingItems = {};

  IconData _getIconForRole(String role) {
    switch (role.toLowerCase()) {
      case 'venue':
        return Icons.location_on;
      case 'team':
        return Icons.group;
      case 'tournament':
        return Icons.emoji_events;
      case 'coach':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _results = List<AssociationCardData>.from(widget.available);
    
    // Initialize pending items from selectedAssociations
    if (widget.selectedAssociations != null) {
      for (final assoc in widget.selectedAssociations!) {
        if (widget.selectedIds.contains(assoc.id) &&
            !widget.available.any((a) => a.id == assoc.id)) {
          _pendingItems[assoc.id] = assoc;
        }
      }
    }
    
    _searchController = TextEditingController(text: _query);
    _searchController.addListener(() {
      if (_isProgrammaticSearchUpdate) return;
      _handleQueryChanged(_searchController.text);
    });
  }

  @override
  void didUpdateWidget(covariant _AdminAssociationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      _query = widget.initialQuery;
      _setSearchText(_query);
    }
    if (oldWidget.available != widget.available &&
        (widget.onSearch == null || _query.trim().length < 2)) {
      _results = List<AssociationCardData>.from(widget.available);
    }
    
    // Update pending items - remove items that are now approved
    final approvedIds = widget.available.map((a) => a.id).toSet();
    _pendingItems.removeWhere((id, _) => approvedIds.contains(id));
    
    // Remove items that are no longer selected
    _pendingItems.removeWhere((id, _) => !widget.selectedIds.contains(id));
    
    // Add new pending items from selectedAssociations
    if (widget.selectedAssociations != null) {
      for (final assoc in widget.selectedAssociations!) {
        if (widget.selectedIds.contains(assoc.id) &&
            !widget.available.any((a) => a.id == assoc.id)) {
          _pendingItems[assoc.id] = assoc;
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchText(String value) {
    if (_searchController.text == value) return;
    _isProgrammaticSearchUpdate = true;
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isProgrammaticSearchUpdate = false;
  }

  Future<void> _handleQueryChanged(String value) async {
    final trimmed = value.trim();
    _query = value;
    widget.onQueryChanged(value);

    if (kDebugMode) {
      debugPrint('🔍 _AdminAssociationsTab: Query changed to "$value" (trimmed: "$trimmed")');
      debugPrint('   onSearch is ${widget.onSearch == null ? "null" : "not null"}');
      debugPrint('   trimmed.length: ${trimmed.length}');
    }

    if (widget.onSearch == null || trimmed.length < 2) {
      if (kDebugMode) {
        debugPrint('⚠️ Skipping search: onSearch is null or query too short');
      }
      setState(() {
        _isSearching = false;
        _error = null;
        _results = List<AssociationCardData>.from(widget.available);
      });
      return;
    }

    final token = ++_searchToken;
    setState(() {
      _isSearching = true;
      _error = null;
    });

    if (kDebugMode) {
      debugPrint('🚀 Calling onSearch with query: "$trimmed"');
    }

    try {
      final results = await widget.onSearch!(trimmed);
      if (!mounted || token != _searchToken) {
        if (kDebugMode) {
          debugPrint('⚠️ Search cancelled or widget unmounted');
        }
        return;
      }
      
      if (kDebugMode) {
        debugPrint('✅ Search returned ${results.length} results');
        if (results.isNotEmpty) {
          debugPrint('   Results: ${results.map((r) => r.title).join(", ")}');
        }
      }
      
      setState(() {
        _results = results;
        _isSearching = false;
        // Update pending items with search results
        for (final result in results) {
          if (widget.selectedIds.contains(result.id) && 
              !widget.available.any((a) => a.id == result.id)) {
            _pendingItems[result.id] = result;
          }
        }
      });
    } catch (error, stackTrace) {
      if (!mounted || token != _searchToken) return;
      if (kDebugMode) {
        debugPrint('❌ Search error: $error');
        debugPrint('   Stack trace: $stackTrace');
      }
      setState(() {
        _isSearching = false;
        _error = error.toString();
        _results = List<AssociationCardData>.from(widget.available);
      });
    }
  }

  List<AssociationCardData> _buildDisplayedList() {
    final map = <String, AssociationCardData>{};
    
    // Add search results (these are the new items from search)
    for (final result in _results) {
      map[result.id] = result;
    }
    
    // Add available (approved) associations
    for (final available in widget.available) {
      map.putIfAbsent(available.id, () => available);
    }
    
    // Add pending items (selected but not yet approved)
    for (final entry in _pendingItems.entries) {
      if (widget.selectedIds.contains(entry.key) &&
          !widget.available.any((a) => a.id == entry.key)) {
        map.putIfAbsent(entry.key, () => entry.value);
      }
    }

    if (kDebugMode && _query.trim().length >= 2) {
      debugPrint('📋 Building displayed list:');
      debugPrint('   _results: ${_results.length} items');
      debugPrint('   widget.available: ${widget.available.length} items');
      debugPrint('   _pendingItems: ${_pendingItems.length} items');
      debugPrint('   map total: ${map.length} items');
    }

    final ordered = <AssociationCardData>[];
    // First, add selected items (including pending ones)
    for (final id in widget.selectedIds) {
      final assoc = map.remove(id);
      if (assoc != null) {
        ordered.add(assoc);
      }
    }

    // Then add remaining items (not selected) - this includes search results
    final remaining = map.values.toList()
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    ordered.addAll(remaining);
    
    if (kDebugMode && _query.trim().length >= 2) {
      debugPrint('   Final ordered list: ${ordered.length} items');
      if (ordered.isNotEmpty) {
        debugPrint('   Items: ${ordered.map((o) => o.title).join(", ")}');
      }
    }
    
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _buildDisplayedList();

    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        Text(
          widget.title,
          style:
              TextStyles.font14DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        Gap(12.h),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: widget.searchPlaceholder,
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _setSearchText('');
                      _handleQueryChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        Gap(16.h),
        if (_isSearching)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Text(
              _error!,
              style: TextStyles.font12Grey400Weight
                  .copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          )
        else if (displayed.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: Text(
              widget.emptyLabel ??
                  'No results found. Try a different search term.',
              style: TextStyles.font12Grey400Weight,
              textAlign: TextAlign.center,
            ),
          )
        else
          ...displayed.map(
            (association) {
              final isSelected = widget.selectedIds.contains(association.id);
              final owner = association.ownerName;
              final statusText = association.status;
              
              // Determine association request status
              final isApproved = widget.available.any((item) => item.id == association.id);
              AssociationStatus? associationStatus;
              if (isApproved) {
                associationStatus = AssociationStatus.approved;
              } else if (isSelected) {
                associationStatus = AssociationStatus.pending;
              }
              
              return Card(
                elevation: 0,
                margin: EdgeInsets.only(bottom: 12.h),
                color: PublicProfileTheme.panelColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: BorderSide(
                    color: isSelected
                        ? PublicProfileTheme.panelAccentColor
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: associationStatus != null
                        ? associationStatus.color.withAlpha(51)
                        : Colors.white.withOpacity(0.1),
                    backgroundImage: association.imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(association.imageUrl)
                        : null,
                    child: association.imageUrl.isEmpty
                        ? Icon(
                            _getIconForRole(association.role),
                            color: associationStatus != null
                                ? associationStatus.color
                                : Colors.white.withOpacity(0.7),
                            size: 24.sp,
                          )
                        : null,
                  ),
                  title: Text(
                    association.title,
                    style: TextStyles.font14DarkBlue600Weight
                        .copyWith(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (association.subtitle.isNotEmpty)
                        Text(
                          association.subtitle,
                          style: TextStyles.font12Grey400Weight,
                        ),
                      if (owner != null && owner.isNotEmpty)
                        Text(
                          'Owner: $owner',
                          style: TextStyles.font10Grey400Weight,
                        ),
                      // Show association status badge
                      if (associationStatus != null) ...[
                        Gap(4.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: associationStatus.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: associationStatus.color.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Status: ${associationStatus.displayName}',
                            style: TextStyles.font10Grey400Weight.copyWith(
                              color: associationStatus.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (statusText != null && statusText.isNotEmpty) ...[
                        Gap(4.h),
                        Text(
                          statusText,
                          style: TextStyles.font10Grey400Weight.copyWith(
                              color: PublicProfileTheme.panelAccentColor),
                        ),
                      ],
                    ],
                  ),
                  trailing: Switch(
                    value: isSelected,
                    activeColor: PublicProfileTheme.panelAccentColor,
                    onChanged: (value) async {
                      await widget.onToggle(association, value);
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
