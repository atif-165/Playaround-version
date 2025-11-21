import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../models/dashboard_models.dart';
import '../../models/match_models.dart';
import '../../services/people_matching_service.dart';
import '../../core/widgets/progress_indicaror.dart';
import '../widgets/swipeable_card.dart';
import '../widgets/mood_selector.dart';

/// Main people search screen with Tinder-like swipeable cards
class PeopleSearchScreen extends StatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen>
    with TickerProviderStateMixin {
  final PeopleMatchingService _matchingService = PeopleMatchingService();

  List<MatchmakingSuggestion> _suggestions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;

  late AnimationController _cardAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final suggestions = await _matchingService.getPotentialMatches(limit: 20);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _currentIndex = 0;
          _isLoading = false;
        });

        _cardAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreSuggestions() async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final excludeIds = _suggestions.map((s) => s.id).toList();
      final newSuggestions = await _matchingService.getPotentialMatches(
        limit: 10,
        excludeUserIds: excludeIds,
      );

      if (mounted) {
        setState(() {
          _suggestions.addAll(newSuggestions);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'People Search',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorsManager.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.mood,
              color: ColorsManager.primary,
              size: 24.sp,
            ),
            onPressed: _showMoodSelector,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ColorsManager.primary,
              size: 24.sp,
            ),
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildCardStack(),
        ),
        _buildActionButtons(),
        Gap(20.h),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Text(
            'Discover People',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(8.h),
          Text(
            'Swipe left to like, right to pass',
            style: TextStyles.font14Grey400Weight,
          ),
          Gap(16.h),
          LinearProgressIndicator(
            value: _currentIndex / _suggestions.length,
            backgroundColor: ColorsManager.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            height: 600.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            child: Stack(
              children: [
                // Show next card behind current card
                if (_currentIndex + 1 < _suggestions.length)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.95,
                      child: SwipeableCard(
                        suggestion: _suggestions[_currentIndex + 1],
                        onSwipe: (action) {},
                        onLike: () {},
                        onComment: () {},
                        isInteractive: false,
                      ),
                    ),
                  ),

                // Current card
                if (_currentIndex < _suggestions.length)
                  Positioned.fill(
                    child: SwipeableCard(
                      suggestion: _suggestions[_currentIndex],
                      onSwipe: _handleSwipe,
                      onLike: _handleLike,
                      onComment: _handleComment,
                      isInteractive: true,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  onPressed: () => _handleSwipe(SwipeAction.pass),
                ),
                _buildActionButton(
                  icon: Icons.favorite,
                  color: ColorsManager.primary,
                  onPressed: () => _handleSwipe(SwipeAction.like),
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  color: ColorsManager.secondary,
                  onPressed: _handleComment,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) => _buttonAnimationController.reverse(),
      onTapCancel: () => _buttonAnimationController.reverse(),
      onTap: onPressed,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80.sp,
              color: ColorsManager.outline,
            ),
            Gap(24.h),
            Text(
              'No More People',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(12.h),
            Text(
              'You\'ve seen everyone in your area. Check back later for new people!',
              style: TextStyles.font16Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            ElevatedButton(
              onPressed: _loadSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              ),
              child: Text(
                'Refresh',
                style: TextStyles.font16White600Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSwipe(SwipeAction action) async {
    if (_currentIndex >= _suggestions.length) return;

    try {
      final currentSuggestion = _suggestions[_currentIndex];
      final isMatch = await _matchingService.handleSwipe(
        toUserId: currentSuggestion.id,
        action: action,
      );

      if (isMatch && action == SwipeAction.like) {
        _showMatchDialog(currentSuggestion);
      }

      _moveToNextCard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleLike() {
    _handleSwipe(SwipeAction.like);
  }

  void _handleComment() {
    if (_currentIndex >= _suggestions.length) return;

    final suggestion = _suggestions[_currentIndex];
    _showCommentDialog(suggestion);
  }

  void _moveToNextCard() {
    setState(() {
      _currentIndex++;
    });

    _cardAnimationController.reset();
    _cardAnimationController.forward();

    // Load more suggestions if running low
    if (_currentIndex >= _suggestions.length - 3) {
      _loadMoreSuggestions();
    }
  }

  void _showMatchDialog(MatchmakingSuggestion suggestion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '🎉 It\'s a Match!',
          style: TextStyles.font18DarkBlue600Weight,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You and ${suggestion.fullName} liked each other!',
              style: TextStyles.font16Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            Text(
              'Start chatting now or continue discovering people.',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
            ),
            child: Text(
              'Start Chat',
              style: TextStyles.font14White600Weight,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(MatchmakingSuggestion suggestion) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Comment on ${suggestion.fullName}\'s Profile',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                try {
                  await _matchingService.addProfileComment(
                    toUserId: suggestion.id,
                    comment: commentController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment sent!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending comment: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
            ),
            child: Text(
              'Send',
              style: TextStyles.font14White600Weight,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodSelector(
        onMoodSelected: (mood, description) async {
          try {
            await _matchingService.updateDailyMood(
              mood: mood,
              description: description,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mood updated!')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating mood: $e')),
            );
          }
        },
      ),
    );
  }
}
