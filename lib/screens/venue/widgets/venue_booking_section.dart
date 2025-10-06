import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/venue.dart';
import '../../../models/venue_booking.dart';
import '../../../services/venue_service.dart';

class VenueBookingSection extends StatefulWidget {
  final Venue venue;
  final List<BookingSlot> availableSlots;
  final VoidCallback? onBookingCreated;

  const VenueBookingSection({
    Key? key,
    required this.venue,
    required this.availableSlots,
    this.onBookingCreated,
  }) : super(key: key);

  @override
  State<VenueBookingSection> createState() => _VenueBookingSectionState();
}

class _VenueBookingSectionState extends State<VenueBookingSection> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  int _duration = 1;
  int _participants = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book This Venue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Quick Booking Form
        _buildQuickBookingForm(),
        const SizedBox(height: 24),
        // Available Slots
        if (widget.availableSlots.isNotEmpty) ...[
          Text(
            'Available Today',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAvailableSlots(),
        ] else ...[
          _buildNoSlotsAvailable(),
        ],
        const SizedBox(height: 24),
        // Book Now Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedTimeSlot != null ? _bookNow : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Book Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickBookingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Duration Selection
          Row(
            children: [
              Text(
                'Duration: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
                icon: const Icon(Icons.remove),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_duration hour${_duration > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _duration < 8 ? () => setState(() => _duration++) : null,
                icon: const Icon(Icons.add),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Participants Selection
          Row(
            children: [
              Text(
                'Participants: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: _participants > 1 ? () => setState(() => _participants--) : null,
                icon: const Icon(Icons.remove),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_participants participant${_participants > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _participants < 20 ? () => setState(() => _participants++) : null,
                icon: const Icon(Icons.add),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSlots() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableSlots.map((slot) {
        final isSelected = _selectedTimeSlot == slot.startTime;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = slot.startTime;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  slot.startTime,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${slot.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoSlotsAvailable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No slots available today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date or contact the venue directly',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _bookNow() async {
    if (_selectedTimeSlot == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final slot = widget.availableSlots.firstWhere(
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
        id: '',
        venueId: widget.venue.id,
        userId: 'current_user_id', // TODO: Get from auth service
        userName: 'Current User', // TODO: Get from user profile
        userEmail: 'user@example.com', // TODO: Get from user profile
        userPhone: '+1234567890', // TODO: Get from user profile
        startTime: startTime,
        endTime: endTime,
        duration: _duration,
        totalAmount: slot.price * _duration,
        participants: List.generate(_participants, (index) => 'Participant ${index + 1}'),
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
        widget.onBookingCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created for ${DateFormat('MMM dd, yyyy').format(startTime)} at ${slot.startTime}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // TODO: Navigate to booking details
              },
            ),
          ),
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
          _isLoading = false;
        });
      }
    }
  }
}
