import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../scripts/create_dummy_tournament.dart';
import '../scripts/create_multi_sport_dummy_tournaments.dart';

/// Debug screen for tournament testing and development
/// This screen provides utilities for creating and managing dummy tournaments
class TournamentDebugScreen extends StatefulWidget {
  const TournamentDebugScreen({super.key});

  @override
  State<TournamentDebugScreen> createState() => _TournamentDebugScreenState();
}

class _TournamentDebugScreenState extends State<TournamentDebugScreen> {
  bool _isLoading = false;
  bool _isCreatingMultiple = false;
  String? _lastCreatedTournamentId;
  List<String>? _lastCreatedTournamentIds;
  String? _message;
  bool _isSuccess = true;

  Future<void> _createDummyTournament() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final creator = CreateDummyTournament();
      final tournamentId = await creator.createDummyTournament();

      setState(() {
        _isLoading = false;
        _lastCreatedTournamentId = tournamentId;
        _message =
            'Dummy tournament created successfully!\nTournament ID: $tournamentId';
        _isSuccess = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dummy tournament created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error creating dummy tournament:\n$e';
        _isSuccess = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createAllSportsTournaments() async {
    setState(() {
      _isCreatingMultiple = true;
      _message = null;
    });

    try {
      final creator = CreateMultiSportDummyTournaments();
      final tournamentIds = await creator.createAllSportsTournaments();

      setState(() {
        _isCreatingMultiple = false;
        _lastCreatedTournamentIds = tournamentIds;
        _message =
            'Created ${tournamentIds.length} tournaments successfully!\nAll major sports now have live tournaments!';
        _isSuccess = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Created ${tournamentIds.length} live tournaments for all sports!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingMultiple = false;
        _message = 'Error creating tournaments:\n$e';
        _isSuccess = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tournaments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDummyTournament() async {
    if (_lastCreatedTournamentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tournament to delete. Create one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final creator = CreateDummyTournament();
      await creator.deleteDummyTournament(_lastCreatedTournamentId!);

      setState(() {
        _isLoading = false;
        _message = 'Tournament deleted successfully!';
        _isSuccess = true;
        _lastCreatedTournamentId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error deleting tournament:\n$e';
        _isSuccess = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Debug'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.bug_report,
                  size: 64.sp,
                  color: ColorsManager.mainBlue,
                ),
                Gap(16.h),
                Text(
                  'Tournament Testing Tools',
                  style: TextStyles.font24DarkBlue600Weight.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap(8.h),
                Text(
                  'Create and manage dummy tournaments for testing',
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap(32.h),

                // Create Tournament Button
                ElevatedButton.icon(
                  onPressed: _isLoading || _isCreatingMultiple
                      ? null
                      : _createDummyTournament,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(
                    _isLoading
                        ? 'Creating...'
                        : 'Create Dummy Tournament (Football)',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),

                Gap(16.h),

                // Create All Sports Tournaments Button
                ElevatedButton.icon(
                  onPressed: _isLoading || _isCreatingMultiple
                      ? null
                      : _createAllSportsTournaments,
                  icon: _isCreatingMultiple
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sports),
                  label: Text(
                    _isCreatingMultiple
                        ? 'Creating All Sports...'
                        : 'Create ALL SPORTS Tournaments',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),

                Gap(16.h),

                // Delete Tournament Button
                ElevatedButton.icon(
                  onPressed: _isLoading ||
                          _isCreatingMultiple ||
                          _lastCreatedTournamentId == null
                      ? null
                      : _deleteDummyTournament,
                  icon: const Icon(Icons.delete),
                  label: Text(
                    'Delete Last Tournament',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),

                Gap(24.h),

                // Info Container
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: ColorsManager.mainBlue,
                            size: 20.sp,
                          ),
                          Gap(8.w),
                          Text(
                            'What gets created:',
                            style: TextStyles.font16DarkBlue600Weight.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Gap(12.h),
                      _buildInfoItem('Single Tournament:'),
                      _buildInfoItem('• A football league tournament'),
                      _buildInfoItem('• 6 sample teams'),
                      _buildInfoItem(
                          '• 6 matches (2 completed, 1 live, 3 scheduled)'),
                      Gap(8.h),
                      _buildInfoItem('All Sports Tournaments:'),
                      _buildInfoItem(
                          '• 10 tournaments (Cricket, Football, Basketball, Tennis, Badminton, Volleyball, Hockey, Rugby, Baseball, Soccer)'),
                      _buildInfoItem(
                          '• Each with 4 matches (1 completed, 1 live, 2 scheduled)'),
                      _buildInfoItem('• Sport-specific commentary and scoring'),
                      _buildInfoItem('• All tournaments set to RUNNING status'),
                    ],
                  ),
                ),

                if (_message != null) ...[
                  Gap(24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green : Colors.red,
                          size: 24.sp,
                        ),
                        Gap(12.w),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _isSuccess ? Colors.green : Colors.red,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_lastCreatedTournamentId != null) ...[
                  Gap(16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Created Tournament:',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(4.h),
                        SelectableText(
                          _lastCreatedTournamentId!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_lastCreatedTournamentIds != null &&
                    _lastCreatedTournamentIds!.isNotEmpty) ...[
                  Gap(16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created ${_lastCreatedTournamentIds!.length} Sport Tournaments:',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(8.h),
                        Text(
                          '✅ Cricket\n✅ Football\n✅ Basketball\n✅ Tennis\n✅ Badminton\n✅ Volleyball\n✅ Hockey\n✅ Rugby\n✅ Baseball\n✅ Soccer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
