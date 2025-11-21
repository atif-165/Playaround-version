import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../cubit/team_cubit.dart';
import '../models/team_model.dart';

const _teamHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  SportType _selectedSport = SportType.football;
  bool _isPublic = true;
  int? _maxPlayers;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Team',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _teamHeroGradient),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: BlocListener<TeamCubit, TeamState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {
              setState(() {
                _isLoading = true;
              });
            },
            loaded: (teams) {
              setState(() {
                _isLoading = false;
              });
            },
            userTeamsLoaded: (teams) {
              setState(() {
                _isLoading = false;
              });
            },
            searchResults: (teams) {
              setState(() {
                _isLoading = false;
              });
            },
            teamDetails: (team) {
              setState(() {
                _isLoading = false;
              });
            },
            teamCreated: (teamId) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Team created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            teamUpdated: () {
              setState(() {
                _isLoading = false;
              });
            },
            teamDeleted: () {
              setState(() {
                _isLoading = false;
              });
            },
            playerAdded: () {
              setState(() {
                _isLoading = false;
              });
            },
            playerRemoved: () {
              setState(() {
                _isLoading = false;
              });
            },
            error: (message) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
        },
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamNameField(),
                Gap(20.h),
                _buildSportSelection(),
                Gap(20.h),
                _buildCityField(),
                Gap(20.h),
                _buildDescriptionField(),
                Gap(20.h),
                _buildMaxPlayersField(),
                Gap(20.h),
                _buildVisibilityToggle(),
                Gap(32.h),
                _buildCreateButton(),
              ],
            ),
          ),
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildTeamNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Name *',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter team name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              Icons.groups,
              color: Colors.grey[400],
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Team name is required';
            }
            if (value.trim().length < 3) {
              return 'Team name must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSportSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type *',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SportType>(
              value: _selectedSport,
              isExpanded: true,
              dropdownColor: PublicProfileTheme.panelColor,
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              items: SportType.values.map((sport) {
                return DropdownMenuItem<SportType>(
                  value: sport,
                  child: Row(
                    children: [
                      Icon(
                        _getSportIcon(sport),
                        color: ColorsManager.mainBlue,
                        size: 20.sp,
                      ),
                      Gap(12.w),
                      Text(sport.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (SportType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSport = newValue;
                    _maxPlayers = _getDefaultMaxPlayers(newValue);
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _cityController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter city name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              Icons.location_on,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tell us about your team...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaxPlayersField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Players',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          initialValue: _maxPlayers?.toString() ??
              _getDefaultMaxPlayers(_selectedSport).toString(),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter maximum number of players',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              Icons.people,
              color: Colors.grey[400],
            ),
          ),
          onChanged: (value) {
            _maxPlayers = int.tryParse(value);
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final number = int.tryParse(value);
              if (number == null || number < 2 || number > 50) {
                return 'Please enter a number between 2 and 50';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Public Team',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
          activeColor: ColorsManager.mainBlue,
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Create Team',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _createTeam() {
    if (_formKey.currentState!.validate()) {
      context.read<TeamCubit>().createTeam(
            name: _nameController.text.trim(),
            sportType: _selectedSport,
            city: _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            isPublic: _isPublic,
            maxPlayers: _maxPlayers,
          );
    }
  }

  IconData _getSportIcon(SportType sportType) {
    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.cricket:
        return Icons.sports_cricket;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.badminton:
        return Icons.sports_tennis;
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.hockey:
        return Icons.sports_hockey;
      case SportType.rugby:
        return Icons.sports_rugby;
      case SportType.baseball:
        return Icons.sports_baseball;
      default:
        return Icons.sports;
    }
  }

  int _getDefaultMaxPlayers(SportType sportType) {
    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return 11;
      case SportType.basketball:
        return 5;
      case SportType.cricket:
        return 11;
      case SportType.volleyball:
        return 6;
      case SportType.hockey:
        return 6;
      case SportType.rugby:
        return 15;
      case SportType.baseball:
        return 9;
      case SportType.tennis:
      case SportType.badminton:
        return 2;
      default:
        return 11;
    }
  }
}
