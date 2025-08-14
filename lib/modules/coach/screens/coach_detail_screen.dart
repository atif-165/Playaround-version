import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/coach_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../services/coach_service.dart';

/// Detailed coach profile screen
class CoachDetailScreen extends StatefulWidget {
  final CoachProfile coach;

  const CoachDetailScreen({
    super.key,
    required this.coach,
  });

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final CoachService _coachService = CoachService();
  bool _isCurrentUser = false;
  bool _isLoading = false;
  List<dynamic> _coachVenues = [];
  List<dynamic> _coachTeams = [];
  bool _isLoadingTabs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkIfCurrentUser();
    _loadTabData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkIfCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    _isCurrentUser = currentUser?.uid == widget.coach.uid;
  }

  Future<void> _loadTabData() async {
    setState(() {
      _isLoadingTabs = true;
    });

    try {
      // Load venues owned by the coach
      final venues = await _coachService.getCoachVenues(widget.coach.uid);

      // Load teams where the coach is owner or captain
      final teams = await _coachService.getCoachTeams(widget.coach.uid);

      if (mounted) {
        setState(() {
          _coachVenues = venues;
          _coachTeams = teams;
          _isLoadingTabs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTabs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildTabBar(),
                _buildTabBarView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isCurrentUser ? null : _buildConsultButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: ColorsManager.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorsManager.primary,
                ColorsManager.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: widget.coach.profilePictureUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.coach.profilePictureUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 80.sp,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 80.sp,
                ),
        ),
      ),
      actions: [
        if (_isCurrentUser)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editProfile,
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.coach.fullName,
                      style: TextStyles.font20DarkBlueBold,
                    ),
                    Gap(8.h),
                    _buildRatingRow(),
                    Gap(8.h),
                    _buildLocationRow(),
                  ],
                ),
              ),
              _buildCoachBadge(),
            ],
          ),
          Gap(16.h),
          _buildExperienceInfo(),
          Gap(16.h),
          _buildBio(),
          Gap(16.h),
          _buildSpecializations(),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    // TODO: Implement actual rating system
    const rating = 4.5;
    const reviewCount = 23;

    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20.sp,
          );
        }),
        Gap(8.w),
        Text(
          '$rating ($reviewCount reviews)',
          style: TextStyles.font14DarkBlueMedium,
        ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.grey[600],
          size: 16.sp,
        ),
        Gap(4.w),
        Text(
          widget.coach.location,
          style: TextStyles.font14Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildCoachBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports,
            color: Colors.white,
            size: 16.sp,
          ),
          Gap(4.w),
          Text(
            'COACH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.work_outline,
            title: 'Experience',
            value: '${widget.coach.experienceYears} years',
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.attach_money,
            title: 'Hourly Rate',
            value: '\$${widget.coach.hourlyRate.toStringAsFixed(0)}',
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.schedule,
            title: 'Training Type',
            value: widget.coach.coachingType.displayName,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: ColorsManager.primary,
            size: 24.sp,
          ),
          Gap(8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          Gap(4.h),
          Text(
            value,
            style: TextStyles.font14DarkBlueBold,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    if (widget.coach.bio == null || widget.coach.bio!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'No bio available',
          style: TextStyles.font14Grey400Weight.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(8.h),
        Text(
          widget.coach.bio!,
          style: TextStyles.font14DarkBlueMedium,
        ),
      ],
    );
  }

  Widget _buildSpecializations() {
    if (widget.coach.specializationSports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.coach.specializationSports.map((sport) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: ColorsManager.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                sport,
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: ColorsManager.primary,
        tabs: const [
          Tab(text: 'Venues'),
          Tab(text: 'Teams'),
          Tab(text: 'Players'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 400.h,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildVenuesTab(),
          _buildTeamsTab(),
          _buildPlayersTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildVenuesTab() {
    if (_isLoadingTabs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No venues managed',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(8.h),
            Text(
              'This coach doesn\'t manage any venues yet',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _coachVenues.length,
      itemBuilder: (context, index) {
        final venue = _coachVenues[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(
              Icons.location_on,
              color: ColorsManager.primary,
            ),
            title: Text(venue['name'] ?? 'Unknown Venue'),
            subtitle: Text(venue['location'] ?? 'Unknown Location'),
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_isLoadingTabs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coachTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No teams managed',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(8.h),
            Text(
              'This coach doesn\'t manage any teams yet',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _coachTeams.length,
      itemBuilder: (context, index) {
        final team = _coachTeams[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: const Icon(
              Icons.group,
              color: ColorsManager.primary,
            ),
            title: Text(team['name'] ?? 'Unknown Team'),
            subtitle: Text('${team['memberCount']}/${team['maxMembers']} members'),
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          Gap(16.h),
          Text(
            'Individual Players',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(8.h),
          Text(
            'Individual player management coming soon',
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Add Review Button (only show if not current user)
          if (!_isCurrentUser)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 20.h),
              child: ElevatedButton.icon(
                onPressed: _addReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFFF), // Neon blue
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(
                  'Add Review',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          // Reviews List (placeholder)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48.sp,
                    color: Colors.grey[400],
                  ),
                  Gap(16.h),
                  Text(
                    'No Reviews Yet',
                    style: TextStyles.font16DarkBlueBold,
                  ),
                  Gap(8.h),
                  Text(
                    _isCurrentUser
                        ? 'Reviews from your clients will appear here'
                        : 'Be the first to review this coach',
                    style: TextStyles.font14Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _consultNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat,
                        size: 20.sp,
                      ),
                      Gap(8.w),
                      Text(
                        'Consult Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _consultNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create or get existing chat with the coach
      final chatRoom = await _chatService.getOrCreateDirectChat(widget.coach.uid);

      if (chatRoom != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      } else {
        throw Exception('Unable to start chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editProfile() {
    // Navigate to the main profile screen which has edit functionality
    Navigator.of(context).pushNamed('/profile');
  }

  void _addReview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ReviewDialog(coachName: widget.coach.fullName);
      },
    );
  }
}

/// Dialog for adding a review
class _ReviewDialog extends StatefulWidget {
  final String coachName;

  const _ReviewDialog({required this.coachName});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: Color(0xFF00FFFF), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Review ${widget.coachName}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Gap(16.h),

            // Rating
            Text(
              'Rating:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFF00FFFF), // Neon blue
                    size: 32.sp,
                  ),
                );
              }),
            ),
            Gap(16.h),

            // Review Text
            Text(
              'Review:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your experience with this coach...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
            Gap(20.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: ColorsManager.primary,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement actual review submission to Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Color(0xFF00FFFF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
