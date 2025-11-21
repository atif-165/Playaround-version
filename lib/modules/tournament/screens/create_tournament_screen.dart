import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../helpers/extensions.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/listing_model.dart' as listing;
import '../../../models/user_profile.dart';
import '../../../models/venue_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../listing/widgets/sport_type_dropdown.dart';
import '../../team/models/team_model.dart' as team;
import '../models/tournament_model.dart';
import '../services/tournament_service.dart';
import '../widgets/venue_selector.dart';
import 'tournament_preview_screen.dart';
import '../../../theming/public_profile_theme.dart';

/// Enhanced screen for creating tournaments
class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentService = TournamentService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _locationController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _winningPrizeController = TextEditingController();
  final _rulesController = TextEditingController();

  // Form state
  listing.SportType? _selectedSportType;
  TournamentFormat _selectedFormat = TournamentFormat.singleElimination;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _registrationDeadline;
  VenueModel? _selectedVenue;
  bool _isLoading = false;
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Set default values
    _maxTeamsController.text = '8';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxTeamsController.dispose();
    _locationController.dispose();
    _entryFeeController.dispose();
    _winningPrizeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  void _loadUserProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Create Tournament',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CustomProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    24.w, kToolbarHeight + 24.h, 24.w, 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCard(_buildBasicInfo()),
                      Gap(20.h),
                      _buildCard(_buildTournamentDetails()),
                      Gap(20.h),
                      _buildCard(_buildDateTimeSection()),
                      Gap(20.h),
                      _buildCard(_buildAdditionalInfo()),
                      Gap(32.h),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: PublicProfileTheme.panelColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: child,
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        Gap(16.h),
        _buildTextField(
          controller: _nameController,
          label: 'Tournament Title',
          hint: 'e.g., Summer Cricket Championship',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tournament title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
        ),
        Gap(16.h),
        SportTypeDropdown(
          selectedSportType: _selectedSportType,
          onChanged: (sportType) {
            setState(() {
              _selectedSportType = sportType;
            });
          },
        ),
        Gap(16.h),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint:
              'Describe the tournament, rules, and what participants can expect...',
          maxLines: 4,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tournament description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTournamentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Details',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _maxTeamsController,
                label: 'Maximum Teams',
                hint: '8',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter max teams';
                  }
                  final teams = int.tryParse(value);
                  if (teams == null || teams < 4 || teams > 32) {
                    return 'Teams must be between 4 and 32';
                  }
                  return null;
                },
              ),
            ),
            Gap(16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Format',
                    style: TextStyles.font14DarkBlueMedium,
                  ),
                  Gap(8.h),
                  DropdownButtonFormField<TournamentFormat>(
                    value: _selectedFormat,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide:
                            const BorderSide(color: ColorsManager.mainBlue),
                      ),
                    ),
                    items: TournamentFormat.values.map((format) {
                      return DropdownMenuItem<TournamentFormat>(
                        value: format,
                        child: Text(format.displayName),
                      );
                    }).toList(),
                    onChanged: (format) {
                      if (format != null) {
                        setState(() {
                          _selectedFormat = format;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap(16.h),
        _buildTextField(
          controller: _locationController,
          label: 'Location (Optional)',
          hint: 'Tournament venue or city',
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyles.font18DarkBlueBold,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                label: 'Start Date & Time',
                value: _startDate != null && _startTime != null
                    ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} at ${_startTime!.format(context)}'
                    : 'Select date & time',
                onTap: _selectStartDateTime,
              ),
            ),
          ],
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                label: 'Registration Deadline',
                value: _registrationDeadline != null
                    ? DateFormat('MMM dd, yyyy').format(_registrationDeadline!)
                    : 'Select deadline',
                onTap: _selectRegistrationDeadline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Fees & Prizes',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _entryFeeController,
                label: 'Entry Fee (Required)',
                hint: '0.00',
                prefixText: '\$ ',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter entry fee (use 0 for free tournaments)';
                  }
                  final fee = double.tryParse(value);
                  if (fee == null || fee < 0) {
                    return 'Please enter a valid fee';
                  }
                  return null;
                },
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildTextField(
                controller: _winningPrizeController,
                label: 'Winning Prize (Required)',
                hint: '0.00',
                prefixText: '\$ ',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter winning prize (use 0 for no prize)';
                  }
                  final prize = double.tryParse(value);
                  if (prize == null || prize < 0) {
                    return 'Please enter a valid prize amount';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        Gap(24.h),
        Text(
          'Venue & Rules',
          style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
        ),
        Gap(16.h),
        VenueSelector(
          selectedVenue: _selectedVenue,
          sportType: _selectedSportType,
          onVenueSelected: (venue) {
            setState(() {
              _selectedVenue = venue;
            });
          },
        ),
        Gap(16.h),
        _buildTextField(
          controller: _rulesController,
          label: 'Tournament Rules (Required)',
          hint:
              'Specific rules, eligibility criteria, match format, scoring system...',
          maxLines: 4,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tournament rules';
            }
            if (value.trim().length < 20) {
              return 'Rules must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlueMedium.copyWith(color: Colors.white),
        ),
        Gap(8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlueMedium.copyWith(color: Colors.white),
        ),
        Gap(8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20.sp,
                  color: ColorsManager.mainBlue,
                ),
                Gap(12.w),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyles.font14DarkBlueMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: ColorsManager.mainBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewTournament,
                icon: const Icon(Icons.preview),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsManager.primary,
                  side: BorderSide(color: ColorsManager.primary),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            Gap(16.w),
            Expanded(
              child: AppTextButton(
                buttonText: 'Create Tournament',
                textStyle: TextStyles.font16WhiteSemiBold,
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
        Gap(16.h),
        OutlinedButton.icon(
          onPressed: _saveDraft,
          icon: const Icon(Icons.save),
          label: const Text('Save as Draft'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorsManager.textSecondary,
            side: BorderSide(color: ColorsManager.textSecondary),
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null && mounted) {
        setState(() {
          _startDate = date;
          _startTime = time;
        });
      }
    }
  }

  Future<void> _selectRegistrationDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate?.subtract(const Duration(days: 1)) ??
          DateTime.now().add(const Duration(days: 6)),
      firstDate: DateTime.now(),
      lastDate: _startDate?.subtract(const Duration(hours: 1)) ??
          DateTime.now().add(const Duration(days: 364)),
    );

    if (date != null) {
      setState(() {
        _registrationDeadline = date;
      });
    }
  }

  Future<void> _previewTournament() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSportType == null) {
      context.showSnackBar('Please select a sport type');
      return;
    }

    if (_startDate == null || _startTime == null) {
      context.showSnackBar('Please select start date and time');
      return;
    }

    if (_registrationDeadline == null) {
      context.showSnackBar('Please select registration deadline');
      return;
    }

    if (_registrationDeadline!.isAfter(_startDate!)) {
      context.showSnackBar('Registration deadline must be before start date');
      return;
    }

    if (_selectedVenue == null) {
      context.showSnackBar('Please select a venue for the tournament');
      return;
    }

    // Create preview tournament data
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final entryFee = double.parse(_entryFeeController.text.trim());
    final winningPrize = double.parse(_winningPrizeController.text.trim());

    final rules = _rulesController.text
        .trim()
        .split('\n')
        .where((rule) => rule.trim().isNotEmpty)
        .toList();

    // Convert listing SportType to team SportType
    final teamSportType = _convertToTeamSportType(_selectedSportType!);

    final previewTournament = Tournament(
      id: 'preview',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      sportType: teamSportType,
      format: _selectedFormat,
      status: TournamentStatus.upcoming,
      organizerId: _currentUserProfile?.uid ?? '',
      organizerName: _currentUserProfile?.displayName ?? 'Preview User',
      registrationStartDate: DateTime.now(),
      registrationEndDate: _registrationDeadline!,
      startDate: startDateTime,
      maxTeams: int.parse(_maxTeamsController.text),
      minTeams: 2,
      currentTeamsCount: 0,
      location: _selectedVenue?.location ??
          (_locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim()),
      venueId: _selectedVenue?.id,
      venueName: _selectedVenue?.title,
      rules: rules,
      prizes: {
        'entry_fee': entryFee,
        'winning_prize': winningPrize,
      },
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      entryFee: entryFee,
      winningPrize: winningPrize,
    );

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentPreviewScreen(
          tournament: previewTournament,
          onConfirm: _submitForm,
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_nameController.text.trim().isEmpty) {
      context.showSnackBar('Please enter tournament name to save as draft');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save draft logic here
      // For now, just show a message
      context.showSnackBar('Draft saved successfully!');
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to save draft: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSportType == null) {
      context.showSnackBar('Please select a sport type');
      return;
    }

    if (_startDate == null || _startTime == null) {
      context.showSnackBar('Please select start date and time');
      return;
    }

    if (_registrationDeadline == null) {
      context.showSnackBar('Please select registration deadline');
      return;
    }

    if (_registrationDeadline!.isAfter(_startDate!)) {
      context.showSnackBar('Registration deadline must be before start date');
      return;
    }

    if (_selectedVenue == null) {
      context.showSnackBar('Please select a venue for the tournament');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final entryFee = double.tryParse(_entryFeeController.text.trim()) ?? 0.0;
      final winningPrize =
          double.tryParse(_winningPrizeController.text.trim()) ?? 0.0;

      final rules = _rulesController.text
          .trim()
          .split('\n')
          .where((rule) => rule.trim().isNotEmpty)
          .toList();

      // Convert listing SportType to team SportType
      final teamSportType = _convertToTeamSportType(_selectedSportType!);

      await _tournamentService
          .createTournament(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            sportType: teamSportType,
            format: _selectedFormat,
            registrationStartDate: DateTime.now(),
            registrationEndDate: _registrationDeadline!,
            startDate: startDateTime,
            maxTeams: int.parse(_maxTeamsController.text),
            location: _selectedVenue?.location ??
                (_locationController.text.trim().isEmpty
                    ? null
                    : _locationController.text.trim()),
            venueId: _selectedVenue?.id,
            venueName: _selectedVenue?.title,
            rules: rules,
            prizes: {
              'entry_fee': entryFee,
              'winning_prize': winningPrize,
            },
            entryFee: entryFee,
            winningPrize: winningPrize,
          )
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        context.showSnackBar('Tournament created successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to create tournament: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Convert listing SportType to team SportType
  team.SportType _convertToTeamSportType(listing.SportType listingSportType) {
    switch (listingSportType) {
      case listing.SportType.cricket:
        return team.SportType.cricket;
      case listing.SportType.football:
        return team.SportType.football;
      case listing.SportType.basketball:
        return team.SportType.basketball;
      case listing.SportType.tennis:
        return team.SportType.tennis;
      case listing.SportType.badminton:
        return team.SportType.badminton;
      case listing.SportType.volleyball:
        return team.SportType.volleyball;
      case listing.SportType.swimming:
        return team.SportType.other;
      case listing.SportType.running:
        return team.SportType.other;
      case listing.SportType.cycling:
        return team.SportType.other;
      case listing.SportType.other:
        return team.SportType.other;
    }
  }
}
