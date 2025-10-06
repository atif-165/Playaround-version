import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Widget for sharing tournaments on social media
class TournamentSharing extends StatefulWidget {
  final Tournament tournament;
  final Function(String)? onShared;

  const TournamentSharing({
    super.key,
    required this.tournament,
    this.onShared,
  });

  @override
  State<TournamentSharing> createState() => _TournamentSharingState();
}

class _TournamentSharingState extends State<TournamentSharing> {
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildShareHeader(),
        Gap(16.h),
        _buildShareOptions(),
        Gap(16.h),
        _buildSharePreview(),
      ],
    );
  }

  Widget _buildShareHeader() {
    return Row(
      children: [
        Icon(
          Icons.share,
          color: ColorsManager.primary,
          size: 20.sp,
        ),
        Gap(8.w),
        Text(
          'Share Tournament',
          style: TextStyles.font16DarkBlueBold,
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _copyLink,
          icon: Icon(
            Icons.copy,
            size: 16.sp,
            color: ColorsManager.primary,
          ),
          label: Text(
            'Copy Link',
            style: TextStyles.font14MainBlue500Weight,
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildShareButton(
            icon: Icons.facebook,
            label: 'Facebook',
            color: const Color(0xFF1877F2),
            onTap: () => _shareToFacebook(),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildShareButton(
            icon: Icons.alternate_email,
            label: 'Twitter',
            color: const Color(0xFF1DA1F2),
            onTap: () => _shareToTwitter(),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildShareButton(
            icon: Icons.camera_alt,
            label: 'Instagram',
            color: const Color(0xFFE4405F),
            onTap: () => _shareToInstagram(),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _buildShareButton(
            icon: Icons.message,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _shareToWhatsApp(),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSharing ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
            Gap(4.h),
            Text(
              label,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePreview() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Preview',
            style: TextStyles.font14DarkBlueMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(12.h),
          Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.sports_cricket,
                  color: ColorsManager.primary,
                  size: 24.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tournament.name,
                      style: TextStyles.font14DarkBlueMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    Text(
                      '${widget.tournament.sportType.displayName} Tournament',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.textSecondary,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      'Join now! ${widget.tournament.currentTeamsCount}/${widget.tournament.maxTeams} teams registered',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: ColorsManager.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            _getShareText(),
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getShareText() {
    return 'Check out this ${widget.tournament.sportType.displayName} tournament: "${widget.tournament.name}". '
        '${widget.tournament.entryFee != null && widget.tournament.entryFee! > 0 ? 'Entry fee: \$${widget.tournament.entryFee!.toStringAsFixed(0)}. ' : ''}'
        'Join now and compete for the prize!';
  }

  String _getShareUrl() {
    // In a real app, this would be the actual tournament URL
    return 'https://yourapp.com/tournament/${widget.tournament.id}';
  }

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: _getShareUrl()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard!'),
            backgroundColor: ColorsManager.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy link: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    }
  }

  Future<void> _shareToFacebook() async {
    await _performShare('Facebook', () {
      // TODO: Implement Facebook sharing
      return 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_getShareUrl())}';
    });
  }

  Future<void> _shareToTwitter() async {
    await _performShare('Twitter', () {
      final text = Uri.encodeComponent(_getShareText());
      final url = Uri.encodeComponent(_getShareUrl());
      return 'https://twitter.com/intent/tweet?text=$text&url=$url';
    });
  }

  Future<void> _shareToInstagram() async {
    await _performShare('Instagram', () {
      // Instagram doesn't support direct URL sharing, so we'll copy the text
      return _getShareText();
    });
  }

  Future<void> _shareToWhatsApp() async {
    await _performShare('WhatsApp', () {
      final text = Uri.encodeComponent('${_getShareText()}\n\n${_getShareUrl()}');
      return 'https://wa.me/?text=$text';
    });
  }

  Future<void> _performShare(String platform, String Function() getShareUrl) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final shareUrl = getShareUrl();
      
      // In a real app, you would use a package like url_launcher to open the URL
      // For now, we'll just copy the text to clipboard
      await Clipboard.setData(ClipboardData(text: shareUrl));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platform share link copied to clipboard!'),
            backgroundColor: ColorsManager.success,
          ),
        );
      }

      widget.onShared?.call(platform);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share to $platform: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

/// Tournament follow widget
class TournamentFollowButton extends StatefulWidget {
  final Tournament tournament;
  final bool isFollowing;
  final Function(bool)? onFollowChanged;

  const TournamentFollowButton({
    super.key,
    required this.tournament,
    required this.isFollowing,
    this.onFollowChanged,
  });

  @override
  State<TournamentFollowButton> createState() => _TournamentFollowButtonState();
}

class _TournamentFollowButtonState extends State<TournamentFollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _toggleFollow,
      icon: _isLoading
          ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              _isFollowing ? Icons.favorite : Icons.favorite_border,
              size: 16.sp,
            ),
      label: Text(
        _isFollowing ? 'Following' : 'Follow',
        style: TextStyles.font14WhiteSemiBold,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? ColorsManager.success : ColorsManager.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement follow/unfollow functionality
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isFollowing = !_isFollowing;
      });

      widget.onFollowChanged?.call(_isFollowing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing 
                  ? 'You are now following this tournament!'
                  : 'You have unfollowed this tournament.',
            ),
            backgroundColor: _isFollowing ? ColorsManager.success : ColorsManager.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
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
}
