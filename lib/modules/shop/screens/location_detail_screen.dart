import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/typography.dart';
import '../widgets/shop_theme.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../models/shop_location.dart';
import '../models/location_review.dart';
import '../services/shop_location_service.dart';
import '../services/location_review_service.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/chat_room.dart';
import 'edit_location_screen.dart';
import 'add_review_screen.dart';
import '../../chat/screens/chat_screen.dart';

/// Location detail screen showing information about a shop location
class LocationDetailScreen extends StatefulWidget {
  final ShopLocation? location;
  final String? locationId;

  const LocationDetailScreen({
    super.key,
    this.location,
    this.locationId,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final ShopLocationService _locationService = ShopLocationService();
  final LocationReviewService _reviewService = LocationReviewService();
  final ChatService _chatService = ChatService();
  final PageController _pageController = PageController();

  ShopLocation? _location;
  bool _isOwner = false;
  List<LocationReview> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = false;
  bool _isRefreshing = false;
  bool _isLoadingLocation = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final initial = widget.location;
    if (initial != null) {
      setState(() {
        _location = initial;
        _isLoadingLocation = false;
      });
      _checkOwnership();
      _loadReviews();
      return;
    }

    final locationId = widget.locationId;
    if (locationId == null) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final fetched = await _locationService.getLocationById(locationId);
      if (!mounted) return;
      if (fetched == null) {
        setState(() {
          _isLoadingLocation = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
        return;
      }

      setState(() {
        _location = fetched;
        _isLoadingLocation = false;
      });
      _checkOwnership();
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load location: $e')),
      );
    }
  }

  void _checkOwnership() {
    final location = _location;
    if (location == null) return;
    _isOwner = _locationService.isLocationOwner(location);
  }

  Future<void> _loadReviews() async {
    final location = _location;
    if (location == null) return;

    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviews = await _reviewService.getLocationReviews(location.id);
      final averageRating =
          await _reviewService.getAverageRating(location.id);
      final reviewCount =
          await _reviewService.getReviewCount(location.id);

      setState(() {
        _reviews = reviews;
        _averageRating = averageRating;
        _reviewCount = reviewCount;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReviews = false;
      });
      print('Error loading reviews: $e');
    }
  }

