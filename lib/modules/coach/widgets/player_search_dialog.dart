import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_form_field.dart';
import '../../../models/player_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/coach_associations_service.dart';

/// Dialog for searching and inviting players to connect with a coach profile.
class PlayerSearchDialog extends StatefulWidget {
  final String coachId;
  final String coachName;

  const PlayerSearchDialog({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<PlayerSearchDialog> createState() => _PlayerSearchDialogState();
}

class _PlayerSearchDialogState extends State<PlayerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final CoachAssociationsService _associationsService =
      CoachAssociationsService();

  List<PlayerProfile> _players = [];
  bool _isLoading = false;
  String? _requestingPlayerId;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().length < 2) {
      setState(() {
        _players = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlayers();
    });
  }

  Future<void> _searchPlayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final players =
          await _associationsService.searchPlayers(_searchController.text);
      if (mounted) {
        setState(() {
          _players = players;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching players: $error')),
      );
    }
  }

  Future<void> _requestPlayer(PlayerProfile player) async {
    setState(() {
      _requestingPlayerId = player.uid;
    });

    try {
      final success = await _associationsService.requestPlayerAssociation(
        widget.coachId,
        widget.coachName,
        player,
      );

      if (!mounted) return;
      setState(() {
        _requestingPlayerId = null;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${player.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player already added or request failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestingPlayerId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(16.h),
            _buildSearchField(),
            Gap(16.h),
            Expanded(child: _buildPlayersList()),
            Gap(16.h),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.person_add_alt_1,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            'Invite Player',
            style: TextStyles.font18DarkBlueBold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      style: TextStyles.font14DarkBlue500Weight,
      decoration: InputDecoration(
        hintText: 'Search players by name or nickname...',
        hintStyle: TextStyles.font14Hint500Weight,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isLoading
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _players = [];
                      });
                    },
                  )
                : null,
        filled: true,
        fillColor: ColorsManager.lightShadeOfGray,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.gray93Color,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.mainBlue,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    if (_searchController.text.trim().length < 2) {
      return _buildPlaceholder(
        icon: Icons.search,
        message: 'Type at least 2 characters to search for players',
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_players.isEmpty) {
      return _buildPlaceholder(
        icon: Icons.person_off,
        message: 'No players found matching your search',
      );
    }

    return ListView.builder(
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return _buildPlayerCard(player);
      },
    );
  }

  Widget _buildPlayerCard(PlayerProfile player) {
    final requesting = _requestingPlayerId == player.uid;
    final avatarUrl = player.profilePictureUrl;
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: requesting ? null : () => _requestPlayer(player),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: ColorsManager.primary.withAlpha(40),
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(Icons.person, color: ColorsManager.primary, size: 28.sp)
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: TextStyles.font16DarkBlue500Weight,
                    ),
                    if (player.nickname != null && player.nickname!.isNotEmpty)
                      Text(
                        '@${player.nickname}',
                        style: TextStyles.font12Grey400Weight,
                      ),
                    Gap(4.h),
                    Text(
                      '${player.age} • ${player.location}',
                      style: TextStyles.font12Grey400Weight,
                    ),
                    Gap(8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: player.sportsOfInterest
                          .take(3)
                          .map(
                            (sport) => Chip(
                              label: Text(sport),
                              labelStyle: TextStyles.font10DarkBlue500Weight,
                              backgroundColor:
                                  ColorsManager.surfaceVariant.withOpacity(0.35),
                            ),
                          )
                          .toList(),
                    ),
                    Gap(8.h),
                    Text(
                      'Preferred training: ${player.preferredTrainingType.displayName}',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              ElevatedButton(
                onPressed: requesting ? null : () => _requestPlayer(player),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: requesting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.sp, color: Colors.grey),
            Gap(16.h),
            Text(
              message,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

