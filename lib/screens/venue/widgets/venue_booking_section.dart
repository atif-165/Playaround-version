import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/venue.dart';
import '../../../models/venue_booking.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/venue_service.dart';
import '../../../theming/colors.dart';
import 'booking_calendar.dart';
import 'booking_summary.dart';
import 'booking_time_slots.dart';

class VenueBookingSection extends StatefulWidget {
  final Venue venue;
  final List<BookingSlot> initialSlots;
  final void Function(VenueBooking booking, BookingSlot slot)? onBookingCreated;

  const VenueBookingSection({
    Key? key,
    required this.venue,
    this.initialSlots = const [],
    this.onBookingCreated,
  }) : super(key: key);

  @override
  State<VenueBookingSection> createState() => _VenueBookingSectionState();
}

class _VenueBookingSectionState extends State<VenueBookingSection> {
  final UserRepository _userRepository = UserRepository();
  final TextEditingController _notesController = TextEditingController();

  late DateTime _selectedDate;
  List<BookingSlot> _availableSlots = [];
  String? _selectedSlot;
  int _duration = 1;
  int _participants = 4;
  bool _isFetchingSlots = false;
  bool _isCreatingBooking = false;
  String? _slotsError;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _availableSlots = widget.initialSlots;
    if (_availableSlots.isEmpty) {
      _fetchSlotsFor(_selectedDate);
    }
  }

  @override
  void didUpdateWidget(covariant VenueBookingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlots != widget.initialSlots &&
        widget.initialSlots.isNotEmpty) {
      setState(() {
        _availableSlots = widget.initialSlots;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B1938), Color(0xFF070614)],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity;

        return SingleChildScrollView(
          primary: false,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.primary.withOpacity(0.18),
                      blurRadius: 26,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorsManager.primary.withOpacity(0.16),
                          ),
                          child: Icon(
                            Icons.event_available_rounded,
                            color: ColorsManager.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Book This Venue',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lock in a slot instantly and notify the venue team right away.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BookingCalendar(
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateChanged,
                    ),
                    const SizedBox(height: 24),
                    _buildControls(context),
                    const SizedBox(height: 24),
                    if (_isFetchingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (_slotsError != null)
                      _buildSlotsError(context)
                    else
                      BookingTimeSlots(
                        slots: _availableSlots,
                        selectedSlot: _selectedSlot,
                        duration: _duration,
                        onSlotSelected: _onSlotSelected,
                        currencySymbol: _currencySymbol,
                      ),
                    if (_selectedSlot != null) ...[
                      const SizedBox(height: 24),
                      BookingSummary(
                        venue: widget.venue,
                        selectedDate: _selectedDate,
                        selectedTimeSlot: _selectedSlot!,
                        duration: _duration,
                        participants: _participants,
                        totalPrice: _calculateTotal(),
                        currencySymbol: _currencySymbol,
                      ),
                      const SizedBox(height: 20),
                      _buildNotesField(context),
                    ],
                    const SizedBox(height: 24),
                    _buildBookButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool canFitTwo = maxWidth >= 420;
        final double cardWidth = canFitTwo ? (maxWidth - 12) / 2 : maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCounterCard(
              width: cardWidth,
              icon: Icons.timer_outlined,
              label: 'Duration',
              subtitle: 'Hourly blocks',
              valueText: '$_duration hour${_duration > 1 ? 's' : ''}',
              onIncrement:
                  _duration < 8 ? () => setState(() => _duration++) : null,
              onDecrement:
                  _duration > 1 ? () => setState(() => _duration--) : null,
            ),
            _buildCounterCard(
              width: cardWidth,
              icon: Icons.groups_rounded,
              label: 'Participants',
              subtitle: 'Players joining',
              valueText: '$_participants player${_participants > 1 ? 's' : ''}',
              onIncrement: _participants < 40
                  ? () => setState(() => _participants++)
                  : null,
              onDecrement: _participants > 1
                  ? () => setState(() => _participants--)
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounterCard({
    required double width,
    required IconData icon,
    required String label,
    String? subtitle,
    required String valueText,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF141130), Color(0xFF0A091B)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorsManager.primary.withOpacity(0.18),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: ColorsManager.primary.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCounterButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Center(
                    child: Text(
                      valueText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({required IconData icon, VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled
                ? Colors.white.withOpacity(0.05)
                : ColorsManager.primary.withOpacity(0.22),
            border: Border.all(
              color: isDisabled
                  ? Colors.white.withOpacity(0.08)
                  : ColorsManager.primary.withOpacity(0.4),
            ),
          ),
          child: Icon(
            icon,
            color: isDisabled ? Colors.white.withOpacity(0.35) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsError(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.red.withOpacity(0.12),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load slots',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _slotsError ?? 'Something went wrong while fetching availability.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _fetchSlotsFor(_selectedDate),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Requests (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'Share squad details, preferred setup, or equipment needs…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: ColorsManager.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton(BuildContext context) {
    final total = _selectedSlot != null ? _calculateTotal() : 0.0;
    final label = _selectedSlot != null
        ? 'Confirm Booking • $_currencySymbol${total.toStringAsFixed(0)}'
        : 'Select a time slot to continue';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _selectedSlot != null && !_isCreatingBooking ? _bookNow : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isCreatingBooking
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _onDateChanged(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    setState(() {
      _selectedDate = normalized;
      _selectedSlot = null;
    });
    _fetchSlotsFor(normalized);
  }

  void _onSlotSelected(String slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  Future<void> _fetchSlotsFor(DateTime date) async {
    setState(() {
      _isFetchingSlots = true;
      _slotsError = null;
    });

    try {
      final slots = await VenueService.getAvailableSlots(
        widget.venue.id,
        date,
      );

      if (!mounted) return;

      setState(() {
        _availableSlots = slots;
        if (_selectedSlot != null &&
            !_availableSlots
                .any((element) => element.startTime == _selectedSlot)) {
          _selectedSlot = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingSlots = false;
        });
      }
    }
  }

  BookingSlot? _findSlot(String? slotStart) {
    if (slotStart == null) return null;
    for (final slot in _availableSlots) {
      if (slot.startTime == slotStart) {
        return slot;
      }
    }
    return null;
  }

  double _calculateTotal() {
    final slot = _findSlot(_selectedSlot);
    if (slot != null && slot.price > 0) {
      return slot.price * _duration;
    }
    final hourlyRate = widget.venue.pricing.hourlyRate;
    return hourlyRate > 0 ? hourlyRate * _duration : 0.0;
  }

  String get _currencySymbol {
    final slot = _findSlot(_selectedSlot);
    final currency = slot?.currency.isNotEmpty == true
        ? slot!.currency
        : widget.venue.pricing.currency;
    return _resolveCurrencySymbol(currency);
  }

  Future<_BookingUserInfo> _getCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please sign in to book this venue.');
    }

    final profile = await _userRepository.getUserProfile(user.uid);
    final name = profile?.fullName ?? user.displayName ?? 'PlayAround Athlete';
    final phone = user.phoneNumber ?? '';
    final email = user.email ?? '';

    return _BookingUserInfo(
      uid: user.uid,
      name: name,
      email: email,
      phone: phone,
    );
  }

  Future<void> _bookNow() async {
    if (_selectedSlot == null) {
      _showSnackBar('Select a time slot to continue.');
      return;
    }

    final slot = _findSlot(_selectedSlot);
    if (slot == null) {
      _showSnackBar('This slot is no longer available.');
      _fetchSlotsFor(_selectedDate);
      return;
    }

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final userInfo = await _getCurrentUserInfo();

      final startParts = slot.startTime.split(':');
      final startHour = int.tryParse(startParts.first) ?? 0;
      final startMinute =
          startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;

      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        startHour,
        startMinute,
      );

      final endTime = startTime.add(Duration(hours: _duration));
      final total = _calculateTotal();
      final currency = slot.currency.isNotEmpty
          ? slot.currency
          : widget.venue.pricing.currency;

      final booking = VenueBooking(
        id: '',
        venueId: widget.venue.id,
        userId: userInfo.uid,
        userName: userInfo.name,
        userEmail: userInfo.email,
        userPhone: userInfo.phone,
        startTime: startTime,
        endTime: endTime,
        duration: _duration,
        totalAmount: total,
        currency: currency,
        specialRequests: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        participants: List.generate(
          _participants,
          (index) => 'Participant ${index + 1}',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bookingId = await VenueService.createBooking(booking);
      await VenueService.updateSlotAvailability(
        slot.id,
        false,
        bookingId,
      );

      if (!mounted) return;

      final savedBooking = booking.copyWith(id: bookingId);
      widget.onBookingCreated?.call(savedBooking, slot);

      setState(() {
        _isCreatingBooking = false;
        _selectedSlot = null;
        _availableSlots =
            _availableSlots.where((element) => element.id != slot.id).toList();
      });

      _notesController.clear();

      _showSnackBar(
        'Booking confirmed for ${DateFormat('MMM dd, yyyy').format(startTime)} at ${slot.startTime}',
        background: ColorsManager.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to create booking: ${e.toString()}',
        background: ColorsManager.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
        _fetchSlotsFor(_selectedDate);
      }
    }
  }

  void _showSnackBar(String message, {Color? background}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background ?? ColorsManager.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _resolveCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'PKR':
        return '₨';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ ';
      case 'INR':
        return '₹';
      default:
        return '$currency ';
    }
  }
}

class _BookingUserInfo {
  final String uid;
  final String name;
  final String email;
  final String phone;

  const _BookingUserInfo({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
  });
}