  Future<void> _reloadLocation() async {
    final locationId = _location?.id ?? widget.locationId;
    if (locationId == null) return;

    setState(() {
      _isRefreshing = true;
    });
    try {
      final latest = await _locationService.getLocationById(locationId);
      if (latest != null) {
        setState(() {
          _location = latest;
          _currentImageIndex = 0;
        });
        _checkOwnership();
        await _loadReviews();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _startChatWithOwner() async {
    final location = _location;
    if (location == null) return;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get existing chat room with the location owner
      final chatRoom =
          await _chatService.getOrCreateDirectChat(location.ownerId);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (chatRoom != null) {
        // Navigate to chat screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: chatRoom),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unable to start chat. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    if (_isLoadingLocation || location == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_isRefreshing)
              const LinearProgressIndicator(
                minHeight: 2,
                color: ColorsManager.primary,
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroImage(),
                    _buildLocationInfoCard(),
                    Gap(18.h),
                    _buildBusinessHours(),
                    Gap(18.h),
                    _buildContactInfo(),
                    Gap(18.h),
                    _buildReviewsSection(),
                    if (_isOwner) ...[
                      Gap(18.h),
                      _buildOwnerActions(),
                    ],
                    Gap(32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final location = _location!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 10.h,
        20.w,
        12.h,
      ),
      decoration: const BoxDecoration(
        gradient: ShopTheme.heroGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.w,
            ),
          ),
          Expanded(
            child: Text(
              location.title,
              style: AppTypography.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isOwner)
            IconButton(
              onPressed: _editLocation,
              icon: Icon(
                Icons.edit,
                color: Colors.white,
                size: 24.w,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final images = _location!.images;
    if (images.isEmpty) {
      return Container(
        height: 240.h,
        color: ColorsManager.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.store,
            size: 64.w,
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 260.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: ColorsManager.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: ColorsManager.surfaceVariant,
                  child: Icon(
                    Icons.store,
                    size: 64.w,
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return _buildLocationInfoCard();
  }

  Widget _buildLocationInfoCard() {
    final location = _location!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.title,
                      style: AppTypography.headlineMedium
                          .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Gap(8.h),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: ColorsManager.primary, size: 16.w),
                        Gap(4.w),
                        Expanded(
                          child: Text(
                                location.address,
                            style: AppTypography.bodyMedium
                                .copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (location.isVerified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 16.w),
                      Gap(4.w),
                      Text(
                        'Verified',
                        style: AppTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Gap(16.h),
          Text(
            location.description,
            style: AppTypography.bodyLarge.copyWith(color: Colors.white),
          ),
          Gap(16.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  location.category,
                  style: AppTypography.labelMedium.copyWith(color: Colors.white),
                ),
              ),
              Gap(12.w),
              Row(
                children: [
                  Icon(Icons.star, color: ColorsManager.warning, size: 16.w),
                  Gap(4.w),
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(4.w),
                  Text(
                    '($_reviewCount reviews)',
                    style:
                        AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final location = _location!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          if (location.phoneNumber.isNotEmpty)
            _buildContactItem(
              icon: Icons.phone,
              label: 'Phone',
              value: location.phoneNumber,
              onTap: () => _callPhone(location.phoneNumber),
            ),
          if (location.email.isNotEmpty)
            _buildContactItem(
              icon: Icons.email,
              label: 'Email',
              value: location.email,
              onTap: () => _launchUrl('mailto:${location.email}'),
            ),
          if (location.website.isNotEmpty)
            _buildContactItem(
              icon: Icons.web,
              label: 'Website',
              value: location.website,
              onTap: () => _launchUrl(location.website),
            ),
          Gap(16.h),
          // Chat with owner button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _startChatWithOwner();
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Owner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: ColorsManager.primary,
              size: 20.w,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorsManager.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: ColorsManager.onSurfaceVariant,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHours() {
    final location = _location!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: _buildGlassCard(
        title: 'Business Hours',
        child: location.businessHours.isNotEmpty
            ? Column(
                children: location.businessHours.entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80.w,
                          child: Text(
                            entry.key,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: AppTypography.bodyMedium
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              )
            : _buildEmptyStateMessage('Business hours not specified'),
      ),
    );
  }

  Widget _buildReviewsSection() {
    final location = _location!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: _buildGlassCard(
        title: 'Reviews',
        trailing: IconButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                        builder: (context) => AddReviewScreen(
                          locationId: location.id,
                          locationName: location.title,
                ),
              ),
            );
            if (result == true) _loadReviews();
          },
          icon: const Icon(Icons.add, color: Colors.white),
        ),
        child: _isLoadingReviews
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
                ? _buildEmptyStateMessage('Be the first to review this spot.')
                : Column(
                    children: _reviews
                        .map((review) => _buildReviewItem(review))
                        .toList(),
                  ),
      ),
    );
  }

  Widget _buildReviewItem(LocationReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: review.userProfileImage.isNotEmpty
                    ? CachedNetworkImageProvider(review.userProfileImage)
                    : null,
                child: review.userProfileImage.isEmpty
                    ? Icon(
                        Icons.person,
                        color: ColorsManager.onSurfaceVariant,
                        size: 20.w,
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: ColorsManager.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: ColorsManager.warning,
                            size: 16.w,
                          );
                        }),
                        Gap(8.w),
                        Text(
                          review.createdAt.toString().split(' ')[0],
                          style: AppTypography.bodySmall.copyWith(
                            color: ColorsManager.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            review.comment,
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final location = _location!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(16.h),
          Row(
            children: [
              Icon(
                Icons.star,
                color: ColorsManager.warning,
                size: 20.w,
              ),
              Gap(8.w),
              Text(
                'Rating: ${location.rating.toStringAsFixed(1)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: ColorsManager.onSurface,
                ),
              ),
              Gap(16.w),
              Text(
                '(${location.reviewCount} reviews)',
                style: AppTypography.bodySmall.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (location.tags.isNotEmpty) ...[
            Gap(16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: location.tags
                  .map(
                    (tag) => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryContainer,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.labelSmall.copyWith(
                          color: ColorsManager.onPrimaryContainer,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: _buildGlassCard(
        title: 'Owner Actions',
        child: Row(
          children: [
            Expanded(
              child: AppFilledButton(
                text: 'Edit Location',
                onPressed: _editLocation,
                icon: const Icon(Icons.edit),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: AppOutlinedButton(
                text: 'Delete',
                onPressed: _deleteLocation,
                icon: const Icon(Icons.delete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLocation() async {
    final location = _location;
    if (location == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(location: location),
      ),
    );

    if (updated == true) {
      await _reloadLocation();
    }
  }

  Future<void> _deleteLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.surface,
        title: Text(
          'Delete Location',
          style: AppTypography.headlineSmall.copyWith(
            color: ColorsManager.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this location? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final location = _location;
      if (location == null) return;
      try {
        await _locationService.deleteLocation(location.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete location: $e')),
          );
        }
      }
    }
  }
  Widget _buildGlassCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          Gap(16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white54, size: 20.w),
          Gap(10.w),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
