import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/chat_message.dart';

/// Widget for displaying shared entities in chat
class EntityCard extends StatelessWidget {
  final SharedEntity entity;
  final VoidCallback? onTap;
  final bool isInMessage;

  const EntityCard({
    super.key,
    required this.entity,
    this.onTap,
    this.isInMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isInMessage ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isInMessage 
              ? Colors.transparent 
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isInMessage ? 250.w : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (entity.imageUrl != null && entity.imageUrl!.isNotEmpty)
                _buildImage(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _getEntityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEntityIcon(),
            size: 16.sp,
            color: _getEntityColor(),
          ),
          SizedBox(width: 6.w),
          Text(
            entity.type.value.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _getEntityColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Additional safety check for empty URL
    if (entity.imageUrl == null || entity.imageUrl!.isEmpty) {
      return Container(
        height: isInMessage ? 120.h : 150.h,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: entity.imageUrl!,
        width: double.infinity,
        height: isInMessage ? 120.h : 150.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: isInMessage ? 120.h : 150.h,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              color: ColorsManager.mainBlue,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: isInMessage ? 120.h : 150.h,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entity.title,
            style: isInMessage
                ? TextStyles.font14DarkBlue600Weight
                : TextStyles.font16DarkBlue600Weight,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (entity.subtitle != null && entity.subtitle!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              entity.subtitle!,
              style: TextStyles.font12Grey400Weight,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entity.metadata != null && entity.metadata!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _buildMetadata(),
          ],
          if (!isInMessage) ...[
            SizedBox(height: 8.h),
            Text(
              'Tap to share in chat',
              style: TextStyle(
                fontSize: 11.sp,
                color: ColorsManager.mainBlue,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final metadata = entity.metadata!;
    final widgets = <Widget>[];

    // Add rating if available
    if (metadata['rating'] != null) {
      widgets.add(_buildMetadataItem(
        icon: Icons.star,
        text: '${metadata['rating']}',
        color: Colors.orange,
      ));
    }

    // Add price if available
    if (metadata['price'] != null) {
      widgets.add(_buildMetadataItem(
        icon: Icons.attach_money,
        text: '${metadata['price']}',
        color: Colors.green,
      ));
    }

    // Add location if available
    if (metadata['location'] != null) {
      widgets.add(_buildMetadataItem(
        icon: Icons.location_on,
        text: '${metadata['location']}',
        color: ColorsManager.gray,
      ));
    }

    // Add member count if available
    if (metadata['memberCount'] != null) {
      widgets.add(_buildMetadataItem(
        icon: Icons.group,
        text: '${metadata['memberCount']} members',
        color: ColorsManager.mainBlue,
      ));
    }

    // Add sport if available
    if (metadata['sport'] != null) {
      widgets.add(_buildMetadataItem(
        icon: Icons.sports,
        text: '${metadata['sport']}',
        color: ColorsManager.mainBlue,
      ));
    }

    return Wrap(
      spacing: 12.w,
      runSpacing: 4.h,
      children: widgets,
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: color,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getEntityIcon() {
    switch (entity.type) {
      case EntityType.profile:
        return Icons.person;
      case EntityType.venue:
        return Icons.location_city;
      case EntityType.team:
        return Icons.group;
      case EntityType.tournament:
        return Icons.emoji_events;
    }
  }

  Color _getEntityColor() {
    switch (entity.type) {
      case EntityType.profile:
        return ColorsManager.mainBlue;
      case EntityType.venue:
        return Colors.green;
      case EntityType.team:
        return Colors.purple;
      case EntityType.tournament:
        return Colors.orange;
    }
  }
}

/// Helper class for creating SharedEntity objects from different data types
class EntityHelper {
  /// Create SharedEntity from user profile
  static SharedEntity fromUserProfile({
    required String id,
    required String name,
    String? imageUrl,
    String? location,
    String? role,
  }) {
    return SharedEntity(
      type: EntityType.profile,
      id: id,
      title: name,
      imageUrl: imageUrl,
      subtitle: role != null ? '$role${location != null ? ' • $location' : ''}' : location,
      metadata: {
        if (role != null) 'role': role,
        if (location != null) 'location': location,
      },
    );
  }

  /// Create SharedEntity from venue
  static SharedEntity fromVenue({
    required String id,
    required String name,
    String? imageUrl,
    String? location,
    double? rating,
    String? priceRange,
  }) {
    return SharedEntity(
      type: EntityType.venue,
      id: id,
      title: name,
      imageUrl: imageUrl,
      subtitle: location,
      metadata: {
        if (rating != null) 'rating': rating.toStringAsFixed(1),
        if (priceRange != null) 'price': priceRange,
        if (location != null) 'location': location,
      },
    );
  }

  /// Create SharedEntity from team
  static SharedEntity fromTeam({
    required String id,
    required String name,
    String? imageUrl,
    String? sport,
    int? memberCount,
    String? location,
  }) {
    return SharedEntity(
      type: EntityType.team,
      id: id,
      title: name,
      imageUrl: imageUrl,
      subtitle: sport,
      metadata: {
        if (sport != null) 'sport': sport,
        if (memberCount != null) 'memberCount': memberCount,
        if (location != null) 'location': location,
      },
    );
  }

  /// Create SharedEntity from tournament
  static SharedEntity fromTournament({
    required String id,
    required String name,
    String? imageUrl,
    String? sport,
    String? location,
    String? date,
    String? prizePool,
  }) {
    return SharedEntity(
      type: EntityType.tournament,
      id: id,
      title: name,
      imageUrl: imageUrl,
      subtitle: sport != null && date != null ? '$sport • $date' : (sport ?? date),
      metadata: {
        if (sport != null) 'sport': sport,
        if (location != null) 'location': location,
        if (date != null) 'date': date,
        if (prizePool != null) 'prizePool': prizePool,
      },
    );
  }
}
