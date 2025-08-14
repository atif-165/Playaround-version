import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../core/widgets/progress_indicator.dart';
import '../../../helpers/extensions.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/booking_service.dart';
import '../widgets/time_slot_grid.dart';

/// Screen for the booking flow with date and time selection
class BookingFlowScreen extends StatefulWidget {
  final ListingModel listing;

  const BookingFlowScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _bookingService = BookingService();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  List<TimeSlot> _availableTimeSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTimeSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTimeSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
    });

    try {
      final slots = await _bookingService.getAvailableTimeSlots(
        widget.listing.id,
        _selectedDate,
      );

      setState(() {
        _availableTimeSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
      });
      if (mounted) {
        context.showSnackBar('Failed to load available time slots');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Session',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListingInfo(),
            Gap(24.h),
            _buildDateSelection(),
            Gap(24.h),
            _buildTimeSlotSelection(),
            Gap(24.h),
            _buildNotesSection(),
            Gap(24.h),
            _buildBookingSummary(),
            Gap(32.h),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildListingInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.mainBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.listing.title,
            style: TextStyles.font18DarkBlueBold,
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16.sp,
                color: ColorsManager.mainBlue,
              ),
              Gap(4.w),
              Text(
                widget.listing.ownerName,
                style: TextStyles.font14BlueRegular,
              ),
              const Spacer(),
              Text(
                '\$${widget.listing.hourlyRate.toStringAsFixed(0)}/hour',
                style: TextStyles.font16DarkBlueBold,
              ),
            ],
          ),
          Gap(8.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16.sp,
                color: ColorsManager.mainBlue,
              ),
              Gap(4.w),
              Expanded(
                child: Text(
                  widget.listing.location,
                  style: TextStyles.font14BlueRegular,
                ),
              ),
            ],
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar<Event>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDate, selectedDay)) {
                setState(() {
                  _selectedDate = selectedDay;
                });
                _loadAvailableTimeSlots();
              }
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: ColorsManager.mainBlue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ColorsManager.mainBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyles.font14DarkBlueMedium,
              defaultTextStyle: TextStyles.font14DarkBlueMedium,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyles.font16DarkBlueBold,
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: ColorsManager.mainBlue,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: ColorsManager.mainBlue,
              ),
            ),
            enabledDayPredicate: (day) {
              // Only enable days that are in the listing's available days
              final dayName = _getDayName(day.weekday);
              return widget.listing.availableDays.contains(dayName);
            },
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
          'Select Time Slot',
          style: TextStyles.font16DarkBlueBold,
        ),
        Gap(12.h),
        if (_isLoadingSlots)
          const Center(child: CustomProgressIndicator())
        else if (_availableTimeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time_filled,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                Gap(12.h),
                Text(
                  'No available time slots',
                  style: TextStyles.font16DarkBlueBold,
                ),
                Gap(4.h),
                Text(
                  'Please select a different date',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          )
        else
          TimeSlotGrid(
            timeSlots: _availableTimeSlots,
            selectedTimeSlot: _selectedTimeSlot,
            onTimeSlotSelected: (timeSlot) {
              setState(() {
                _selectedTimeSlot = timeSlot;
              });
            },
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
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Any special requirements or notes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorsManager.mainBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedTimeSlot == null) return const SizedBox.shrink();

    final duration = _calculateDuration(_selectedTimeSlot!);
    final totalAmount = widget.listing.hourlyRate * duration;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          _buildSummaryRow('Date', _formatDate(_selectedDate)),
          _buildSummaryRow('Time', '${_selectedTimeSlot!.start} - ${_selectedTimeSlot!.end}'),
          _buildSummaryRow('Duration', '${duration.toStringAsFixed(1)} hours'),
          _buildSummaryRow('Rate', '\$${widget.listing.hourlyRate.toStringAsFixed(0)}/hour'),
          const Divider(),
          _buildSummaryRow(
            'Total Amount',
            '\$${totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: isTotal
                  ? TextStyles.font16DarkBlueBold
                  : TextStyles.font14DarkBlueMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: isTotal
                  ? TextStyles.font16DarkBlueBold
                  : TextStyles.font14DarkBlueMedium,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook = _selectedTimeSlot != null && !_isBooking;

    return AppTextButton(
      buttonText: _isBooking ? 'Booking...' : 'Confirm Booking',
      textStyle: TextStyles.font16WhiteSemiBold,
      onPressed: canBook ? () => _confirmBooking() : null,
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      await _bookingService.createBooking(
        listingId: widget.listing.id,
        selectedDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        context.showSnackBar('Booking confirmed successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to create booking: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double _calculateDuration(TimeSlot timeSlot) {
    final startParts = timeSlot.start.split(':');
    final endParts = timeSlot.end.split(':');
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return (endMinutes - startMinutes) / 60.0;
  }
}

// Placeholder class for calendar events
class Event {
  final String title;
  Event(this.title);
}
