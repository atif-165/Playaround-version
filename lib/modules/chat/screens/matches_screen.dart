import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../matchmaking/models/matchmaking_models.dart';
import '../../matchmaking/services/matchmaking_service.dart';
import '../../matchmaking/screens/match_profile_detail_screen.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';
import 'chat_screen.dart';

const _matchesBackgroundColor = Color(0xFF050414);
const LinearGradient _matchesBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);
const LinearGradient _matchesPanelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF181536),
    Color(0xFF0E0D24),
  ],
);
const Color _matchesPanelColor = Color(0xFF14112D);
const Color _matchesOverlayColor = Color(0xFF1C1A3C);
const Color _matchesAccentColor = Color(0xFFFFC56F);

/// Screen showing all users you've matched with (mutual likes)
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final ChatService _chatService = ChatService();

  List<Match> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _matchmakingService.getUserMatches();

      // Deduplicate matches - keep only one match per unique user pair
      final deduplicatedMatches = _deduplicateMatches(matches);

      if (mounted) {
        setState(() {
          _matches = deduplicatedMatches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading matches: $e');
      }
      if (mounted) {
        String errorMessage = 'Failed to load matches. Please try again.';

        // Provide more specific error messages
        if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please sign in to view your matches.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please try signing in again.';
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  /// Deduplicate matches to ensure each user appears only once
  /// Keeps the most recent match for each unique user pair
  List<Match> _deduplicateMatches(List<Match> matches) {
    if (matches.isEmpty) return matches;

    final currentUserId = _matchmakingService.currentUserId;
    final Map<String, Match> uniqueMatches = {};

    for (final match in matches) {
      // Determine the other user's ID
      final otherUserId =
          match.user1Id == currentUserId ? match.user2Id : match.user1Id;

      // If we haven't seen this user before, or if this match is more recent
      if (!uniqueMatches.containsKey(otherUserId) ||
          match.createdAt.isAfter(uniqueMatches[otherUserId]!.createdAt)) {
        uniqueMatches[otherUserId] = match;
      }
    }

    // Convert back to list and sort by creation date (most recent first)
    final deduplicatedList = uniqueMatches.values.toList();
    deduplicatedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (kDebugMode && matches.length != deduplicatedList.length) {
      debugPrint(
          '🔍 Deduplicated matches: ${matches.length} → ${deduplicatedList.length}');
      debugPrint(
          '   Removed ${matches.length - deduplicatedList.length} duplicate(s)');
    }

    return deduplicatedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _matchesBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: _matchesBackgroundGradient,
        ),
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _matchesBackgroundGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 3.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 22.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Matches',
                      style: TextStyles.font20DarkBlueBold.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_matches.isNotEmpty)
                      Text(
                        '${_matches.length} ${_matches.length == 1 ? 'match' : 'matches'}',
                        style: TextStyles.font14Grey400Weight.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: _loadMatches,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_matches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: _matchesAccentColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildMatchCard(match),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.redAccent,
            ),
            Gap(16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.font16DarkBlue600Weight.copyWith(
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            AppTextButton(
              buttonText: 'Try Again',
              textStyle: TextStyles.font14White600Weight,
              onPressed: _loadMatches,
              backgroundColor: _matchesAccentColor,
              buttonHeight: 40,
            ),
            Gap(12.h),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate back to discover screen
                Navigator.pushReplacementNamed(context, '/main_navigation');
              },
              child: Text(
                'Go to Discover',
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: _matchesAccentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64.sp,
              color: Colors.white54,
            ),
            Gap(16.h),
            Text(
              'No Matches Yet',
              style: TextStyles.font18DarkBlue600Weight.copyWith(
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            Text(
              'Start swiping to find people you like!\nWhen you both like each other, you\'ll see them here.',
              style: TextStyles.font14Grey400Weight.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(24.h),
            AppTextButton(
              buttonText: 'Start Swiping',
              textStyle: TextStyles.font14White600Weight,
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/player-matchmaking');
              },
              backgroundColor: _matchesAccentColor,
              buttonHeight: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    // Determine which user is the other person (not current user)
    final isCurrentUserUser1 =
        match.user1Id == _matchmakingService.currentUserId;
    final otherUserName =
        isCurrentUserUser1 ? match.user2Name : match.user1Name;
    final otherUserPhotoUrl =
        isCurrentUserUser1 ? match.user2PhotoUrl : match.user1PhotoUrl;
    final otherUserId = isCurrentUserUser1 ? match.user2Id : match.user1Id;

    final initials = _getInitials(otherUserName);

    return Container(
      decoration: BoxDecoration(
        gradient: _matchesPanelGradient,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _matchesAccentColor.withOpacity(0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              // Profile Image - Tappable
              GestureDetector(
                onTap: () => _navigateToUserProfile(otherUserId),
                child: Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: otherUserPhotoUrl != null &&
                            otherUserPhotoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: otherUserPhotoUrl,
                            width: 64.w,
                            height: 64.h,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.white.withOpacity(0.08),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: _matchesAccentColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                gradient: _matchesPanelGradient,
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyles.font20DarkBlueBold.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: _matchesPanelGradient,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyles.font20DarkBlueBold.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Gap(16.w),
              // User Info - Tappable
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToUserProfile(otherUserId),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: TextStyles.font16DarkBlue600Weight.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(6.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: _matchesAccentColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: _matchesAccentColor,
                                  size: 12.sp,
                                ),
                                Gap(3.w),
                                Text(
                                  _getTimeAgo(match.createdAt),
                                  style:
                                      TextStyles.font12Grey400Weight.copyWith(
                                    color: Colors.white70,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (match.compatibilityScore > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 12.sp,
                                  ),
                                  Gap(3.w),
                                  Text(
                                    '${match.compatibilityScore}%',
                                    style:
                                        TextStyles.font12Grey400Weight.copyWith(
                                      color: Colors.white70,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Gap(12.w),
              // Chat Button
              Container(
                decoration: BoxDecoration(
                  color: _matchesAccentColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: _matchesAccentColor.withOpacity(0.4),
                      blurRadius: 10.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () => _openChat(match),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 12.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          Gap(6.w),
                          Text(
                            'Chat',
                            style: TextStyles.font14White600Weight.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Future<void> _openChat(Match match) async {
    try {
      // If chat room already exists, navigate to it
      if (match.chatRoomId != null) {
        final chatRoom = await _chatService.getChatRoom(match.chatRoomId!);
        if (chatRoom != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: chatRoom),
            ),
          );
          return;
        }
      }

      // Otherwise create a new chat room
      final otherUserId = match.user1Id == _matchmakingService.currentUserId
          ? match.user2Id
          : match.user1Id;

      final chatRoom = await _chatService.getOrCreateDirectChat(otherUserId);
      if (chatRoom != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open chat. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _navigateToUserProfile(String userId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: _matchesAccentColor),
      ),
    );

    try {
      // Get the match profile for this user
      final matchProfile =
          await _matchmakingService.getMatchProfileByUserId(userId);

      if (mounted) {
        // Remove loading dialog
        Navigator.pop(context);

        if (matchProfile != null) {
          // Navigate to the proper profile detail screen (same as matchmaking)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MatchProfileDetailScreen(profile: matchProfile),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load user profile'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
