import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/venue.dart';
import '../../models/venue_booking.dart';
import '../../models/venue_review.dart';
import '../../services/venue_service.dart';
import '../../core/widgets/loading_widget.dart';
import '../venue/widgets/venue_image_carousel.dart';
import '../venue/widgets/venue_amenities_section.dart';
import '../venue/widgets/venue_pricing_section.dart';
import '../venue/widgets/venue_reviews_section.dart';
import '../venue/widgets/venue_booking_section.dart';
import '../venue/widgets/venue_hours_section.dart';
import '../venue/venue_booking_screen.dart';

class VenueProfileScreen extends StatefulWidget {
  final Venue venue;

  const VenueProfileScreen({
    super.key,
    required this.venue,
  });

  @override
  State<VenueProfileScreen> createState() => _VenueProfileScreenState();
}

class _VenueProfileScreenState extends State<VenueProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  List<VenueReview> _reviews = [];
  List<BookingSlot> _availableSlots = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVenueDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVenueDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load reviews
      final reviews = await VenueService.getVenueReviews(widget.venue.id);
      
      // Load available slots for today
      final today = DateTime.now();
      final slots = await VenueService.getAvailableSlots(widget.venue.id, today);

      setState(() {
        _reviews = reviews;
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Implement favorite functionality
  }

  void _shareVenue() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _reportVenue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Venue'),
        content: const Text('Are you sure you want to report this venue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueBookingScreen(venue: widget.venue),
      ),
    );
  }

  void _openMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.venue.latitude},${widget.venue.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _callVenue() async {
    // TODO: Get venue phone number from venue data
    final phoneNumber = '+1234567890'; // Placeholder
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: VenueImageCarousel(
                images: widget.venue.images,
                venue: widget.venue,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
              ),
              IconButton(
                onPressed: _shareVenue,
                icon: const Icon(Icons.share, color: Colors.white),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'report':
                      _reportVenue();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Venue Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.venue.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.venue.rating.toStringAsFixed(1)} (${widget.venue.totalReviews} reviews)',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (widget.venue.isVerified) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Address and Actions
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.venue.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sports, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.venue.sports.join(', '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _callVenue,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    widget.venue.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Booking'),
                ],
              ),
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildReviewsTab(),
                _buildBookingTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From \$${widget.venue.pricing.hourlyRate.toStringAsFixed(0)}/hour',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per hour',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _navigateToBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amenities
          VenueAmenitiesSection(amenities: widget.venue.amenities),
          const SizedBox(height: 24),
          // Pricing
          VenuePricingSection(pricing: widget.venue.pricing),
          const SizedBox(height: 24),
          // Hours
          VenueHoursSection(hours: widget.venue.hours),
          const SizedBox(height: 24),
          // Sports
          Text(
            'Available Sports',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.venue.sports.map((sport) {
              return Chip(
                label: Text(sport),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    return VenueReviewsSection(
      reviews: _reviews,
      venueId: widget.venue.id,
      onReviewAdded: () => _loadVenueDetails(),
    );
  }

  Widget _buildBookingTab() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    return VenueBookingSection(
      venue: widget.venue,
      availableSlots: _availableSlots,
      onBookingCreated: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully!')),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
