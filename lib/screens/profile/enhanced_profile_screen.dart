import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../core/widgets/app_text_button.dart';
import '../../logic/cubit/auth_cubit.dart';
import '../../models/user_profile.dart';
import '../../models/player_profile.dart';
import '../../models/coach_profile.dart';
import '../../repositories/user_repository.dart';
import 'enhanced_profile_edit_screen.dart';
import '../../routing/routes.dart';

/// Enhanced profile screen with preview and edit functionality
class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  @override
  void initState() {
    super.initState();
    // Ensure profile is loaded when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().refreshUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is UserSignedOut) {
            // Navigate to login screen when user logs out
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.loginScreen,
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is AuthenticatedWithProfile) {
            return _buildProfileContent(state.userProfile);
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserSignedOut) {
            // Show loading while navigating - don't show profile content
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthInitial) {
            // Show loading for initial state
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthError) {
            return _buildErrorState(state.message);
          } else if (state is UserNeedsOnboarding) {
            // User needs to complete onboarding
            return _buildErrorState(
                'Profile setup incomplete. Please complete your profile.');
          } else {
            // For any other state, try to refresh the profile once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AuthCubit>().refreshUserProfile();
            });
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(profile),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(profile),
                Gap(24.h),
                _buildAboutSection(profile),
                Gap(24.h),
                _buildSportsSection(profile),
                Gap(24.h),
                _buildPhotoGallery(profile),
                Gap(24.h),
                _buildTeamsSection(profile),
                Gap(24.h),
                _buildVenuesSection(profile),
                Gap(24.h),
                _buildTournamentsSection(profile),
                Gap(24.h),
                _buildLogoutSection(),
                Gap(100.h), // Space for floating action button
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(UserProfile profile) {
    final photos = _getProfilePhotos(profile);

    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: ColorsManager.background,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main profile image - use profilePictureUrl instead of first photo
            if (profile.profilePictureUrl != null)
              CachedNetworkImage(
                imageUrl: profile.profilePictureUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            else if (photos.isNotEmpty)
              CachedNetworkImage(
                imageUrl: photos.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            else
              _buildDefaultAvatar(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Profile info overlay
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: TextStyles.font28White700Weight,
                  ),
                  Gap(4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16.sp,
                      ),
                      Gap(4.w),
                      Text(
                        profile.location,
                        style: TextStyles.font16White400Weight,
                      ),
                      Gap(16.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          profile.role.displayName,
                          style: TextStyles.font12White600Weight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToEdit(profile),
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Profile',
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ColorsManager.surface,
      child: Icon(
        Icons.person,
        size: 100.sp,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildBasicInfo(UserProfile profile) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(16.h),
          _buildInfoRow(Icons.person, 'Full Name', profile.fullName),
          _buildInfoRow(
              Icons.alternate_email, 'Nickname', _getNickname(profile)),
          _buildInfoRow(Icons.cake, 'Age', '${profile.age} years old'),
          _buildInfoRow(Icons.wc, 'Gender', profile.gender.displayName),
          _buildInfoRow(Icons.location_on, 'Location', profile.location),
        ],
      ),
    );
  }

  Widget _buildAboutSection(UserProfile profile) {
    final about = _getAbout(profile);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Me',
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(12.h),
          Text(
            about.isNotEmpty ? about : 'No bio added yet.',
            style: TextStyles.font14Grey400Weight,
            maxLines: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSection(UserProfile profile) {
    final sports = _getSportsOfInterest(profile);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sports of Interest',
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(12.h),
          if (sports.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: sports.map((sport) => _buildSportChip(sport)).toList(),
            )
          else
            Text(
              'No sports selected yet.',
              style: TextStyles.font14Grey400Weight,
            ),
        ],
      ),
    );
  }

  Widget _buildSportChip(String sport) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ColorsManager.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        sport,
        style: TextStyles.font12DarkBlue600Weight.copyWith(
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(UserProfile profile) {
    final photos = _getProfilePhotos(profile);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos (${photos.length}/5)',
                style: TextStyles.font18DarkBlueBold,
              ),
              if (photos.length < 5)
                TextButton.icon(
                  onPressed: () => _navigateToEdit(profile),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add'),
                ),
            ],
          ),
          Gap(8.h),
          if (photos.isNotEmpty)
            Text(
              'Tap and hold a photo to set as main profile photo',
              style: TextStyles.font12Grey400Weight,
            ),
          Gap(16.h),
          if (photos.isNotEmpty)
            _buildPhotoGrid(photos, profile)
          else
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, color: Colors.grey[400]),
                    Gap(8.h),
                    Text(
                      'No photos added yet',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photos, UserProfile profile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isMainPhoto = photo == profile.profilePictureUrl;

        return GestureDetector(
          onLongPress: () => _showSetMainPhotoDialog(photo, profile),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: isMainPhoto
                      ? Border.all(color: ColorsManager.primary, width: 3.w)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              if (isMainPhoto)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: ColorsManager.primary),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyles.font12Grey400Weight),
                Text(value, style: TextStyles.font14DarkBlue600Weight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(UserProfile profile) {
    return FutureBuilder<List<dynamic>>(
      future: _getUserTeams(profile.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionLoadingState('Teams');
        }

        final teams = snapshot.data ?? [];
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.groups, color: ColorsManager.primary, size: 24.sp),
                  Gap(8.w),
                  Text(
                    'Teams (${teams.length})',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                ],
              ),
              Gap(16.h),
              if (teams.isEmpty)
                Text(
                  'Not part of any team yet',
                  style: TextStyles.font14Grey400Weight,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teams.length,
                  separatorBuilder: (context, index) => Gap(8.h),
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return _buildTeamItem(team);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVenuesSection(UserProfile profile) {
    return FutureBuilder<List<dynamic>>(
      future: _getUserVenues(profile.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionLoadingState('Venues');
        }

        final venues = snapshot.data ?? [];
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city,
                      color: ColorsManager.primary, size: 24.sp),
                  Gap(8.w),
                  Text(
                    'Venues Played (${venues.length})',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                ],
              ),
              Gap(16.h),
              if (venues.isEmpty)
                Text(
                  'No venues booked yet',
                  style: TextStyles.font14Grey400Weight,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: venues.length,
                  separatorBuilder: (context, index) => Gap(8.h),
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return _buildVenueItem(venue);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTournamentsSection(UserProfile profile) {
    return FutureBuilder<List<dynamic>>(
      future: _getUserTournaments(profile.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionLoadingState('Tournaments');
        }

        final tournaments = snapshot.data ?? [];
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: ColorsManager.primary, size: 24.sp),
                  Gap(8.w),
                  Text(
                    'Tournaments (${tournaments.length})',
                    style: TextStyles.font18DarkBlueBold,
                  ),
                ],
              ),
              Gap(16.h),
              if (tournaments.isEmpty)
                Text(
                  'No tournaments participated yet',
                  style: TextStyles.font14Grey400Weight,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tournaments.length,
                  separatorBuilder: (context, index) => Gap(8.h),
                  itemBuilder: (context, index) {
                    final tournament = tournaments[index];
                    return _buildTournamentItem(tournament);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLoadingState(String sectionName) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionName,
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(16.h),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTeamItem(Map<String, dynamic> team) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: ColorsManager.primary, size: 20.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team['name'] ?? 'Unknown Team',
                  style: TextStyles.font14DarkBlueBold,
                ),
                if (team['sport'] != null)
                  Text(
                    team['sport'],
                    style: TextStyles.font12Grey400Weight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueItem(Map<String, dynamic> venue) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.stadium, color: ColorsManager.primary, size: 20.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue['venueTitle'] ?? 'Unknown Venue',
                  style: TextStyles.font14DarkBlueBold,
                ),
                if (venue['selectedDate'] != null)
                  Text(
                    'Played on: ${_formatVenueDate(venue['selectedDate'])}',
                    style: TextStyles.font12Grey400Weight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentItem(Map<String, dynamic> tournament) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: ColorsManager.primary, size: 20.sp),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament['name'] ?? 'Unknown Tournament',
                  style: TextStyles.font14DarkBlueBold,
                ),
                if (tournament['sport'] != null)
                  Text(
                    tournament['sport'],
                    style: TextStyles.font12Grey400Weight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to fetch data
  Future<List<Map<String, dynamic>>> _getUserTeams(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('memberIds', arrayContains: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? 'Unknown',
                'sport': doc.data()['sport'] ?? '',
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading teams: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserVenues(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('venue_bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .orderBy('selectedDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'venueTitle': doc.data()['venueTitle'] ?? 'Unknown',
                'selectedDate': doc.data()['selectedDate'],
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading venues: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserTournaments(String userId) async {
    try {
      // Get all tournaments where user is a participant
      final tournamentsSnapshot =
          await FirebaseFirestore.instance.collection('tournaments').get();

      final userTournaments = <Map<String, dynamic>>[];

      for (final doc in tournamentsSnapshot.docs) {
        final data = doc.data();
        final teams =
            (data['teams'] as List?)?.map((t) => t['id'] as String).toList() ??
                [];

        // Check if user is in any team participating in this tournament
        final userTeamsSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .where('memberIds', arrayContains: userId)
            .get();

        final userTeamIds = userTeamsSnapshot.docs.map((d) => d.id).toList();

        if (teams.any((teamId) => userTeamIds.contains(teamId))) {
          userTournaments.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'sport': data['sport'] ?? '',
          });
        }
      }

      return userTournaments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading tournaments: $e');
      }
      return [];
    }
  }

  String _formatVenueDate(dynamic date) {
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(16.h),
          SizedBox(
            width: double.infinity,
            child: AppTextButton(
              buttonText: 'Logout',
              textStyle: TextStyles.font16WhiteSemiBold,
              backgroundColor: ColorsManager.error,
              onPressed: () => _showLogoutDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState([String? errorMessage]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.grey[400]),
          Gap(16.h),
          Text(
            errorMessage ?? 'Failed to load profile',
            style: TextStyles.font16DarkBlue600Weight,
            textAlign: TextAlign.center,
          ),
          Gap(16.h),
          AppTextButton(
            buttonText: 'Retry',
            textStyle: TextStyles.font14White600Weight,
            onPressed: () => context.read<AuthCubit>().refreshUserProfile(),
          ),
        ],
      ),
    );
  }

  // Helper methods to extract data from profile
  List<String> _getProfilePhotos(UserProfile profile) {
    // Return all profile photos
    if (profile.profilePhotos.isNotEmpty) {
      return profile.profilePhotos;
    }
    // Fallback to profile picture if no photos array
    if (profile.profilePictureUrl != null) {
      return [profile.profilePictureUrl!];
    }
    return [];
  }

  String _getNickname(UserProfile profile) {
    // Return the actual nickname from profile, or first name as fallback
    return profile.nickname ?? profile.fullName.split(' ').first;
  }

  String _getAbout(UserProfile profile) {
    // Return the actual bio from the profile, or a default if empty
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      return profile.bio!;
    }
    return 'Sports enthusiast and ${profile.role.displayName.toLowerCase()} looking to connect with like-minded people.';
  }

  List<String> _getSportsOfInterest(UserProfile profile) {
    if (profile is PlayerProfile) {
      return profile.sportsOfInterest;
    } else if (profile is CoachProfile) {
      return profile.specializationSports;
    }
    return [];
  }

  void _navigateToEdit(UserProfile profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProfileEditScreen(userProfile: profile),
      ),
    );

    // Refresh profile if edit was successful
    if (result == true && mounted) {
      context.read<AuthCubit>().refreshUserProfile();
    }
  }

  void _showSetMainPhotoDialog(String photoUrl, UserProfile profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Main Photo'),
          content: const Text(
              'Do you want to set this photo as your main profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _setMainPhoto(photoUrl, profile);
              },
              child: const Text('Set as Main'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setMainPhoto(String photoUrl, UserProfile profile) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating main photo...')),
        );
      }

      // Update profile with new main photo
      if (profile is PlayerProfile) {
        final updatedProfile = PlayerProfile(
          uid: profile.uid,
          fullName: profile.fullName,
          nickname: profile.nickname,
          bio: profile.bio,
          gender: profile.gender,
          age: profile.age,
          location: profile.location,
          profilePictureUrl: photoUrl, // Set new main photo
          profilePhotos: profile.profilePhotos,
          isProfileComplete: profile.isProfileComplete,
          teamId: profile.teamId,
          createdAt: profile.createdAt,
          updatedAt: DateTime.now(),
          sportsOfInterest: profile.sportsOfInterest,
          skillLevel: profile.skillLevel,
          availability: profile.availability,
          preferredTrainingType: profile.preferredTrainingType,
        );
        await _userRepository.updateUserProfile(
            profile.uid, updatedProfile.toFirestore());
      } else if (profile is CoachProfile) {
        final updatedProfile = CoachProfile(
          uid: profile.uid,
          fullName: profile.fullName,
          nickname: profile.nickname,
          gender: profile.gender,
          age: profile.age,
          location: profile.location,
          profilePictureUrl: photoUrl, // Set new main photo
          profilePhotos: profile.profilePhotos,
          isProfileComplete: profile.isProfileComplete,
          teamId: profile.teamId,
          createdAt: profile.createdAt,
          updatedAt: DateTime.now(),
          specializationSports: profile.specializationSports,
          experienceYears: profile.experienceYears,
          hourlyRate: profile.hourlyRate,
          availableTimeSlots: profile.availableTimeSlots,
          coachingType: profile.coachingType,
          certifications: profile.certifications,
          bio: profile.bio,
        );
        await _userRepository.updateUserProfile(
            profile.uid, updatedProfile.toFirestore());
      }

      // Refresh profile
      if (mounted) {
        context.read<AuthCubit>().refreshUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Main photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update main photo: $e')),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorsManager.surface,
          title: Text(
            'Logout',
            style: TextStyles.font18DarkBlueBold,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyles.font14DarkBlue600Weight,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyles.font14MainBlue500Weight,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                // Sign out
                context.read<AuthCubit>().signOut();
              },
              child: Text(
                'Logout',
                style: TextStyles.font14MainBlue500Weight.copyWith(
                  color: ColorsManager.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
