import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../services/tournament_service.dart';
import '../services/tournament_permission_service.dart';
import '../widgets/tournament_card.dart';
import 'tournament_detail_screen.dart';
import 'create_tournament_screen.dart';

/// Screen displaying list of tournaments
class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _tournamentService = TournamentService();
  final TournamentPermissionService _permissionService = TournamentPermissionService();
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  UserProfile? _currentUserProfile;
  TournamentCreationPermission? _creationPermission;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTournaments();
  }

  void _loadUserProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
      await _checkCreationPermission();
    }
  }

  Future<void> _checkCreationPermission() async {
    final permission = await _permissionService.checkTournamentCreationPermission(
      _currentUserProfile,
    );
    setState(() {
      _creationPermission = permission;
    });
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _tournamentService.getPublicTournaments().listen((tournaments) {
        if (mounted) {
          setState(() {
            _tournaments = tournaments;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tournaments: ${e.toString()}'),
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
        title: Text(
          'Tournaments',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_canCreateTournament())
            IconButton(
              onPressed: _handleCreateTournament,
              icon: const Icon(
                Icons.add,
                color: ColorsManager.mainBlue,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomProgressIndicator())
          : _buildTournamentsList(),
      floatingActionButton: _canCreateTournament()
          ? FloatingActionButton(
              heroTag: "tournaments_fab",
              onPressed: _handleCreateTournament,
              backgroundColor: ColorsManager.primary,
              child: const Icon(Icons.emoji_events, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTournamentsList() {
    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            Gap(16.h),
            Text(
              'No tournaments available',
              style: TextStyles.font18DarkBlueBold,
            ),
            Gap(8.h),
            Text(
              'Check back later for upcoming tournaments',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
            if (_canCreateTournament()) ...[
              Gap(24.h),
              ElevatedButton.icon(
                onPressed: _handleCreateTournament,
                icon: const Icon(Icons.add),
                label: const Text('Create Tournament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final tournament = _tournaments[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: TournamentCard(
              tournament: tournament,
              onTap: () => _navigateToTournamentDetails(tournament),
            ),
          );
        },
      ),
    );
  }

  bool _canCreateTournament() {
    return _creationPermission?.canCreate ?? false;
  }

  void _handleCreateTournament() {
    if (_creationPermission?.canCreate == true) {
      _navigateToCreateTournament();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _navigateToCreateTournament() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTournamentScreen(),
      ),
    ).then((_) {
      // Refresh tournaments list when returning
      _loadTournaments();
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permission Required',
          style: TextStyles.font18DarkBlueBold,
        ),
        content: Text(
          _permissionService.getPermissionDenialMessage(),
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyles.font14MainBlue500Weight,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(tournament: tournament),
      ),
    );
  }
}
