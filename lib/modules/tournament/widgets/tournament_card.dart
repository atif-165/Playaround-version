import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Tournament card styled to mirror the coaches/venues listing aesthetic.
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  static const List<Color> _cardColorOptions = [
    Color(0xFF26214A), // muted royal purple
    Color(0xFF153746), // deep cyan teal
    Color(0xFF342245), // soft violet
    Color(0xFF1F2F46), // navy slate
    Color(0xFF30243E), // plum dusk
  ];

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor;
    final baseColor = _cardColor;
    final borderColor = _cardBorderColor;

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: borderColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(),
                Gap(16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _pill(
                        icon: _sportIcon,
                        label: tournament.sportType.displayName,
                      ),
                    ),
                    Gap(12.w),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _statusChip(accent),
                      ),
                    ),
                  ],
                ),
                Gap(14.h),
                Text(
                  tournament.name,
                  style: TextStyles.font24WhiteBold.copyWith(
                    fontSize: 22.sp,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(6.h),
                Text(
                  tournament.description,
                  style: TextStyles.font12WhiteMedium.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(12.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 8.h,
                  children: [
                    _infoChip(
                      icon: Icons.calendar_today_rounded,
                      text: DateFormat('EEE, MMM d • h:mm a')
                          .format(tournament.startDate),
                    ),
                    _infoChip(
                      icon: Icons.groups_rounded,
                      text:
                          '${tournament.currentTeamsCount}/${tournament.maxTeams} teams',
                    ),
                    if (tournament.location != null &&
                        tournament.location!.isNotEmpty)
                      _infoChip(
                        icon: Icons.location_on_rounded,
                        text: tournament.location!,
                        maxLines: 2,
                      ),
                    if (tournament.entryFee != null)
                      _infoChip(
                        icon: Icons.attach_money_rounded,
                        text: _formatMoney(
                          tournament.entryFee!,
                          tournament.metadata != null
                              ? tournament.metadata!['currency']?.toString()
                              : null,
                        ),
                      ),
                  ],
                ),
                Gap(18.h),
                _buildFooter(accent, baseColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final imageUrl = tournament.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _heroPlaceholder(),
                errorWidget: (_, __, ___) => _heroPlaceholder(),
              )
            else
              _heroPlaceholder(),
            Container(
              color: _cardColor.withOpacity(0.65),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: Color.lerp(_cardColor, Colors.black, 0.3)!,
      alignment: Alignment.center,
      child: Icon(
        _sportIcon,
        color: Colors.white.withOpacity(0.25),
        size: 34.sp,
      ),
    );
  }

  Widget _buildFooter(Color accent, Color baseColor) {
    final remainingSpots =
        (tournament.maxTeams - tournament.currentTeamsCount).clamp(0, 999);
    final deadline =
        DateFormat('MMM dd, yyyy').format(tournament.registrationEndDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.organizerName,
                style: TextStyles.font12WhiteMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14.sp,
                    color: Colors.white60,
                  ),
                  Gap(6.w),
                  Expanded(
                    child: Text(
                      'Register by $deadline',
                      style: TextStyles.font12WhiteMedium.copyWith(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canRegister) ...[
          Gap(12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Color.lerp(baseColor, Colors.white, 0.18)!,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Color.lerp(baseColor, Colors.white, 0.35)!,
              ),
            ),
            child: Text(
              '$remainingSpots spots left',
              style: TextStyles.font12WhiteMedium.copyWith(fontSize: 10.sp),
            ),
          ),
        ],
        Gap(12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: canRegister
                ? Color.lerp(baseColor, Colors.white, 0.22)!
                : Colors.white.withOpacity(0.14),
            border: Border.all(
              color: canRegister
                  ? Color.lerp(baseColor, Colors.white, 0.4)!
                  : Colors.white.withOpacity(0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
              Gap(6.w),
              Text(
                actionText,
                style: TextStyles.font12WhiteMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill({required IconData icon, required String label}) {
    final baseColor = _cardColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Color.lerp(baseColor, Colors.white, 0.12)!,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Color.lerp(baseColor, Colors.white, 0.25)!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12WhiteMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(Color accent) {
    if (hasWinner) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [
              ColorsManager.success,
              ColorsManager.success.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.white, size: 14.sp),
            Gap(6.w),
            Text(
              'Winner',
              style: TextStyles.font12WhiteMedium.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: accent.withOpacity(0.22),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Text(
        tournament.status.displayName.toUpperCase(),
        style: TextStyles.font12WhiteMedium.copyWith(
          fontSize: 10.sp,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    int maxLines = 1,
  }) {
    final baseColor = _cardColor;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 230.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Color.lerp(baseColor, Colors.black, 0.25)!,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Color.lerp(baseColor, Colors.white, 0.14)!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14.sp),
            Gap(6.w),
            Flexible(
              child: Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.font12WhiteMedium.copyWith(fontSize: 11.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _sportIcon {
    final sportName = tournament.sportType.displayName.toLowerCase();
    if (sportName.contains('cricket')) return Icons.sports_cricket_rounded;
    if (sportName.contains('football') || sportName.contains('soccer')) {
      return Icons.sports_soccer_rounded;
    }
    if (sportName.contains('basketball')) return Icons.sports_basketball_rounded;
    if (sportName.contains('tennis') || sportName.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    }
    if (sportName.contains('volleyball')) return Icons.sports_volleyball_rounded;
    if (sportName.contains('swimming')) return Icons.pool_rounded;
    if (sportName.contains('running')) return Icons.directions_run_rounded;
    if (sportName.contains('cycling')) return Icons.directions_bike_rounded;
    if (sportName.contains('hockey')) return Icons.sports_hockey_rounded;
    return Icons.emoji_events_rounded;
  }

  Color get _statusColor {
    switch (tournament.status) {
      case TournamentStatus.upcoming:
        return ColorsManager.mainBlue;
      case TournamentStatus.registrationOpen:
        return ColorsManager.success;
      case TournamentStatus.registrationClosed:
        return Colors.orangeAccent;
      case TournamentStatus.ongoing:
      case TournamentStatus.running:
      case TournamentStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case TournamentStatus.completed:
        return Colors.blueGrey;
      case TournamentStatus.cancelled:
        return Colors.redAccent;
    }
  }

  bool get canRegister =>
      tournament.status == TournamentStatus.registrationOpen &&
      tournament.currentTeamsCount < tournament.maxTeams &&
      tournament.registrationEndDate.isAfter(DateTime.now());

  bool get hasWinner =>
      tournament.status == TournamentStatus.completed &&
      tournament.winnerTeamId != null;

  String get actionText {
    if (tournament.status == TournamentStatus.completed) {
      return 'View Results';
    }
    if (tournament.status == TournamentStatus.ongoing ||
        tournament.status == TournamentStatus.inProgress ||
        tournament.status == TournamentStatus.running) {
      return 'Live Now';
    }
    if (canRegister) return 'Join Tournament';
    if (tournament.currentTeamsCount >= tournament.maxTeams) {
      return 'Spots Filled';
    }
    if (tournament.registrationEndDate.isBefore(DateTime.now())) {
      return 'Registration Closed';
    }
    return 'View Details';
  }

  String _formatMoney(double amount, String? currencyCode) {
    final effectiveCurrency = currencyCode?.toUpperCase();
    final symbol = switch (effectiveCurrency) {
      'PKR' => '₨',
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'INR' => '₹',
      _ => effectiveCurrency ?? '\$',
    };

    final formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: symbol,
      name: effectiveCurrency,
    );
    return formatter.format(amount);
  }

  int get _paletteIndex =>
      tournament.id.hashCode.abs() % _cardColorOptions.length;

  Color get _cardColor => _cardColorOptions[_paletteIndex];

  Color get _cardBorderColor =>
      Color.lerp(_cardColor, Colors.white, 0.18)!;
}
