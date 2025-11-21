import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/utils/image_utils.dart';
import '../../core/widgets/app_text_button.dart';
import '../../logic/cubit/auth_cubit.dart';
import '../../models/coach_profile.dart';
import '../../models/player_profile.dart';
import '../../models/user_profile.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../modules/booking/screens/my_booking_history_screen.dart';
import '../../modules/booking/screens/coach_earnings_screen.dart';
import '../../modules/venue/screens/my_venue_bookings_screen.dart';
import '../../modules/team/models/models.dart';
import '../../modules/tournament/models/models.dart';
import 'services/profile_data_service.dart';
import 'widgets/profile_connections_widget.dart';
import 'widgets/profile_teams_widget.dart';
import 'widgets/profile_tournaments_widget.dart';

/// Enhanced profile screen showing comprehensive user information
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileDataService _profileDataService = ProfileDataService();

  List<UserProfile> _connectedUsers = [];
  List<Team> _userTeams = [];
  List<Tournament> _pastTournaments = [];
  List<Tournament> _upcomingTournaments = [];

  bool _isLoadingConnections = true;
  bool _isLoadingTeams = true;
  bool _isLoadingTournaments = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Load all profile data concurrently
    await Future.wait([
      _loadConnections(),
      _loadTeams(),
      _loadTournaments(),
    ]);
  }

  Future<void> _loadConnections() async {
    try {
      final connections = await _profileDataService.getAllConnectedUsers();
      if (mounted) {
        setState(() {
          _connectedUsers = connections;
          _isLoadingConnections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConnections = false;
        });
      }
    }
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _profileDataService.getUserTeams();
      if (mounted) {
        setState(() {
          _userTeams = teams;
          _isLoadingTeams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeams = false;
        });
      }
    }
  }

  Future<void> _loadTournaments() async {
    try {
      final pastTournaments =
          await _profileDataService.getUserPastTournaments();
      final upcomingTournaments =
          await _profileDataService.getUserUpcomingTournaments();

      if (mounted) {
        setState(() {
          _pastTournaments = pastTournaments;
          _upcomingTournaments = upcomingTournaments;
          _isLoadingTournaments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthenticatedWithProfile) {
            return _buildProfileContent(context, state.userProfile);
          } else if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            // Try to refresh the user profile if we're not in the right state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AuthCubit>().refreshUserProfile();
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildProfileHeader(profile),
            Gap(24.h),
            _buildProfileInfo(profile),
            Gap(24.h),

            // Connections Section
            ProfileConnectionsWidget(
              connectedUsers: _connectedUsers,
              isLoading: _isLoadingConnections,
            ),
            Gap(16.h),

            // Teams Section
            ProfileTeamsWidget(
              teams: _userTeams,
              isLoading: _isLoadingTeams,
            ),
            Gap(16.h),

            // Tournaments Section
            ProfileTournamentsWidget(
              pastTournaments: _pastTournaments,
              upcomingTournaments: _upcomingTournaments,
              isLoading: _isLoadingTournaments,
            ),
            Gap(24.h),

            _buildActionButtons(context, profile),
            Gap(32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Column(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorsManager.mainBlue.withValues(alpha: 0.1),
          ),
          child: ImageUtils.buildSafeCachedImage(
            imageUrl: profile.profilePictureUrl ?? '',
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(50.r),
            fallbackIcon: Icons.person,
            fallbackIconColor: ColorsManager.mainBlue,
            fallbackIconSize: 50.sp,
          ),
        ),
        Gap(16.h),
        Text(
          profile.fullName,
          style: TextStyles.font24Blue700Weight,
          textAlign: TextAlign.center,
        ),
        Gap(8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _getRoleColor(profile.role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            profile.role.displayName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(profile.role),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(16.h),
          _buildInfoRow(Icons.person, 'Full Name', profile.fullName),
          _buildInfoRow(Icons.cake, 'Age', '${profile.age} years old'),
          _buildInfoRow(Icons.wc, 'Gender', profile.gender.displayName),
          _buildInfoRow(Icons.location_on, 'Location', profile.location),
          _buildInfoRow(Icons.badge, 'Role', profile.role.displayName),
          if (profile is PlayerProfile) ...[
            Gap(12.h),
            Divider(color: Colors.grey[300]),
            Gap(12.h),
            Text(
              'Player Details',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            Gap(8.h),
            _buildInfoRow(
              Icons.sports,
              'Sports of Interest',
              profile.sportsOfInterest.join(', '),
            ),
            _buildInfoRow(
              Icons.trending_up,
              'Skill Level',
              profile.skillLevel.displayName,
            ),
            _buildInfoRow(
              Icons.fitness_center,
              'Training Type',
              profile.preferredTrainingType.displayName,
            ),
          ],
          if (profile is CoachProfile) ...[
            Gap(12.h),
            Divider(color: Colors.grey[300]),
            Gap(12.h),
            Text(
              'Coach Details',
              style: TextStyles.font16DarkBlue600Weight,
            ),
            Gap(8.h),
            _buildInfoRow(
              Icons.sports,
              'Specialization',
              profile.specializationSports.join(', '),
            ),
            _buildInfoRow(
              Icons.work,
              'Experience',
              '${profile.experienceYears} years',
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Hourly Rate',
              '\$${profile.hourlyRate.toStringAsFixed(0)}/hour',
            ),
            if (profile.certifications != null &&
                profile.certifications!.isNotEmpty)
              _buildInfoRow(
                Icons.verified,
                'Certifications',
                profile.certifications?.join(', ') ?? '',
              ),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              _buildInfoRow(
                Icons.info,
                'Bio',
                profile.bio ?? '',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: ColorsManager.mainBlue,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.font12Grey400Weight,
                ),
                Gap(2.h),
                Text(
                  value,
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        AppTextButton(
          buttonText: 'Edit Profile',
          textStyle: TextStyles.font16WhiteSemiBold,
          onPressed: () {
            // TODO: Navigate to edit profile screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edit profile feature coming soon!'),
              ),
            );
          },
        ),
        Gap(16.h),
        AppTextButton(
          buttonText: 'My Bookings',
          textStyle: TextStyles.font16WhiteSemiBold,
          backgroundColor: Colors.green,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyBookingHistoryScreen(),
              ),
            );
          },
        ),
        Gap(16.h),
        AppTextButton(
          buttonText: 'My Venue Bookings',
          textStyle: TextStyles.font16WhiteSemiBold,
          backgroundColor: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyVenueBookingsScreen(),
              ),
            );
          },
        ),
        // Show earnings dashboard for coaches
        if (profile.role == UserRole.coach ||
            profile.role == UserRole.admin) ...[
          Gap(16.h),
          AppTextButton(
            buttonText: 'Earnings Dashboard',
            textStyle: TextStyles.font16WhiteSemiBold,
            backgroundColor: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachEarningsScreen(),
                ),
              );
            },
          ),
        ],
        Gap(16.h),
        AppTextButton(
          buttonText: 'Settings',
          textStyle: TextStyles.font16WhiteSemiBold,
          backgroundColor: Colors.grey[600],
          onPressed: () {
            // TODO: Navigate to settings screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings feature coming soon!'),
              ),
            );
          },
        ),
        Gap(32.h),
        TextButton(
          onPressed: () {
            context.read<AuthCubit>().signOut();
          },
          child: Text(
            'Sign Out',
            style: TextStyles.font16BlueRegular.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.player:
        return Colors.green;
      case UserRole.coach:
        return Colors.blue;
      case UserRole.admin:
        return Colors.purple;
    }
  }
}
