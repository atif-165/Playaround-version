import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../cubit/tournament_cubit.dart';
import '../models/tournament_model.dart';
import '../services/tournament_permissions_service.dart';
import '../../team/models/team_model.dart';

class AddTournamentScreen extends StatefulWidget {
  const AddTournamentScreen({super.key});

  @override
  State<AddTournamentScreen> createState() => _AddTournamentScreenState();
}

class _AddTournamentScreenState extends State<AddTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final TournamentPermissionsService _permissionsService =
      TournamentPermissionsService();

  SportType _selectedSport = SportType.football;
  TournamentType _selectedType = TournamentType.knockOut;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isPublic = true;
  int _maxTeams = 8;
  int? _minTeams;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canCreate = await _permissionsService.canCreateTournaments();

    if (!mounted) return;

    setState(() {
      _hasPermission = canCreate;
      _isCheckingPermission = false;
    });

    if (!canCreate) {
      _showPermissionDeniedAndGoBack();
    }
  }

  Future<void> _showPermissionDeniedAndGoBack() async {
    final reason = await _permissionsService.getCreationRestrictionReason();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.red),
            Gap(12.w),
            const Text('Access Denied'),
          ],
        ),
        content: Text(reason),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to tournaments list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Tournament'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ColorsManager.mainBlue),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Tournament'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ColorsManager.mainBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Create Tournament',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<TournamentCubit, TournamentState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {
              setState(() {
                _isLoading = true;
              });
            },
            loaded: (tournaments) {
              setState(() {
                _isLoading = false;
              });
            },
            userTournamentsLoaded: (tournaments) {
              setState(() {
                _isLoading = false;
              });
            },
            searchResults: (tournaments) {
              setState(() {
                _isLoading = false;
              });
            },
            tournamentDetails: (tournament) {
              setState(() {
                _isLoading = false;
              });
            },
            tournamentCreated: (tournamentId) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tournament created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            tournamentUpdated: () {
              setState(() {
                _isLoading = false;
              });
            },
            tournamentDeleted: () {
              setState(() {
                _isLoading = false;
              });
            },
            teamAdded: () {
              setState(() {
                _isLoading = false;
              });
            },
            teamRemoved: () {
              setState(() {
                _isLoading = false;
              });
            },
            statusUpdated: () {
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTournamentNameField(),
                Gap(20.h),
                _buildSportAndTypeSelection(),
                Gap(20.h),
                _buildDateFields(),
                Gap(20.h),
                _buildLocationField(),
                Gap(20.h),
                _buildDescriptionField(),
                Gap(20.h),
                _buildTeamLimitsFields(),
                Gap(20.h),
                _buildEntryFeeField(),
                Gap(20.h),
                _buildVisibilityToggle(),
                Gap(32.h),
                _buildCreateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Name *',
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
            hintText: 'Enter tournament name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.emoji_events,
              color: Colors.grey[400],
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tournament name is required';
            }
            if (value.trim().length < 3) {
              return 'Tournament name must be at least 3 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSportAndTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: Column(
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SportType>(
                    value: _selectedSport,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    items: SportType.values.map((sport) {
                      return DropdownMenuItem<SportType>(
                        value: sport,
                        child: Text(sport.displayName),
                      );
                    }).toList(),
                    onChanged: (SportType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSport = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type *',
                style: TextStyles.font16DarkBlue600Weight.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TournamentType>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    items: TournamentType.values.map((type) {
                      return DropdownMenuItem<TournamentType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (TournamentType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                          _minTeams = newValue.minTeamRequirement;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Dates *',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectStartDate(),
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _endDate,
                onTap: () => _selectEndDate(),
              ),
            ),
          ],
        ),
        Gap(12.h),
        _buildDateField(
          label: 'Registration Deadline (Optional)',
          date: _registrationDeadline,
          onTap: () => _selectRegistrationDeadline(),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        Gap(4.h),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[400],
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  date != null ? _formatDate(date) : 'Select date',
                  style: TextStyle(
                    color: date != null ? Colors.white : Colors.grey[400],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _locationController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter tournament location',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
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
            hintText: 'Describe your tournament...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLimitsFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Max Teams',
                style: TextStyles.font16DarkBlue600Weight.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              TextFormField(
                initialValue: _maxTeams.toString(),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Max teams',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  _maxTeams = int.tryParse(value) ?? 8;
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final number = int.tryParse(value);
                    if (number == null || number < 2 || number > 64) {
                      return 'Enter 2-64 teams';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min Teams',
                style: TextStyles.font16DarkBlue600Weight.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(8.h),
              TextFormField(
                initialValue:
                    (_minTeams ?? _selectedType.minTeamRequirement).toString(),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min teams',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  _minTeams = int.tryParse(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntryFeeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entry Fee (Optional)',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _entryFeeController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter entry fee (leave empty for free)',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.attach_money,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Public Tournament',
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
        onPressed: _isLoading ? null : _createTournament,
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
                'Create Tournament',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _selectRegistrationDeadline() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: _startDate!,
    );
    if (date != null) {
      setState(() {
        _registrationDeadline = date;
      });
    }
  }

  void _createTournament() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')),
        );
        return;
      }

      final entryFee = _entryFeeController.text.isNotEmpty
          ? double.tryParse(_entryFeeController.text)
          : null;

      final selectedFormat = _mapTypeToFormat(_selectedType);

      context.read<TournamentCubit>().createTournament(
            name: _nameController.text.trim(),
            format: selectedFormat,
            sportType: _selectedSport,
            registrationStartDate: _registrationDeadline ??
                _startDate!.subtract(const Duration(days: 7)),
            registrationEndDate: _startDate!.subtract(const Duration(days: 1)),
            startDate: _startDate!,
            endDate: _endDate!,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            isPublic: _isPublic,
            maxTeams: _maxTeams,
            minTeams: _minTeams,
            location: _locationController.text.trim().isNotEmpty
                ? _locationController.text.trim()
                : null,
            entryFee: entryFee,
          );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

TournamentFormat _mapTypeToFormat(TournamentType type) {
  switch (type) {
    case TournamentType.knockout:
    case TournamentType.knockOut:
      return TournamentFormat.singleElimination;
    case TournamentType.league:
      return TournamentFormat.league;
    case TournamentType.individual:
    case TournamentType.team:
    case TournamentType.mixed:
      return TournamentFormat.roundRobin;
  }
}
