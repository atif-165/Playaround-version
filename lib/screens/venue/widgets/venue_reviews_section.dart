import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/venue_review.dart';
import '../../../services/venue_service.dart';

class VenueReviewsSection extends StatefulWidget {
  final List<VenueReview> reviews;
  final String venueId;
  final VoidCallback? onReviewAdded;

  const VenueReviewsSection({
    Key? key,
    required this.reviews,
    required this.venueId,
    this.onReviewAdded,
  }) : super(key: key);

  @override
  State<VenueReviewsSection> createState() => _VenueReviewsSectionState();
}

class _VenueReviewsSectionState extends State<VenueReviewsSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showWriteReviewDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Write Review'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Reviews List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final review = widget.reviews[index];
            return _buildReviewCard(context, review);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.reviews,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No reviews yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be the first to share your experience!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showWriteReviewDialog,
          icon: const Icon(Icons.edit),
          label: const Text('Write First Review'),
        ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, VenueReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Review Header
        Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: review.userAvatar != null
                  ? CachedNetworkImageProvider(review.userAvatar!)
                  : null,
              child: review.userAvatar == null
                  ? Text(
                      review.userName.isNotEmpty
                          ? review.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (review.isVerified) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Helpful Button
            IconButton(
              onPressed: () => _toggleHelpful(review),
              icon: Icon(
                Icons.thumb_up,
                color: review.helpfulUsers.contains('current_user_id')
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                size: 20,
              ),
            ),
            Text(
              '${review.helpfulCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Review Title
        if (review.title.isNotEmpty) ...[
          Text(
            review.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Review Comment
        Text(
          review.comment,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // Review Images
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: review.images[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Review Categories
        if (review.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: review.categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 12,
                    ),
                    Text(
                      category.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showWriteReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => _WriteReviewDialog(
        venueId: widget.venueId,
        onReviewAdded: () {
          widget.onReviewAdded?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleHelpful(VenueReview review) {
    // TODO: Implement helpful toggle functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Helpful functionality coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _WriteReviewDialog extends StatefulWidget {
  final String venueId;
  final VoidCallback onReviewAdded;

  const _WriteReviewDialog({
    required this.venueId,
    required this.onReviewAdded,
  });

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate() || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = VenueReview(
        id: '',
        venueId: widget.venueId,
        userId: 'current_user_id', // TODO: Get from auth service
        userName: 'Current User', // TODO: Get from user profile
        rating: _rating,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await VenueService.createReview(review);
      widget.onReviewAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write Review'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rating
              Text(
                'Rating',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Comment
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Your Review *',
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a review';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
