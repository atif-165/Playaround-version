import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../widgets/payment_integration.dart';
import '../widgets/team_selector.dart';

/// Screen for joining tournaments as team or individual
class TournamentJoinScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentJoinScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentJoinScreen> createState() => _TournamentJoinScreenState();
}

class _TournamentJoinScreenState extends State<TournamentJoinScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  UserProfile? _currentUserProfile;
  String? _selectedTeamId;
  List<Map<String, String>> _qualifyingAnswers = [];
  bool _agreeToTerms = false;
  bool _agreeToRules = false;
  bool _isProcessingPayment = false;
  String? _paymentMethodId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _initializeQualifyingAnswers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
    }
  }

  void _initializeQualifyingAnswers() {
    _qualifyingAnswers = List.generate(
      widget.tournament.qualifyingQuestions.length,
      (index) => {'question': '', 'answer': ''},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Join Tournament',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CustomProgressIndicator())
          : Column(
              children: [
                _buildTournamentHeader(),
                _buildJoinTypeTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTeamJoinTab(),
                      _buildIndividualJoinTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTournamentHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: ColorsManager.cardBackground,
        border: Border(
          bottom: BorderSide(color: ColorsManager.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.tournament.name,
            style: TextStyles.font20DarkBlueBold,
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.sports_cricket,
                size: 16.sp,
                color: ColorsManager.primary,
              ),
              Gap(8.w),
              Text(
                widget.tournament.sportType.displayName,
                style: TextStyles.font14DarkBlueMedium,
              ),
              Gap(16.w),
              Icon(
                Icons.people,
                size: 16.sp,
                color: ColorsManager.textSecondary,
              ),
              Gap(4.w),
              Text(
                '${widget.tournament.currentTeamsCount}/${widget.tournament.maxTeams} teams',
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16.sp,
                color: ColorsManager.textSecondary,
              ),
              Gap(4.w),
              Text(
                DateFormat('MMM dd, yyyy at HH:mm')
                    .format(widget.tournament.startDate),
                style: TextStyles.font14Grey400Weight.copyWith(
                  color: ColorsManager.textSecondary,
                ),
              ),
              if (widget.tournament.entryFee != null) ...[
                Gap(16.w),
                Icon(
                  Icons.attach_money,
                  size: 16.sp,
                  color: ColorsManager.success,
                ),
                Gap(4.w),
                Text(
                  '\$${widget.tournament.entryFee!.toStringAsFixed(0)} entry fee',
                  style: TextStyles.font14Grey400Weight.copyWith(
                    color: ColorsManager.success,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTypeTabs() {
    return Container(
      color: ColorsManager.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.primary,
        unselectedLabelColor: ColorsManager.textSecondary,
        indicatorColor: ColorsManager.primary,
        tabs: const [
          Tab(text: 'Join as Team'),
          Tab(text: 'Join as Individual'),
        ],
      ),
    );
  }

  Widget _buildTeamJoinTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamSelector(),
          Gap(24.h),
          _buildQualifyingQuestions(),
          Gap(24.h),
          _buildAdditionalInfo(),
          Gap(24.h),
          _buildPaymentSection(),
          Gap(24.h),
          _buildTermsAndConditions(),
          Gap(32.h),
          _buildJoinButton(),
        ],
      ),
    );
  }

  Widget _buildIndividualJoinTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndividualInfo(),
          Gap(24.h),
          _buildQualifyingQuestions(),
          Gap(24.h),
          _buildAdditionalInfo(),
          Gap(24.h),
          _buildPaymentSection(),
          Gap(24.h),
          _buildTermsAndConditions(),
          Gap(32.h),
          _buildJoinButton(),
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Team',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        TeamSelector(
          selectedTeamId: _selectedTeamId,
          sportType: widget.tournament.sportType,
          onTeamSelected: (teamId) {
            setState(() {
              _selectedTeamId = teamId;
            });
          },
        ),
      ],
    );
  }

  Widget _buildIndividualInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Registration',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundImage: _currentUserProfile?.photoURL != null
                    ? NetworkImage(_currentUserProfile!.photoURL!)
                    : null,
                child: _currentUserProfile?.photoURL == null
                    ? Icon(
                        Icons.person,
                        color: ColorsManager.textSecondary,
                        size: 24.sp,
                      )
                    : null,
              ),
              Gap(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUserProfile?.displayName ?? 'Unknown User',
                      style: TextStyles.font16DarkBlueBold,
                    ),
                    Gap(4.h),
                    Text(
                      _currentUserProfile?.uid ?? '',
                      style: TextStyles.font14Grey400Weight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualifyingQuestions() {
    if (widget.tournament.qualifyingQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qualifying Questions',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        ...widget.tournament.qualifyingQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: TextStyles.font14DarkBlueMedium,
                ),
                Gap(8.h),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Your answer...',
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      _qualifyingAnswers[index]['answer'] = value;
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Any additional notes or information...',
          ),
          maxLines: 4,
          onChanged: (value) {
            // Additional notes handling
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    if (widget.tournament.entryFee == null || widget.tournament.entryFee == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        PaymentIntegration(
          amount: widget.tournament.entryFee!,
          onPaymentMethodSelected: (methodId) {
            setState(() {
              _paymentMethodId = methodId;
            });
          },
          onPaymentProcessing: (isProcessing) {
            setState(() {
              _isProcessingPayment = isProcessing;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        CheckboxListTile(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          title: Text(
            'I agree to the tournament terms and conditions',
            style: TextStyles.font14DarkBlueMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _agreeToRules,
          onChanged: (value) {
            setState(() {
              _agreeToRules = value ?? false;
            });
          },
          title: Text(
            'I agree to follow tournament rules and regulations',
            style: TextStyles.font14DarkBlueMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    final canJoin = _agreeToTerms && _agreeToRules;

    return AppTextButton(
      buttonText: _isProcessingPayment ? 'Processing...' : 'Join Tournament',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed:
          canJoin && !_isProcessingPayment ? _handleJoinTournament : null,
    );
  }

  Future<void> _handleJoinTournament() async {
    if (!_agreeToTerms || !_agreeToRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Process payment if required
      if (widget.tournament.entryFee != null &&
          widget.tournament.entryFee! > 0) {
        if (_paymentMethodId == null) {
          throw Exception('Please select a payment method');
        }
        // Payment processing would happen here
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined tournament!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join tournament: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
}
