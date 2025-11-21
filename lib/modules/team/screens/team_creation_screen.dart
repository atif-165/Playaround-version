import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../helpers/app_regex.dart';
import '../../../services/cloudinary_service.dart';
import '../../../modules/coach/services/coach_service.dart';

import '../../../screens/profile/services/profile_data_service.dart';
import '../../../modules/chat/models/connection.dart';
import '../../../models/models.dart' hide SportType;

import '../models/models.dart';
import '../services/team_service.dart';

/// Screen for creating a new team
class TeamCreationScreen extends StatefulWidget {
  const TeamCreationScreen({super.key});

  @override
  State<TeamCreationScreen> createState() => _TeamCreationScreenState();
}

class _TeamCreationScreenState extends State<TeamCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  final TeamService _teamService = TeamService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final CoachService _coachService = CoachService();

  final ProfileDataService _profileDataService = ProfileDataService();
  final ImagePicker _imagePicker = ImagePicker();

  SportType _selectedSportType = SportType.cricket;
  int _maxMembers = 11;
  bool _isPublic = true;
  bool _isLoading = false;

  // New fields
  File? _profileImage;
  File? _backgroundImage;
  String? _profileImageUrl;
  String? _backgroundImageUrl;
  String? _selectedCoachId;
  String? _selectedCoachName;
  List<String> _selectedMemberIds = [];
  List<Connection> _availableConnections = [];
  List<CoachProfile> _availableCoaches = [];

  bool _isUploadingProfile = false;
  bool _isUploadingBackground = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load user connections for initial members
      final connections = await _profileDataService.getUserConnections();

      // Load available coaches
      final coaches = await _coachService.searchCoachesByName('', limit: 50);

      if (mounted) {
        setState(() {
          _availableConnections = connections;
          _availableCoaches = coaches;
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images if selected
      String? profileImageUrl = _profileImageUrl;
      String? backgroundImageUrl = _backgroundImageUrl;

      if (_profileImage != null && profileImageUrl == null) {
        profileImageUrl = await _cloudinaryService.uploadImage(
          _profileImage!,
          folder: 'teams/profiles',
        );
      }

      if (_backgroundImage != null && backgroundImageUrl == null) {
        backgroundImageUrl = await _cloudinaryService.uploadImage(
          _backgroundImage!,
          folder: 'teams/backgrounds',
        );
      }

      final teamId = await _teamService.createTeam(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        sportType: _selectedSportType,
        maxMembers: _maxMembers,
        isPublic: _isPublic,
        teamImageUrl: profileImageUrl,
        backgroundImageUrl: backgroundImageUrl,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        coachId: _selectedCoachId,
        coachName: _selectedCoachName,
        initialMemberIds: _selectedMemberIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, teamId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create team: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Team',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamNameField(),
              Gap(20.h),
              _buildDescriptionField(),
              Gap(20.h),
              _buildBioField(),
              Gap(20.h),
              _buildImageUploadSection(),
              Gap(20.h),
              _buildLocationField(),
              Gap(20.h),
              _buildSportTypeSelector(),
              Gap(20.h),
              _buildMaxMembersSelector(),
              Gap(20.h),
              _buildCoachSelector(),
              Gap(20.h),
              _buildInitialMembersSelector(),
              Gap(20.h),
              _buildVisibilityToggle(),
              Gap(40.h),
              _buildCreateButton(),
            ],
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
          'Team Name',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter team name',
            hintStyle: TextStyles.font13Grey400Weight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.gray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          validator: (value) => AppRegex.validateTeamName(value),
          maxLength: 50,
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
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Tell others about your team',
            hintStyle: TextStyles.font13Grey400Weight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.gray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          maxLines: 3,
          maxLength: 200,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a team description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio (Optional)',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            hintText: 'Detailed team bio and achievements',
            hintStyle: TextStyles.font13Grey400Weight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.gray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Images',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildImageUploadCard(
                title: 'Profile Picture',
                subtitle: 'Team avatar',
                image: _profileImage,
                imageUrl: _profileImageUrl,
                isUploading: _isUploadingProfile,
                onTap: () => _pickImage(isProfile: true),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildImageUploadCard(
                title: 'Background',
                subtitle: 'Team banner',
                image: _backgroundImage,
                imageUrl: _backgroundImageUrl,
                isUploading: _isUploadingBackground,
                onTap: () => _pickImage(isProfile: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location (Optional)',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Team base location or venue',
            hintStyle: TextStyles.font13Grey400Weight,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.gray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildSportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sport Type',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            border: Border.all(color: ColorsManager.gray),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SportType>(
              value: _selectedSportType,
              onChanged: (SportType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSportType = newValue;
                    // Set default max members based on sport
                    switch (newValue) {
                      case SportType.cricket:
                        _maxMembers = 11;
                        break;
                      case SportType.football:
                        _maxMembers = 11;
                        break;
                      case SportType.basketball:
                        _maxMembers = 5;
                        break;
                      case SportType.volleyball:
                        _maxMembers = 6;
                        break;
                      default:
                        _maxMembers = 11;
                    }
                  });
                }
              },
              items: SportType.values
                  .map<DropdownMenuItem<SportType>>((SportType value) {
                return DropdownMenuItem<SportType>(
                  value: value,
                  child: Text(
                    value.displayName,
                    style: TextStyles.font14Blue400Weight,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaxMembersSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Members',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            border: Border.all(color: ColorsManager.gray),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _maxMembers,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _maxMembers = newValue;
                  });
                }
              },
              items: List.generate(20, (index) => index + 5)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value members',
                    style: TextStyles.font14Blue400Weight,
                  ),
                );
              }).toList(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Visibility',
                style: TextStyles.font15DarkBlue500Weight,
              ),
              Gap(4.h),
              Text(
                _isPublic
                    ? 'Public - Anyone can find and request to join'
                    : 'Private - Only you can invite members',
                style: TextStyles.font13Grey400Weight,
              ),
            ],
          ),
        ),
        Switch(
          value: _isPublic,
          onChanged: (bool value) {
            setState(() {
              _isPublic = value;
            });
          },
          activeColor: ColorsManager.mainBlue,
        ),
      ],
    );
  }

  Widget _buildCoachSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Coach (Optional)',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        GestureDetector(
          onTap: _showCoachSelectionDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: ColorsManager.gray),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: ColorsManager.gray),
                Gap(12.w),
                Expanded(
                  child: Text(
                    _selectedCoachName ?? 'Select a coach',
                    style: _selectedCoachName != null
                        ? TextStyles.font14Blue400Weight
                        : TextStyles.font13Grey400Weight,
                  ),
                ),
                if (_selectedCoachName != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCoachId = null;
                        _selectedCoachName = null;
                      });
                    },
                    child: Icon(Icons.clear,
                        color: ColorsManager.gray, size: 20.sp),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialMembersSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Initial Members (Optional)',
          style: TextStyles.font15DarkBlue500Weight,
        ),
        Gap(8.h),
        GestureDetector(
          onTap: _showMemberSelectionDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: ColorsManager.gray),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.group_outlined, color: ColorsManager.gray),
                Gap(12.w),
                Expanded(
                  child: Text(
                    _selectedMemberIds.isEmpty
                        ? 'Select from your connections'
                        : '${_selectedMemberIds.length} members selected',
                    style: _selectedMemberIds.isNotEmpty
                        ? TextStyles.font14Blue400Weight
                        : TextStyles.font13Grey400Weight,
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: ColorsManager.gray, size: 16.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Create Team',
                style: TextStyles.font16White600Weight,
              ),
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    File? image,
    String? imageUrl,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          border: Border.all(color: ColorsManager.gray),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: isUploading
            ? const Center(child: CircularProgressIndicator())
            : image != null || imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: image != null
                        ? Image.file(image, fit: BoxFit.cover)
                        : Image.network(imageUrl!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: ColorsManager.gray, size: 32.sp),
                      Gap(8.h),
                      Text(title, style: TextStyles.font12DarkBlue400Weight),
                      Text(subtitle, style: TextStyles.font10Grey400Weight),
                    ],
                  ),
      ),
    );
  }

  Future<void> _pickImage({required bool isProfile}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isProfile ? 512 : 1024,
        maxHeight: isProfile ? 512 : 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(image.path);
            _isUploadingProfile = true;
          } else {
            _backgroundImage = File(image.path);
            _isUploadingBackground = true;
          }
        });

        // Upload immediately for preview
        try {
          final imageUrl = await _cloudinaryService.uploadImage(
            File(image.path),
            folder: isProfile ? 'teams/profiles' : 'teams/backgrounds',
          );

          setState(() {
            if (isProfile) {
              _profileImageUrl = imageUrl;
              _isUploadingProfile = false;
            } else {
              _backgroundImageUrl = imageUrl;
              _isUploadingBackground = false;
            }
          });
        } catch (e) {
          setState(() {
            if (isProfile) {
              _isUploadingProfile = false;
            } else {
              _isUploadingBackground = false;
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCoachSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Coach'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300.h,
          child: _availableCoaches.isEmpty
              ? const Center(child: Text('No coaches available'))
              : ListView.builder(
                  itemCount: _availableCoaches.length,
                  itemBuilder: (context, index) {
                    final coach = _availableCoaches[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: coach.profilePictureUrl != null
                            ? NetworkImage(coach.profilePictureUrl!)
                            : null,
                        child: coach.profilePictureUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(coach.fullName),
                      subtitle: Text(coach.specializationSports.join(', ')),
                      onTap: () {
                        setState(() {
                          _selectedCoachId = coach.uid;
                          _selectedCoachName = coach.fullName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Initial Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300.h,
          child: _availableConnections.isEmpty
              ? const Center(child: Text('No connections available'))
              : ListView.builder(
                  itemCount: _availableConnections.length,
                  itemBuilder: (context, index) {
                    final connection = _availableConnections[index];
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    final otherUserId =
                        connection.getOtherUserId(currentUserId);
                    final otherUserName =
                        connection.getOtherUserName(currentUserId);
                    final otherUserImageUrl =
                        connection.getOtherUserImageUrl(currentUserId);
                    final isSelected = _selectedMemberIds.contains(otherUserId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedMemberIds.add(otherUserId);
                          } else {
                            _selectedMemberIds.remove(otherUserId);
                          }
                        });
                      },
                      title: Text(otherUserName),
                      subtitle: const Text('Player'),
                      secondary: CircleAvatar(
                        backgroundImage: otherUserImageUrl != null
                            ? NetworkImage(otherUserImageUrl)
                            : null,
                        child: otherUserImageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
