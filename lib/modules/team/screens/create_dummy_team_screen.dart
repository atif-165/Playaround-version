import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/team_dummy_data.dart';
import 'team_profile_screen.dart';
import '../services/team_service.dart';

class CreateDummyTeamScreen extends StatefulWidget {
  const CreateDummyTeamScreen({super.key});

  @override
  State<CreateDummyTeamScreen> createState() => _CreateDummyTeamScreenState();
}

class _CreateDummyTeamScreenState extends State<CreateDummyTeamScreen> {
  final TeamDummyDataService _dummyService = TeamDummyDataService();
  final TeamService _teamService = TeamService();

  bool _isCreating = false;
  String? _createdTeamId;
  String? _errorMessage;

  Future<void> _createDummyTeam() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Create the dummy team with all data
      final teamId = await _dummyService.createFullDummyTeam();

      setState(() {
        _createdTeamId = teamId;
        _isCreating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dummy team created successfully with all data!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _viewTeam() async {
    if (_createdTeamId == null) return;

    try {
      final team = await _teamService.getTeamById(_createdTeamId!);
      if (team != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeamProfileScreen(team: team),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading team: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDummyTeam() async {
    if (_createdTeamId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dummy Team?'),
        content: const Text(
          'This will delete the team and all associated data (matches, join requests, etc.). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCreating = true);

    try {
      await _dummyService.deleteDummyData(_createdTeamId!);

      setState(() {
        _createdTeamId = null;
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dummy team deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Dummy Team Generator',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCreating
          ? const Center(child: CustomProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon
                  Icon(
                    Icons.science_outlined,
                    size: 80.sp,
                    color: ColorsManager.secondary,
                  ),
                  Gap(20.h),

                  // Title
                  Text(
                    'Test Team Admin Features',
                    style: TextStyles.font24DarkBlue600Weight,
                    textAlign: TextAlign.center,
                  ),
                  Gap(10.h),

                  // Description
                  Text(
                    'Generate a complete dummy team with all features to test admin capabilities',
                    style: TextStyles.font14Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                  Gap(30.h),

                  // What will be created
                  _buildInfoCard(
                    title: 'What will be created:',
                    items: [
                      '⚽ Thunder Warriors FC (Football Team)',
                      '👥 11 dummy players with positions',
                      '👨‍🏫 3 coaches (1 head coach)',
                      '🏆 4 matches (2 completed, 1 live, 1 upcoming)',
                      '📊 Team statistics and records',
                      '📨 3 pending join requests',
                      '🔧 Full admin access for testing',
                    ],
                  ),
                  Gap(20.h),

                  // Features you can test
                  _buildInfoCard(
                    title: 'Admin features you can test:',
                    items: [
                      '✏️ Edit team name, bio, description',
                      '🖼️ Upload team logo and banner',
                      '👥 Manage team members (add/remove)',
                      '⭐ Assign captain and head coach',
                      '📨 Accept/reject join requests',
                      '⚽ View and manage matches',
                      '📊 Track team statistics',
                      '🏅 Assign jersey numbers and positions',
                    ],
                  ),
                  Gap(30.h),

                  // Create button
                  if (_createdTeamId == null)
                    ElevatedButton.icon(
                      onPressed: _createDummyTeam,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Dummy Team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.secondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),

                  // Success state with actions
                  if (_createdTeamId != null) ...[
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 60.sp,
                            color: Colors.green,
                          ),
                          Gap(15.h),
                          Text(
                            'Dummy Team Created!',
                            style: TextStyles.font20DarkBlueBold.copyWith(
                              color: Colors.green.shade900,
                            ),
                          ),
                          Gap(10.h),
                          Text(
                            'You are the team owner/admin',
                            style: TextStyles.font14Grey400Weight,
                          ),
                          Gap(20.h),

                          // View Team Button
                          ElevatedButton.icon(
                            onPressed: _viewTeam,
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Team & Test Admin Access'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsManager.secondary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 14.h,
                                horizontal: 20.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                          Gap(10.h),

                          // Delete Button
                          OutlinedButton.icon(
                            onPressed: _deleteDummyTeam,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete Dummy Team'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(
                                vertical: 14.h,
                                horizontal: 20.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    Gap(20.h),
                    Container(
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyles.font14Grey400Weight.copyWith(
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],

                  Gap(30.h),

                  // Note
                  Container(
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20.sp,
                        ),
                        Gap(10.w),
                        Expanded(
                          child: Text(
                            'Note: The Firestore index for matches is building. Matches tab will work once the index is ready (usually 5-10 minutes).',
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16DarkBlue600Weight,
          ),
          Gap(10.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.substring(0, 2),
                    style: TextStyles.font14DarkBlue500Weight,
                  ),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      item.substring(3),
                      style: TextStyles.font14DarkBlue500Weight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
