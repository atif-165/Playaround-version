import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../models/venue_model.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/venue_service.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_screen.dart';

/// Widget for booking venue with calendar selection
class VenueBookingCalendar extends StatefulWidget {
  final VenueModel venue;
  final VoidCallback onBookingConfirmed;

  const VenueBookingCalendar({
    super.key,
    required this.venue,
    required this.onBookingConfirmed,
  });

  @override
  State<VenueBookingCalendar> createState() => _VenueBookingCalendarState();
}

class _VenueBookingCalendarState extends State<VenueBookingCalendar> {
  final VenueService _venueService = VenueService();
  final ChatService _chatService = ChatService();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  List<TimeSlot> _availableTimeSlots = [];
  bool _isLoadingTimeSlots = false;
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVenueInfo(),
                  Gap(24.h),
                  _buildDateSelection(),
                  if (_selectedDate != null) ...[
                    Gap(24.h),
                    _buildTimeSlotSelection(),
                  ],
                  if (_selectedTimeSlot != null) ...[
                    Gap(24.h),
                    _buildNotesSection(),
                    Gap(24.h),
                    _buildBookingSummary(),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedDate != null && _selectedTimeSlot != null)
            _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Book Venue',
            style: TextStyles.font18DarkBlueBold,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildVenueInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorsManager.mainBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_city,
            color: ColorsManager.mainBlue,
            size: 20.sp,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.venue.title,
                  style: TextStyles.font14DarkBlueBold,
                ),
                Gap(2.h),
                Text(
                  '₹${widget.venue.hourlyRate.toStringAsFixed(0)}/hour',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: ColorsManager.mainBlue, // Selected date color
                    onPrimary: Colors.white, // Selected date text color
                    surface: Colors.white, // Calendar background
                    onSurface: Colors.black87, // Default text color
                  ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: ColorsManager.mainBlue, // Navigation buttons
                ),
              ),
            ),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: _onDateSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        if (_isLoadingTimeSlots)
          const Center(child: CustomProgressIndicator())
        else if (_availableTimeSlots.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 16.sp,
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    'No time slots available for selected date',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _availableTimeSlots.map((timeSlot) {
              final isSelected = _selectedTimeSlot == timeSlot;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = isSelected ? null : timeSlot;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? ColorsManager.mainBlue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.mainBlue
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    '${timeSlot.start} - ${timeSlot.end}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Any special requirements or notes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedDate == null || _selectedTimeSlot == null)
      return const SizedBox.shrink();

    final duration = _selectedTimeSlot!.durationInHours;
    final totalAmount = widget.venue.hourlyRate * duration;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyles.font14DarkBlueBold,
          ),
          Gap(8.h),
          _buildSummaryRow('Date', _formatDate(_selectedDate!)),
          _buildSummaryRow('Time',
              '${_selectedTimeSlot!.start} - ${_selectedTimeSlot!.end}'),
          _buildSummaryRow('Duration', '${duration.toStringAsFixed(1)} hours'),
          _buildSummaryRow(
              'Rate', '₹${widget.venue.hourlyRate.toStringAsFixed(0)}/hour'),
          Divider(color: Colors.green.withValues(alpha: 0.3)),
          _buildSummaryRow('Total Amount', '₹${totalAmount.toStringAsFixed(0)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14.sp : 12.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green[700] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 14.sp : 12.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isBooking ? null : _bookVenue,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsManager.mainBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _isBooking
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirm Booking',
                  style: TextStyles.font16White600Weight,
                ),
        ),
      ),
    );
  }

  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
      _isLoadingTimeSlots = true;
    });

    try {
      final timeSlots = await _venueService.getAvailableTimeSlots(
        venueId: widget.venue.id,
        date: date,
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        _isLoadingTimeSlots = false;
      });
    } catch (e) {
      setState(() {
        _availableTimeSlots = [];
        _isLoadingTimeSlots = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load time slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookVenue() async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    // Additional validation checks
    if (!_isValidBookingTime()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot book in the past or too close to current time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // Check for double booking before proceeding
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final hasConflict = await _venueService.hasConflictingBooking(
        userId: user.uid,
        date: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
      );

      if (hasConflict) {
        throw Exception('You already have a booking at this time');
      }

      // Verify time slot is still available (race condition protection)
      final isStillAvailable = await _venueService.isTimeSlotAvailable(
        venueId: widget.venue.id,
        date: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
      );

      if (!isStillAvailable) {
        throw Exception('This time slot is no longer available');
      }

      final bookingId = await _venueService.bookVenue(
        venueId: widget.venue.id,
        selectedDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Create or get existing chat with venue owner
      final chatRoom = await _chatService.getOrCreateDirectChat(
        widget.venue.ownerId,
      );

      if (chatRoom != null) {
        // Send initial booking message to chat
        await _chatService.sendTextMessage(
          chatId: chatRoom.id,
          text:
              '🏟️ I just booked your venue "${widget.venue.title}" for ${_formatDate(_selectedDate!)} at ${_selectedTimeSlot!.start}. Looking forward to it!',
        );
      }

      // Show local success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking confirmed! Opening chat with venue owner...',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to chat screen
      if (mounted && chatRoom != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      } else {
        widget.onBookingConfirmed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
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

  /// Validate if the selected booking time is valid
  bool _isValidBookingTime() {
    if (_selectedDate == null || _selectedTimeSlot == null) return false;

    final now = DateTime.now();
    final bookingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(_selectedTimeSlot!.start.split(':')[0]),
      int.parse(_selectedTimeSlot!.start.split(':')[1]),
    );

    // Must be at least 1 hour in the future
    return bookingDateTime.isAfter(now.add(const Duration(hours: 1)));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
