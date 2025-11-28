import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/detail_navigator.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/coach_profile.dart';
import '../../models/user_profile.dart';
import '../../models/player_profile.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../models/venue_booking.dart';
import '../../models/venue_review.dart';
import '../../modules/chat/screens/chat_screen.dart';
import '../../modules/chat/services/chat_service.dart';
import '../../modules/chat/models/chat_message.dart';
import '../../modules/chat/models/connection.dart';
import '../../repositories/user_repository.dart';
import '../../services/venue_service.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../venue/venue_booking_screen.dart';
import '../venue/widgets/venue_amenities_section.dart';
import '../venue/widgets/venue_booking_section.dart';
import '../venue/widgets/venue_hours_section.dart';
import '../venue/widgets/venue_image_carousel.dart';
import '../venue/widgets/venue_pricing_section.dart';
import '../venue/widgets/venue_reviews_section.dart';
import '../../modules/coach/screens/coach_detail_screen.dart';
import '../../modules/venue/screens/edit_venue_screen.dart';
import '../../modules/venue/services/venue_service.dart' as venue_module;

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
  List<CoachProfile> _venueCoaches = [];
  List<Map<String, dynamic>> _metadataCoaches = [];
  bool _isFavorite = false;
  final ChatService _chatService = ChatService();
  final UserRepository _userRepository = UserRepository();

  bool get _isDemoVenue =>
      widget.venue.ownerId == 'playaround_demo' ||
      widget.venue.id.toLowerCase().startsWith('demo_');

  LinearGradient get _sectionGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B1938),
          Color(0xFF070614),
        ],
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final slots =
          await VenueService.getAvailableSlots(widget.venue.id, today);

      final List<VenueReview> hydratedReviews = reviews.isNotEmpty
          ? reviews
          : (_isDemoVenue
              ? _buildFallbackReviews(widget.venue)
              : <VenueReview>[]);
      await _loadVenueCoaches();
      final metadataCoaches = _extractMetadataCoaches();

      setState(() {
        _reviews = hydratedReviews;
        _availableSlots = slots;
        _metadataCoaches = metadataCoaches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVenueCoaches() async {
    if (widget.venue.coachIds.isEmpty) {
      if (mounted) {
        setState(() => _venueCoaches = []);
      }
      return;
    }

    final fetchedCoaches = <CoachProfile>[];
    final coachIds = widget.venue.coachIds;
    for (var i = 0; i < coachIds.length && i < 6; i++) {
      final coachId = coachIds[i];
      try {
        final profile = await _userRepository.getUserProfile(coachId);
        if (profile is CoachProfile) {
          fetchedCoaches.add(profile);
        }
      } catch (_) {
        // Ignore errors for individual profiles
      }
    }

    if (mounted) {
      setState(() => _venueCoaches = fetchedCoaches);
    }
  }

  List<Map<String, dynamic>> _extractMetadataCoaches() {
    final metadata = widget.venue.metadata ?? const <String, dynamic>{};
    final rawCoaches =
        metadata['featuredCoaches'] ?? metadata['coaches'] ?? metadata['staff'];
    final parsed = <Map<String, dynamic>>[];

    if (rawCoaches is List) {
      for (final coach in rawCoaches) {
        if (coach is Map) {
          parsed.add(
            coach.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
        }
      }
    }

    if (parsed.isEmpty && _isDemoVenue) {
      return _buildDemoCoaches();
    }

    return parsed;
  }

  List<Map<String, dynamic>> _buildDemoCoaches() {
    final sport =
        widget.venue.sports.isNotEmpty ? widget.venue.sports.first : 'Performance';
    return [
      {
        'name': 'Coach Zara Qureshi',
        'specialization': '$sport Strategy Lead',
        'experienceYears': 8,
        'rating': 4.9,
        'summary':
            'High intensity conditioning, tactical video breakdowns, and personalised match plans.',
        'hourlyRate': 8500,
        'profileImageUrl':
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=600&q=80',
      },
      {
        'name': 'Bilal Khan',
        'specialization': '$sport Technical Director',
        'experienceYears': 11,
        'rating': 4.8,
        'summary':
            'Biomechanics-focused drills, recovery blueprints, and progress dashboards for squads.',
        'hourlyRate': 7600,
        'profileImageUrl':
            'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=600&q=80',
      },
      {
        'name': 'Sara Mehmood',
        'specialization': 'Elite Fitness & Rehab',
        'experienceYears': 9,
        'rating': 5.0,
        'summary':
            'Injury-prevention labs, data-driven load management, and mindset coaching in one plan.',
        'hourlyRate': 9000,
        'profileImageUrl':
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=600&q=80',
      },
    ];
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Implement favorite functionality
  }

  Future<void> _editVenue() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading venue details...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Fetch venue as VenueModel for editing
      final venueService = venue_module.VenueService();
      final venueModel = await venueService.getVenue(widget.venue.id);

      if (venueModel == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venue not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Navigate to edit screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditVenueScreen(venue: venueModel),
        ),
      );

      // Reload venue details if edited successfully
      if (result == true) {
        _loadVenueDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venue updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open edit screen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareVenue() {
    final shareLink = _buildShareLink();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ShareOptionsSheet(
          shareLink: shareLink,
          onShareInChat: () {
            Navigator.of(sheetContext).pop();
            _showShareInChatSheet(shareLink);
          },
          onCopyLink: () async {
            await Clipboard.setData(ClipboardData(text: shareLink));
            if (mounted) {
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shareable link copied to clipboard'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showShareInChatSheet(String shareLink) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to share venues in chat'),
            backgroundColor: ColorsManager.warning,
          ),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ShareVenueChatSheet(
          connectionsStream: _chatService.getUserConnections(),
          currentUserId: currentUser.uid,
          onConnectionSelected: (connection) {
            Navigator.of(sheetContext).pop();
            _handleShareWithConnection(
              connection: connection,
              currentUserId: currentUser.uid,
              shareLink: shareLink,
            );
          },
        );
      },
    );
  }

  Future<void> _handleShareWithConnection({
    required Connection connection,
    required String currentUserId,
    required String shareLink,
  }) async {
    try {
      await _ensureChatProfiles();

      final otherUserId = connection.getOtherUserId(currentUserId);
      final chatRoom = await _chatService.getOrCreateDirectChat(otherUserId);

      if (chatRoom == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open chat to share this venue'),
              backgroundColor: ColorsManager.warning,
            ),
          );
        }
        return;
      }

      final entity = _buildSharedEntity(shareLink);
      final success = await _chatService.sendEntityMessage(
        chatId: chatRoom.id,
        entity: entity,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shared with ${connection.getOtherUserName(currentUserId)}',
            ),
            backgroundColor: ColorsManager.primary,
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: chatRoom,
              backgroundImageUrl: widget.venue.images.isNotEmpty
                  ? widget.venue.images.first
                  : null,
              triggerCelebration: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share this venue right now'),
            backgroundColor: ColorsManager.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share venue: $e'),
            backgroundColor: ColorsManager.warning,
          ),
        );
      }
    }
  }

  SharedEntity _buildSharedEntity(String shareLink) {
    final location = _resolveVenueLocation();
    final metadata = <String, dynamic>{
      'link': shareLink,
      if (widget.venue.rating > 0) 'rating': widget.venue.rating.toStringAsFixed(1),
      if (widget.venue.pricing.hourlyRate > 0)
        'hourlyRate': widget.venue.pricing.hourlyRate.toStringAsFixed(0),
    }..removeWhere(
        (key, value) =>
            value == null ||
            (value is String && value.trim().isEmpty),
      );

    return SharedEntity(
      type: EntityType.venue,
      id: widget.venue.id,
      title: widget.venue.name,
      imageUrl: widget.venue.images.isNotEmpty ? widget.venue.images.first : null,
      subtitle: location.isNotEmpty ? location : null,
      metadata: metadata.isNotEmpty ? metadata : null,
    );
  }

  String _buildShareLink() {
    final encodedId = Uri.encodeComponent(widget.venue.id);
    final baseUrl = 'https://playaround.app/venues/$encodedId';

    final name = widget.venue.name.trim().toLowerCase();
    if (name.isEmpty) {
      return baseUrl;
    }

    final slug = name
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return slug.isNotEmpty ? '$baseUrl?name=$slug' : baseUrl;
  }

  String _resolveVenueLocation() {
    final parts = <String>[
      if (widget.venue.address.isNotEmpty) widget.venue.address,
      if (widget.venue.city.isNotEmpty) widget.venue.city,
      if (widget.venue.country.isNotEmpty) widget.venue.country,
    ];
    return parts.join(', ');
  }

  String? get _venuePhoneNumber {
    final metadata = widget.venue.metadata ?? const <String, dynamic>{};

    final candidates = [
      widget.venue.phoneNumber,
      metadata['phoneNumber']?.toString(),
      metadata['contactNumber']?.toString(),
      metadata['contact']?.toString(),
      metadata['contactInfo']?.toString(),
      metadata['phone']?.toString(),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  void _showInfoSnackBar(
    String message, {
    Color backgroundColor = ColorsManager.warning,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
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
      case 'INR':
        return '₹';
      default:
        return '$currency ';
    }
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

  Future<void> _openMaps() async {
    final mapsLink = widget.venue.googleMapsLink?.trim();
    Uri? uri;

    if (mapsLink != null && mapsLink.isNotEmpty) {
      uri = Uri.tryParse(mapsLink);
    }

    if (uri == null) {
      final lat = widget.venue.latitude;
      final lng = widget.venue.longitude;
      if (lat != 0 || lng != 0) {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );
      } else if (widget.venue.address.trim().isNotEmpty) {
        final encoded = Uri.encodeComponent(widget.venue.address);
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        );
      }
    }

    if (uri == null) {
      _showInfoSnackBar('Location details are not available.');
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showInfoSnackBar('Could not open Google Maps.');
    }
  }

  Future<void> _callVenue() async {
    final phone = _venuePhoneNumber;
    if (phone == null) {
      await _openMaps();
      return;
    }

    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) {
      _showInfoSnackBar('Phone number is unavailable.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showInfoSnackBar('Could not open the dialer.');
    }
  }

  void _openCoachProfile(CoachProfile coach) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoachDetailScreen(coach: coach),
      ),
    );
  }

  Future<void> _openMetadataCoach(Map<String, dynamic> coachData) async {
    final coachId = coachData['coachId']?.toString() ??
        coachData['id']?.toString() ??
        coachData['uid']?.toString();
    if (coachId != null && coachId.isNotEmpty) {
    final success = await DetailNavigator.openCoach(
      context,
      coachId: coachId,
    );

      if (success) {
        return;
      }
    }

    final fallbackProfile = _buildCoachProfileFromMetadata(coachData, coachId);
    if (fallbackProfile != null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachDetailScreen(coach: fallbackProfile),
        ),
      );
    } else {
      final name = (coachData['name'] ?? 'Coach').toString();
      _showInfoSnackBar(
        '$name\'s profile will be published soon.',
        backgroundColor: ColorsManager.warning,
      );
    }
  }

  Future<void> _handleBookingCreated(
    VenueBooking booking,
    BookingSlot slot,
  ) async {
    try {
      await _ensureChatProfiles();

      final chatRoom =
          await _chatService.getOrCreateDirectChat(widget.venue.ownerId);

      if (chatRoom == null) {
        throw Exception('Unable to open venue chat.');
      }

      final currencySymbol = _currencySymbol(booking.currency);
      final bookingMessage = '''
📩 New venue booking request!

🏟️ ${widget.venue.name}
📅 ${DateFormat('EEE, MMM d, yyyy').format(booking.startTime)}
🕒 ${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}
⏱ Duration: ${booking.duration} hour${booking.duration > 1 ? 's' : ''}
👥 Participants: ${booking.participants.length}
💳 Total: $currencySymbol${booking.totalAmount.toStringAsFixed(0)}${booking.specialRequests?.isNotEmpty == true ? '\n📝 Notes: ${booking.specialRequests}' : ''}
'''
          .trim();

      await _chatService.sendTextMessage(
        chatId: chatRoom.id,
        text: bookingMessage,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoom: chatRoom,
            backgroundImageUrl: widget.venue.images.isNotEmpty
                ? widget.venue.images.first
                : null,
            triggerCelebration: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking confirmed but chat could not be opened: $e'),
          backgroundColor: ColorsManager.warning,
        ),
      );
    } finally {
      _loadVenueDetails();
    }
  }

  CoachProfile? _buildCoachProfileFromMetadata(
    Map<String, dynamic> coachData,
    String? fallbackId,
  ) {
    final name = (coachData['name'] ?? coachData['title'])?.toString().trim();
    if (name == null || name.isEmpty) return null;

    List<String> _parseSports(dynamic value) {
      if (value is List) {
        return value
            .where((e) => e != null)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    List<TimeSlot> _parseAvailability(dynamic value) {
      if (value is List) {
        final slots = value
            .map((e) {
              if (e is Map<String, dynamic>) return TimeSlot.fromMap(e);
              if (e is Map) {
                return TimeSlot.fromMap(
                  e.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                );
              }
              return null;
            })
            .whereType<TimeSlot>()
            .toList();
        if (slots.isNotEmpty) {
          return slots;
        }
      }
      return const [
        TimeSlot(day: 'Flexible', startTime: 'Anytime', endTime: 'Anytime'),
      ];
    }

    double? _asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? _asInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final sports = _parseSports(
      coachData['specializationSports'] ??
          coachData['sports'] ??
          coachData['specialization'],
    );

    final location = (coachData['location'] ??
            coachData['city'] ??
            coachData['country'] ??
            widget.venue.address)
        .toString()
        .trim();

    final description =
        (coachData['summary'] ?? coachData['bio'])?.toString().trim();

    final experience = _asInt(coachData['experienceYears']) ?? 3;
    final hourlyRate = _asDouble(coachData['hourlyRate']) ??
        (widget.venue.pricing.hourlyRate > 0
            ? widget.venue.pricing.hourlyRate
            : null);
    final uid = fallbackId ??
        'metadata_${widget.venue.id}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

    return CoachProfile(
      uid: uid,
      fullName: name,
      gender: Gender.other,
      age: _asInt(coachData['age']) ?? 30,
      location: location.isNotEmpty ? location : widget.venue.address,
      profilePictureUrl: coachData['profileImageUrl']?.toString(),
      profilePhotos: const [],
      isProfileComplete: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      specializationSports: sports.isNotEmpty
          ? sports
          : (widget.venue.sports.isNotEmpty
              ? widget.venue.sports
              : <String>['Performance']),
      experienceYears: experience,
      certifications: coachData['certifications'] is List
          ? (coachData['certifications'] as List)
              .map((e) => e.toString())
              .toList()
          : null,
      hourlyRate: hourlyRate ?? 0,
      availableTimeSlots: _parseAvailability(
        coachData['availability'] ?? coachData['schedule'],
      ),
      coachingType: TrainingType.fromString(
        (coachData['coachingType'] ?? coachData['trainingType'] ?? 'both')
            .toString(),
      ),
      bio: description?.isNotEmpty == true
          ? description
          : 'High-performance coaching available at ${widget.venue.name}.',
    );
  }

  Future<void> _ensureChatProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in to continue.');
    }

    final currentProfile =
        await _userRepository.getUserProfile(currentUser.uid);
    if (currentProfile == null) {
      final now = DateTime.now();
      final fallbackSports = widget.venue.sports.isNotEmpty
          ? widget.venue.sports.take(2).toList()
          : ['Sports'];

      final fallbackProfile = PlayerProfile(
        uid: currentUser.uid,
        fullName: currentUser.displayName?.trim().isNotEmpty == true
            ? currentUser.displayName!.trim()
            : 'Player ${currentUser.uid.substring(0, 6)}',
        nickname: currentUser.displayName,
        bio: 'Auto-generated profile for quick venue bookings.',
        gender: Gender.other,
        age: 24,
        location: widget.venue.city.isNotEmpty
            ? widget.venue.city
            : widget.venue.country.isNotEmpty
                ? widget.venue.country
                : 'Unknown',
        profilePictureUrl: currentUser.photoURL,
        isProfileComplete: false,
        createdAt: now,
        updatedAt: now,
        sportsOfInterest: fallbackSports,
        skillLevel: SkillLevel.beginner,
        availability: const [
          TimeSlot(day: 'Flexible', startTime: 'Anytime', endTime: 'Anytime'),
        ],
        preferredTrainingType: TrainingType.both,
      );

      await _userRepository.saveUserProfile(fallbackProfile);
    }

    final ownerProfile =
        await _userRepository.getUserProfile(widget.venue.ownerId);
    if (ownerProfile == null) {
      final now = DateTime.now();
      final fallbackSports =
          widget.venue.sports.isNotEmpty ? widget.venue.sports : ['Venue'];

      final fallbackOwnerProfile = PlayerProfile(
        uid: widget.venue.ownerId,
        fullName: '${widget.venue.name} Team',
        bio: 'Auto-generated profile for venue management.',
        gender: Gender.other,
        age: 30,
        location: widget.venue.city.isNotEmpty
            ? widget.venue.city
            : widget.venue.country.isNotEmpty
                ? widget.venue.country
                : 'Unknown',
        profilePictureUrl:
            widget.venue.images.isNotEmpty ? widget.venue.images.first : null,
        isProfileComplete: false,
        createdAt: now,
        updatedAt: now,
        sportsOfInterest: fallbackSports,
        skillLevel: SkillLevel.beginner,
        availability: const [
          TimeSlot(day: 'Flexible', startTime: 'Anytime', endTime: 'Anytime'),
        ],
        preferredTrainingType: TrainingType.both,
      );

      await _userRepository.saveUserProfile(fallbackOwnerProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E0C22),
              Color(0xFF04030A),
            ],
          ),
        ),
        child: CustomScrollView(
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
                Flexible(
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editVenue();
                          break;
                        case 'report':
                          _reportVenue();
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isOwner = currentUser != null && 
                          currentUser.uid == widget.venue.ownerId;
                      
                      final items = <PopupMenuItem<String>>[];
                      
                      if (isOwner) {
                        items.add(
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Edit Venue',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      items.add(
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.report, color: Colors.red),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Report',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      
                      return items;
                    },
                  ),
                ),
              ],
            ),
            // Venue Info
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF18163A),
                        Color(0xFF080713),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: ColorsManager.primary.withOpacity(0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
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
                                  widget.venue.name,
                                  style: TextStyles.font24WhiteBold.copyWith(
                                    fontSize: 26.sp,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Gap(8.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: const Color(0xFFFFD76F),
                                      size: 20.sp,
                                    ),
                                    Gap(6.w),
                                    Expanded(
                                      child: Text(
                                        '${widget.venue.rating.toStringAsFixed(1)} • ${widget.venue.totalReviews} reviews',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.font13White400Weight
                                            .copyWith(
                                          color:
                                              Colors.white.withOpacity(0.8),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    if (widget.venue.isVerified) ...[
                                      Gap(10.w),
                                      Flexible(
                                        child: _StatusPill(
                                          icon: Icons.verified_rounded,
                                          label: 'Verified',
                                          gradient: ColorsManager.primaryGradient,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Gap(12.w),
                          Flexible(
                            child: _StatusPill(
                              icon: Icons.sports_soccer_rounded,
                              label: widget.venue.sports.isNotEmpty
                                  ? widget.venue.sports.first
                                  : 'Premium Venue',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00D1FF),
                                  Color(0xFF0077FF),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Gap(18.h),
                      _IconTextRow(
                        icon: Icons.location_on_rounded,
                        text: widget.venue.address,
                      ),
                      Gap(10.h),
                      if (_venuePhoneNumber != null) ...[
                        _IconTextRow(
                          icon: Icons.phone_outlined,
                          text: _venuePhoneNumber!,
                        ),
                        Gap(10.h),
                      ],
                      if (widget.venue.googleMapsLink != null &&
                          widget.venue.googleMapsLink!.trim().isNotEmpty)
                        _IconTextRow(
                          icon: Icons.map_outlined,
                          text: 'Google Maps • Tap directions to navigate',
                        ),
                      if (widget.venue.googleMapsLink != null &&
                          widget.venue.googleMapsLink!.trim().isNotEmpty)
                        Gap(10.h),
                      _IconTextRow(
                        icon: Icons.schedule_rounded,
                        text:
                            '${widget.venue.hours.weeklyHours.length} day schedule • ${widget.venue.amenities.length} amenities',
                      ),
                      Gap(16.h),
                      _SportsWrap(sports: widget.venue.sports),
                      Gap(20.h),
                      Text(
                        widget.venue.description,
                        style: TextStyles.font13White400Weight.copyWith(
                          color: Colors.white.withOpacity(0.78),
                          height: 1.5,
                        ),
                      ),
                      Gap(22.h),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.directions_rounded,
                              label: 'Directions',
                              onPressed: _openMaps,
                              isPrimary: true,
                            ),
                          ),
                          Gap(14.w),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.phone_forwarded_rounded,
                              label: 'Call',
                              onPressed: _callVenue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelStyle: TextStyles.font14White600Weight,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  labelColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: ColorsManager.primaryGradient,
                  ),
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Coaches'),
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
                  _buildCoachesTab(),
                  _buildReviewsTab(),
                  _buildBookingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14122E),
              Color(0xFF090817),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, -12),
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
                      'From ${_currencySymbol(widget.venue.pricing.currency)}${widget.venue.pricing.hourlyRate.toStringAsFixed(0)}',
                      style: TextStyles.font18DarkBlueBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Gap(4.h),
                    if (widget.venue.pricing.dailyRate > 0)
                      Text(
                        'Daily ${_currencySymbol(widget.venue.pricing.currency)}${widget.venue.pricing.dailyRate.toStringAsFixed(0)} • Weekly ${_currencySymbol(widget.venue.pricing.currency)}${widget.venue.pricing.weeklyRate.toStringAsFixed(0)}',
                        style: TextStyles.font12White500Weight.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Gap(18.w),
              Expanded(
                flex: 2,
                child: _ActionButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Book Now',
                  onPressed: _navigateToBooking,
                  isPrimary: true,
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
      primary: false,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
        decoration: BoxDecoration(
          gradient: _sectionGradient,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Top Amenities'),
            Gap(14.h),
            VenueAmenitiesSection(amenities: widget.venue.amenities),
            Gap(24.h),
            _SectionHeader(title: 'Pricing & Packages'),
            Gap(14.h),
            VenuePricingSection(pricing: widget.venue.pricing),
            Gap(24.h),
            _SectionHeader(title: 'Operating Hours'),
            Gap(14.h),
            VenueHoursSection(hours: widget.venue.hours),
              Gap(24.h),
            _SectionHeader(title: 'Available Sports'),
            Gap(12.h),
            _SportsWrap(sports: widget.venue.sports),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachesTab() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_venueCoaches.isEmpty && _metadataCoaches.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 32.h),
          decoration: BoxDecoration(
            gradient: _sectionGradient,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded,
                  size: 56.sp, color: Colors.white.withOpacity(0.8)),
              Gap(16.h),
              Text(
                'No on-site coaches listed for this venue yet.',
                textAlign: TextAlign.center,
                style: TextStyles.font14White500Weight.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
              Gap(8.h),
              Text(
                'Check back soon or contact the venue for coaching availability.',
                textAlign: TextAlign.center,
                style: TextStyles.font12White500Weight.copyWith(
                  color: Colors.white.withOpacity(0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
        decoration: BoxDecoration(
          gradient: _sectionGradient,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_venueCoaches.isNotEmpty) ...[
              _SectionHeader(title: 'Resident Coaches'),
              Gap(14.h),
              _VenueCoachesSection(
                coaches: _venueCoaches,
                onCoachTap: _openCoachProfile,
              ),
            ],
            if (_metadataCoaches.isNotEmpty) ...[
              if (_venueCoaches.isNotEmpty) Gap(28.h),
              _SectionHeader(
                title: _venueCoaches.isNotEmpty
                    ? 'Additional Coaches'
                    : 'Featured Coaches',
              ),
              Gap(14.h),
              _MetadataCoachesSection(
                coaches: _metadataCoaches,
                onCoachTap: _openMetadataCoach,
              ),
            ],
          ],
        ),
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
      backgroundGradient: _sectionGradient,
    );
  }

  Widget _buildBookingTab() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    return VenueBookingSection(
      venue: widget.venue,
      initialSlots: _availableSlots,
      onBookingCreated: _handleBookingCreated,
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white),
          Gap(6.w),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.font12White600Weight.copyWith(
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOptionsSheet extends StatelessWidget {
  final String shareLink;
  final VoidCallback onShareInChat;
  final VoidCallback onCopyLink;

  const _ShareOptionsSheet({
    required this.shareLink,
    required this.onShareInChat,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141126),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.chat_outlined, color: ColorsManager.primary),
              title: Text(
                'Share in chat',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Send this venue directly to your PlayAround connections',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              onTap: onShareInChat,
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Colors.white),
              title: Text(
                'Copy shareable link',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                shareLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                onPressed: onCopyLink,
              ),
              onTap: onCopyLink,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ShareVenueChatSheet extends StatelessWidget {
  final Stream<List<Connection>> connectionsStream;
  final String currentUserId;
  final ValueChanged<Connection> onConnectionSelected;

  const _ShareVenueChatSheet({
    required this.connectionsStream,
    required this.currentUserId,
    required this.onConnectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141126),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Container(
          height: maxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share in chat',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a connection to send this venue.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Connection>>(
                  stream: connectionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final connections = (snapshot.data ?? []).toSet().toList();
                    if (connections.isEmpty) {
                      return _EmptyConnectionsMessage(theme: theme);
                    }

                    return ListView.separated(
                      itemCount: connections.length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      itemBuilder: (context, index) {
                        final connection = connections[index];
                        final otherName =
                            connection.getOtherUserName(currentUserId);
                        final avatarUrl =
                            connection.getOtherUserImageUrl(currentUserId);
                        final initials = otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?';

                        return ListTile(
                          onTap: () => onConnectionSelected(connection),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                ColorsManager.primary.withOpacity(0.18),
                            backgroundImage: avatarUrl != null &&
                                    avatarUrl.trim().isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null ||
                                    avatarUrl.trim().isEmpty)
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            otherName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Tap to share',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          trailing: Icon(
                            Icons.send_rounded,
                            color: ColorsManager.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConnectionsMessage extends StatelessWidget {
  final ThemeData theme;

  const _EmptyConnectionsMessage({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.white.withOpacity(0.4),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No connections yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect with players and teams to share venues directly in chat.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTextRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconTextRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: ColorsManager.primary,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyles.font14White500Weight.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ),
      ],
    );
  }
}

class _SportsWrap extends StatelessWidget {
  final List<String> sports;

  const _SportsWrap({required this.sports});

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D1FF),
      const Color(0xFFFF6CAB),
      const Color(0xFFFFAA4C),
      const Color(0xFF4ADE80),
    ];

    return Wrap(
      spacing: 10.w,
      runSpacing: 8.h,
      children: sports.asMap().entries.map((entry) {
        final color = palette[entry.key % palette.length];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.55),
                color.withOpacity(0.25),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports,
                size: 14.sp,
                color: Colors.white,
              ),
              Gap(6.w),
              Text(
                entry.value,
                style: TextStyles.font12White600Weight,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VenueCoachesSection extends StatelessWidget {
  final List<CoachProfile> coaches;
  final ValueChanged<CoachProfile> onCoachTap;

  const _VenueCoachesSection({
    required this.coaches,
    required this.onCoachTap,
  });

  @override
  Widget build(BuildContext context) {
    if (coaches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: coaches
          .map(
            (coach) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _CoachListTile(
                name: coach.fullName,
                roleLabel: 'Coach',
                specialization: coach.specializationSports.isNotEmpty
                    ? coach.specializationSports.join(' • ')
                    : null,
                description: coach.bio,
                experienceYears: coach.experienceYears,
                hourlyRate: coach.hourlyRate > 0 ? coach.hourlyRate : null,
                location: coach.location,
                avatarUrl: coach.profilePictureUrl,
                accentColor: ColorsManager.primary,
            onTap: () => onCoachTap(coach),
      ),
            ),
          )
          .toList(),
    );
  }
}

class _MetadataCoachesSection extends StatelessWidget {
  final List<Map<String, dynamic>> coaches;
  final ValueChanged<Map<String, dynamic>> onCoachTap;

  const _MetadataCoachesSection({
    required this.coaches,
    required this.onCoachTap,
  });

  @override
  Widget build(BuildContext context) {
    if (coaches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: coaches
          .map(
            (coach) {
              final rating = (coach['rating'] as num?)?.toDouble();
              final experience = (coach['experienceYears'] as num?)?.toInt();
              final hourlyRate = (coach['hourlyRate'] as num?)?.toDouble();
              final role =
                  (coach['role'] ?? coach['title'] ?? 'Coach').toString();
              final location =
                  (coach['location'] ?? coach['city'] ?? '').toString().trim();

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _CoachListTile(
                  name: (coach['name'] ?? 'Coach').toString(),
                  roleLabel: role.isNotEmpty ? role : 'Coach',
                  specialization:
                      (coach['specialization'] ?? coach['focusArea'])
                          ?.toString(),
                  description:
                      (coach['summary'] ?? coach['bio'])?.toString(),
                  avatarUrl: coach['profileImageUrl']?.toString(),
                  rating: rating,
                  experienceYears: experience,
                  hourlyRate: hourlyRate,
                  location: location.isNotEmpty ? location : null,
                  accentColor: ColorsManager.warning,
            onTap: () => onCoachTap(coach),
                ),
          );
        },
          )
          .toList(),
    );
  }
}

class _CoachListTile extends StatelessWidget {
  final String name;
  final String? roleLabel;
  final String? specialization;
  final String? description;
  final String? location;
  final String? avatarUrl;
  final double? rating;
  final int? experienceYears;
  final double? hourlyRate;
  final Color accentColor;
  final VoidCallback? onTap;

  const _CoachListTile({
    required this.name,
    this.roleLabel,
    this.specialization,
    this.description,
    this.location,
    this.avatarUrl,
    this.rating,
    this.experienceYears,
    this.hourlyRate,
    this.accentColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = [
      if (specialization != null && specialization!.trim().isNotEmpty)
        specialization!.trim(),
      if (location != null && location!.trim().isNotEmpty) location!.trim(),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: accentColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
              radius: 26.r,
              backgroundColor: accentColor.withOpacity(0.18),
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: TextStyle(
                        color: accentColor,
                            fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                          ),
                        )
                      : null,
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTap,
                          child: Text(
                        name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
              ),
            ),
                        ),
                      ),
                if (rating != null)
                  Row(
                          mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                                color: ColorsManager.warning, size: 18.sp),
                      Gap(4.w),
                      Text(
                              rating!.toStringAsFixed(
                                  rating! % 1 == 0 ? 0 : 1),
                              style: TextStyles.font14White600Weight,
                      ),
                    ],
                  ),
              ],
            ),
                  if (subtitleParts.isNotEmpty) ...[
              Gap(6.h),
              Text(
                      subtitleParts.join(' • '),
                      style: TextStyles.font13White400Weight.copyWith(
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
            ],
                  Gap(8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
          children: [
                      if (roleLabel != null && roleLabel!.isNotEmpty)
                        _CoachInfoChip(
                          label: roleLabel!,
                          color: accentColor,
                        ),
                      if (experienceYears != null)
                        _CoachInfoChip(
                          label: '${experienceYears!}+ yrs exp',
                        ),
                      if (hourlyRate != null && hourlyRate! > 0)
                        _CoachInfoChip(
                          label: 'PKR ${hourlyRate!.toStringAsFixed(0)}/hr',
                      ),
                    ],
                  ),
                  if (description != null && description!.trim().isNotEmpty) ...[
                    Gap(10.h),
            Text(
                      description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
                      style: TextStyles.font12White500Weight.copyWith(
                color: Colors.white.withOpacity(0.8),
                        height: 1.4,
              ),
            ),
                  ],
                ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _CoachInfoChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _CoachInfoChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.white.withOpacity(0.8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: baseColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyles.font12White600Weight.copyWith(
          color: baseColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = isPrimary
        ? ColorsManager.primaryGradient
        : const LinearGradient(
            colors: [
              Color(0xFF1F1C3A),
              Color(0xFF0C0B18),
            ],
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: background,
            border: Border.all(
              color: Colors.white.withOpacity(isPrimary ? 0.28 : 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isPrimary ? 0.25 : 0.15),
                blurRadius: isPrimary ? 16 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: Colors.white,
              ),
              Gap(10.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyles.font14White600Weight.copyWith(
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            gradient: ColorsManager.primaryGradient,
          ),
        ),
        Gap(10.w),
        Text(
          title,
          style: TextStyles.font16DarkBlueBold.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

final Map<String, List<Map<String, dynamic>>> _demoVenueReviewsSeed = {
  'demo_prime_tennis': [
    {
      'userId': 'athlete_sana',
      'userName': 'Sana Qureshi',
      'rating': 4.9,
      'title': 'Elite coaching atmosphere',
      'comment':
          'The coaching bays and video analysis screens are top-notch. Courts feel tournament-ready every session.',
    },
    {
      'userId': 'club_capt_kashif',
      'userName': 'Kashif Mehmood',
      'rating': 4.8,
      'title': 'Night sessions are a dream',
      'comment':
          'Lighting is crisp, hydration bar is stocked, and the staff reset the ball machine after every drill. Love it.',
    },
  ],
  'demo_aurora_dome': [
    {
      'userId': 'goalkeeper_ali',
      'userName': 'Ali Raza',
      'rating': 4.7,
      'title': 'Perfect for high-tempo drills',
      'comment':
          'LED-lit turf with accurate line markings. Our team sprint training felt like a pro camp.',
    },
    {
      'userId': 'fitness_coach_mina',
      'userName': 'Coach Mina',
      'rating': 4.8,
      'title': 'Climate control wins it',
      'comment':
          'No humidity issues, and the recovery lounge has compression boots ready. Booking again next month.',
    },
  ],
  'demo_velocity_cricket': [
    {
      'userId': 'batsman_haris',
      'userName': 'Haris Baloch',
      'rating': 4.9,
      'title': 'Hawk-Eye analytics is accurate',
      'comment':
          'Coaches can instantly show projection paths. Turf wickets bounce consistently. Worth every rupee.',
    },
    {
      'userId': 'coach_sadiq',
      'userName': 'Coach Sadiq',
      'rating': 4.7,
      'title': 'Love the coach lounge',
      'comment':
          'We held a whole strategy session post-net. Live scoreboard helps batters gauge strike rate too.',
    },
  ],
  'demo_summit_complex': [
    {
      'userId': 'sprinter_zoya',
      'userName': 'Zoya Khan',
      'rating': 4.8,
      'title': 'Indoor track is blazing fast',
      'comment':
          'No slip, excellent traction, and the recovery spa downstairs sealed the deal. Coaches felt spoiled.',
    },
    {
      'userId': 'volley_captain_umar',
      'userName': 'Umar Nadeem',
      'rating': 4.7,
      'title': 'Multi-sport done right',
      'comment':
          'We booked back-to-back volleyball and strength sessions. Equipment is fresh and staff are proactive.',
    },
  ],
  'demo_zenith_courts': [
    {
      'userId': 'doubles_champ_hina',
      'userName': 'Hina Baig',
      'rating': 4.9,
      'title': 'Sunset matches hit different',
      'comment':
          'Shaded seating keeps supporters comfy. Hydration bar has electrolyte slushies. Courts bounce evenly.',
    },
    {
      'userId': 'junior_coach_ibrahim',
      'userName': 'Coach Ibrahim',
      'rating': 4.8,
      'title': 'Pickleball courts included!',
      'comment':
          'Switching between tennis and pickleball in one booking saved us planning headaches. Staff reset gear fast.',
    },
  ],
  'default': [
    {
      'userId': 'athlete_default_1',
      'userName': 'Aleena Tariq',
      'rating': 4.8,
      'title': 'Professional experience',
      'comment':
          'Loved the facility management and warm staff. We locked in weekly slots after the first visit.',
    },
    {
      'userId': 'athlete_default_2',
      'userName': 'Bilal Yusuf',
      'rating': 4.7,
      'title': 'Events ready venue',
      'comment':
          'Booking flow was smooth, and the support team handled all our requests promptly. Highly recommend.',
    },
  ],
};

List<VenueReview> _buildFallbackReviews(Venue venue) {
  final seeds = _demoVenueReviewsSeed[venue.id] ??
      _demoVenueReviewsSeed['default'] ??
      const <Map<String, dynamic>>[];

  if (seeds.isEmpty) {
    return [];
  }

  final now = DateTime.now();

  return seeds.asMap().entries.map((entry) {
    final index = entry.key;
    final seed = entry.value;
    final createdAt = now.subtract(Duration(days: (index + 1) * 4));

    return VenueReview(
      id: 'demo_review_${venue.id}_$index',
      venueId: venue.id,
      userId: seed['userId'] as String,
      userName: seed['userName'] as String,
      rating: (seed['rating'] as num).toDouble(),
      title: seed['title'] as String,
      comment: seed['comment'] as String,
      userAvatar: null,
      images: const [],
      categories: [
        ReviewCategory(
          name: 'Facilities',
          rating: ((seed['rating'] as num) + 0.1).clamp(0, 5).toDouble(),
          description: 'Condition and readiness of courts & surfaces',
        ),
        ReviewCategory(
          name: 'Staff',
          rating: ((seed['rating'] as num) - 0.1).clamp(0, 5).toDouble(),
          description: 'Coaching & support responsiveness',
        ),
      ],
      isVerified: true,
      bookingId: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      helpfulCount: 14 - index,
      helpfulUsers: const [],
      isReported: false,
      reportReason: null,
    );
  }).toList();
}
