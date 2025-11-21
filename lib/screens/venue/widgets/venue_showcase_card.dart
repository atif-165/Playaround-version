import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/venue.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class VenueShowcaseCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;

  const VenueShowcaseCard({
    super.key,
    required this.venue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final amenities = venue.amenities
        .map((amenity) => amenity.name.trim())
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.18),
                const Color(0xFF0D0A2A),
              ],
            ),
            border: Border.all(
              color: accent.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(accent),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Gap(12.h),
                    _buildLocationAndPrice(),
                    if (venue.sports.isNotEmpty) ...[
                      Gap(14.h),
                      _buildSportsRow(accent),
                    ],
                    if (amenities.isNotEmpty) ...[
                      Gap(14.h),
                      _buildAmenitiesRow(amenities),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(Color accent) {
    final imageUrl =
        venue.images.isNotEmpty ? venue.images.first : null;

    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.25),
            const Color(0xFF05030F),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF15112C),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF15112C),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 42.sp,
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16.h,
            left: 16.w,
            child: _Badge(
              icon: Icons.verified_rounded,
              label: venue.isVerified ? 'Verified Venue' : 'Featured Venue',
              accent: accent,
            ),
          ),
          Positioned(
            bottom: 16.h,
            left: 16.w,
            child: _RatingPill(
              rating: venue.rating,
              totalReviews: venue.totalReviews,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          venue.name.isNotEmpty ? venue.name : 'Untitled Venue',
          style: TextStyles.font20DarkBlue600Weight
              .copyWith(color: Colors.white, letterSpacing: 0.2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (venue.description.isNotEmpty) ...[
          Gap(6.h),
          Text(
            venue.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.font13White400Weight.copyWith(
              color: Colors.white.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationAndPrice() {
    final location = venue.address.isNotEmpty
        ? venue.address
        : [venue.city, venue.country]
            .where((value) => value.isNotEmpty)
            .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 18.sp,
                color: Colors.white.withOpacity(0.7),
              ),
              Gap(6.w),
              Expanded(
                child: Text(
                  location.isNotEmpty ? location : 'Location coming soon',
                  style: TextStyles.font13White400Weight.copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Gap(12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
            ),
          ),
          child: Text(
            _formattedPrice,
            style: TextStyles.font12White600Weight.copyWith(
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportsRow(Color accent) {
    final sports = venue.sports.take(3).toList();
    final extra = venue.sports.length - sports.length;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final sport in sports)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.38),
                  accent.withOpacity(0.14),
                ],
              ),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                Gap(6.w),
                Text(
                  sport,
                  style: TextStyles.font12White600Weight,
                ),
              ],
            ),
          ),
        if (extra > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Text(
              '+$extra more',
              style: TextStyles.font12White600Weight,
            ),
          ),
      ],
    );
  }

  Widget _buildAmenitiesRow(List<String> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Amenities',
          style: TextStyles.font14White600Weight.copyWith(
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.2,
          ),
        ),
        Gap(8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final amenity in amenities)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Text(
                  amenity,
                  style: TextStyles.font12White600Weight,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color get _accentColor {
    if (venue.sports.isEmpty) {
      return ColorsManager.primary;
    }
    final palette = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D1FF),
      const Color(0xFFFF6CAB),
      const Color(0xFFFFAA4C),
      const Color(0xFF4ADE80),
    ];
    final seed = venue.sports.first.codeUnitAt(0);
    return palette[seed % palette.length];
  }

  String get _formattedPrice {
    final amount = venue.pricing.hourlyRate;
    if (amount <= 0) {
      return 'Rates on request';
    }

    String currency = venue.pricing.currency.toUpperCase();
    if (currency.isEmpty ||
        currency == 'USD' && venue.address.toLowerCase().contains('pakistan')) {
      currency = 'PKR';
    }

    final symbol = _currencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(0)}/hr';
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'PKR':
        return '₨';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'AED':
        return 'د.إ ';
      default:
        return '$currency ';
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _Badge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            accent,
            accent.withOpacity(0.6),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14.sp,
          ),
          Gap(6.w),
          Text(
            label.toUpperCase(),
            style: TextStyles.font12White600Weight.copyWith(
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int? totalReviews;

  const _RatingPill({
    required this.rating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final reviewsCopy = totalReviews != null && totalReviews! > 0
        ? '$totalReviews reviews'
        : 'Be the first to review';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.black.withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFD76F),
            size: 16.sp,
          ),
          Gap(6.w),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'New',
            style: TextStyles.font12White600Weight,
          ),
          Gap(8.w),
          Text(
            '•',
            style: TextStyles.font12White600Weight,
          ),
          Gap(8.w),
          Text(
            reviewsCopy,
            style: TextStyles.font12White500Weight.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

