import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../services/coach_matching_service.dart';
import '../../../models/match_models.dart';
import 'coach_swipeable_card.dart';

/// Coaches tab with swipe matchmaking functionality
class CoachesTab extends StatefulWidget {
  const CoachesTab({super.key});

  @override
  State<CoachesTab> createState() => _CoachesTabState();
}

class _CoachesTabState extends State<CoachesTab>
    with TickerProviderStateMixin {
  final CoachMatchingService _matchingService = CoachMatchingService();
  
  List<CoachMatch> _coachMatches = [];
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
    _loadCoachMatches();
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

  Future<void> _loadCoachMatches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final matches = await _matchingService.findCoachMatches(
        currentUserId: user.uid,
        maxDistance: 50.0,
        maxResults: 20,
      );
      
      if (mounted) {
        setState(() {
          _coachMatches = matches;
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
          SnackBar(content: Text('Error loading coaches: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreCoachMatches() async {
    if (_isLoadingMore) return;
    
    try {
      setState(() {
        _isLoadingMore = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final excludeIds = _coachMatches.map((m) => m.coach.uid).toList();
      final newMatches = await _matchingService.findCoachMatches(
        currentUserId: user.uid,
        maxDistance: 50.0,
        maxResults: 10,
      );
      
      // Filter out already shown coaches
      final filteredMatches = newMatches.where((match) => 
        !excludeIds.contains(match.coach.uid)).toList();
      
      if (mounted) {
        setState(() {
          _coachMatches.addAll(filteredMatches);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachMatches.isEmpty) {
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
            'Discover Coaches',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Gap(8.h),
          Text(
            'Swipe right to like, left to pass',
            style: TextStyles.font14Grey400Weight,
          ),
          Gap(16.h),
          LinearProgressIndicator(
            value: _currentIndex / _coachMatches.length,
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
                if (_currentIndex + 1 < _coachMatches.length)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.95,
                      child: CoachSwipeableCard(
                        coachMatch: _coachMatches[_currentIndex + 1],
                        onSwipe: (action) {},
                        onLike: () {},
                        onComment: () {},
                        isInteractive: false,
                      ),
                    ),
                  ),
                
                // Current card
                if (_currentIndex < _coachMatches.length)
                  Positioned.fill(
                    child: CoachSwipeableCard(
                      coachMatch: _coachMatches[_currentIndex],
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
              Icons.sports,
              size: 80.sp,
              color: ColorsManager.outline,
            ),
            Gap(24.h),
            Text(
              'No More Coaches',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(12.h),
            Text(
              'You\'ve seen all available coaches in your area. Check back later for new coaches!',
              style: TextStyles.font16Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(32.h),
            ElevatedButton(
              onPressed: _loadCoachMatches,
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
    if (_currentIndex >= _coachMatches.length) return;

    try {
      final currentCoachMatch = _coachMatches[_currentIndex];
      final isMatch = await _matchingService.handleCoachSwipe(
        toCoachId: currentCoachMatch.coach.uid,
        action: action,
      );

      if (isMatch && action == SwipeAction.like) {
        _showMatchDialog(currentCoachMatch);
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
    if (_currentIndex >= _coachMatches.length) return;
    
    final coachMatch = _coachMatches[_currentIndex];
    _showCommentDialog(coachMatch);
  }

  void _moveToNextCard() {
    setState(() {
      _currentIndex++;
    });

    _cardAnimationController.reset();
    _cardAnimationController.forward();

    // Load more suggestions if running low
    if (_currentIndex >= _coachMatches.length - 3) {
      _loadMoreCoachMatches();
    }
  }

  void _showMatchDialog(CoachMatch coachMatch) {
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
              'You and ${coachMatch.coach.fullName} liked each other!',
              style: TextStyles.font16Grey400Weight,
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            Text(
              'Start chatting now or continue discovering coaches.',
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

  void _showCommentDialog(CoachMatch coachMatch) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Comment on ${coachMatch.coach.fullName}\'s Profile',
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
                  await _matchingService.addCoachProfileComment(
                    toCoachId: coachMatch.coach.uid,
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
}
