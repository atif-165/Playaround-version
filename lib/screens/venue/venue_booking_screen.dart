import 'package:flutter/material.dart';
import '../../models/venue.dart';
import '../../models/venue_booking.dart';
import '../../services/venue_service.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../venue/widgets/booking_calendar.dart';
import '../venue/widgets/booking_time_slots.dart';
import '../venue/widgets/booking_summary.dart';

class VenueBookingScreen extends StatefulWidget {
  final Venue venue;

  const VenueBookingScreen({
    super.key,
    required this.venue,
  });

  @override
  State<VenueBookingScreen> createState() => _VenueBookingScreenState();
}

class _VenueBookingScreenState extends State<VenueBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  int _duration = 1;
  int _participants = 1;
  List<BookingSlot> _availableSlots = [];
  bool _isLoading = false;
  String? _error;
  bool _isBooking = false;

  final TextEditingController _participantsController =
      TextEditingController(text: '1');
  final TextEditingController _specialRequestsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _participantsController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await VenueService.getAvailableSlots(
        widget.venue.id,
        _selectedDate,
      );

      setState(() {
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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
    });
    _loadAvailableSlots();
  }

  void _onTimeSlotSelected(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  void _onDurationChanged(int duration) {
    setState(() {
      _duration = duration;
      _selectedTimeSlot = null;
    });
  }

  void _onParticipantsChanged(int participants) {
    setState(() {
      _participants = participants;
    });
  }

  double _calculateTotalPrice() {
    if (_selectedTimeSlot == null) return 0.0;

    final slot = _availableSlots.firstWhere(
      (slot) => slot.startTime == _selectedTimeSlot,
    );

    return slot.price * _duration;
  }

  String get _currencySymbol =>
      _resolveCurrencySymbol(widget.venue.pricing.currency);

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

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled
                ? Colors.black.withOpacity(0.04)
                : Theme.of(context).primaryColor.withOpacity(0.14),
            border: Border.all(
              color: isDisabled
                  ? Colors.black.withOpacity(0.06)
                  : Theme.of(context).primaryColor.withOpacity(0.28),
            ),
          ),
          child: Icon(
            icon,
            color: isDisabled
                ? Colors.black.withOpacity(0.25)
                : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCounterValue(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Future<void> _createBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final slot = _availableSlots.firstWhere(
        (slot) => slot.startTime == _selectedTimeSlot,
      );

      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(slot.startTime.split(':')[0]),
        int.parse(slot.startTime.split(':')[1]),
      );

      final endTime = startTime.add(Duration(hours: _duration));

      final booking = VenueBooking(
        id: '', // Will be generated by Firestore
        venueId: widget.venue.id,
        userId: 'current_user_id', // TODO: Get from auth service
        userName: 'Current User', // TODO: Get from user profile
        userEmail: 'user@example.com', // TODO: Get from user profile
        userPhone: '+1234567890', // TODO: Get from user profile
        startTime: startTime,
        endTime: endTime,
        duration: _duration,
        totalAmount: _calculateTotalPrice(),
        currency: widget.venue.pricing.currency,
        participants:
            List.generate(_participants, (index) => 'Participant ${index + 1}'),
        specialRequests: _specialRequestsController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await VenueService.createBooking(booking);

      // Update slot availability
      await VenueService.updateSlotAvailability(
        slot.id,
        false,
        booking.id,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Venue'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show booking help/info
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Venue Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.venue.images.isNotEmpty
                        ? widget.venue.images.first
                        : '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.venue.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.venue.address,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Booking Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  BookingCalendar(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                  const SizedBox(height: 24),
                  // Duration Selection
                  Text(
                    'Duration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildCounterButton(
                        icon: Icons.remove,
                        onPressed: _duration > 1
                            ? () => _onDurationChanged(_duration - 1)
                            : null,
                      ),
                      _buildCounterValue(
                        context,
                        '$_duration hour${_duration > 1 ? 's' : ''}',
                      ),
                      _buildCounterButton(
                        icon: Icons.add,
                        onPressed: _duration < 8
                            ? () => _onDurationChanged(_duration + 1)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Time Slots
                  Text(
                    'Available Time Slots',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: LoadingWidget())
                  else if (_error != null)
                    AppErrorWidget(
                      message: _error!,
                      onRetry: _loadAvailableSlots,
                    )
                  else
                    BookingTimeSlots(
                      slots: _availableSlots,
                      selectedSlot: _selectedTimeSlot,
                      duration: _duration,
                      onSlotSelected: _onTimeSlotSelected,
                      currencySymbol: _currencySymbol,
                    ),
                  const SizedBox(height: 24),
                  // Participants
                  Text(
                    'Number of Participants',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildCounterButton(
                        icon: Icons.remove,
                        onPressed: _participants > 1
                            ? () => _onParticipantsChanged(_participants - 1)
                            : null,
                      ),
                      _buildCounterValue(
                        context,
                        '$_participants participant${_participants > 1 ? 's' : ''}',
                      ),
                      _buildCounterButton(
                        icon: Icons.add,
                        onPressed: _participants < 20
                            ? () => _onParticipantsChanged(_participants + 1)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Special Requests
                  Text(
                    'Special Requests (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _specialRequestsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Any special requirements or notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Booking Summary
                  if (_selectedTimeSlot != null)
                    BookingSummary(
                      venue: widget.venue,
                      selectedDate: _selectedDate,
                      selectedTimeSlot: _selectedTimeSlot!,
                      duration: _duration,
                      participants: _participants,
                      totalPrice: _calculateTotalPrice(),
                      currencySymbol: _currencySymbol,
                    ),
                ],
              ),
            ),
          ),
          // Bottom Action Bar
          Container(
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
                          'Total: $_currencySymbol${_calculateTotalPrice().toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'for $_duration hour${_duration > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedTimeSlot != null && !_isBooking
                          ? _createBooking
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isBooking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
                                    'Confirm Booking',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
