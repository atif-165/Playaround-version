import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_text_button.dart';
import '../../../models/venue_booking_model.dart';
import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/venue_service.dart';

/// Screen for rescheduling venue bookings
class VenueRescheduleScreen extends StatefulWidget {
  final VenueBookingModel booking;

  const VenueRescheduleScreen({
    super.key,
    required this.booking,
  });

  @override
  State<VenueRescheduleScreen> createState() => _VenueRescheduleScreenState();
}

class _VenueRescheduleScreenState extends State<VenueRescheduleScreen> {
  final VenueService _venueService = VenueService();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  List<TimeSlot> _availableTimeSlots = [];
  bool _isLoadingTimeSlots = false;
  bool _isRescheduling = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.booking.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reschedule Booking',
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
            _buildCurrentBookingInfo(),
            Gap(24.h),
            _buildDateSelection(),
            Gap(24.h),
            _buildTimeSlotSelection(),
            Gap(24.h),
            _buildNotesSection(),
            Gap(24.h),
            _buildRescheduleSummary(),
            Gap(32.h),
            _buildRescheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBookingInfo() {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Booking',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            Text(
              widget.booking.venueTitle,
              style: TextStyles.font14DarkBlueMedium,
            ),
            Gap(4.h),
            Text(
              '${dateFormat.format(widget.booking.selectedDate)} • ${widget.booking.timeSlot.start} - ${widget.booking.timeSlot.end}',
              style: TextStyles.font12Grey400Weight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select New Date',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(16.h),
            TableCalendar<dynamic>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)))) {
                  return;
                }
                setState(() {
                  _selectedDate = selectedDay;
                  _selectedTimeSlot = null;
                });
                _loadAvailableTimeSlots();
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
                disabledDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyles.font16DarkBlueBold,
              ),
              enabledDayPredicate: (day) {
                return day
                    .isAfter(DateTime.now().subtract(const Duration(days: 1)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select New Time Slot',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(16.h),
            if (_selectedDate == null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Please select a date first',
                  style: TextStyles.font14Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              )
            else if (_isLoadingTimeSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableTimeSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'No available time slots for this date',
                  style: TextStyles.font14DarkBlueMedium
                      .copyWith(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                ),
                itemCount: _availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = _availableTimeSlots[index];
                  final isSelected = _selectedTimeSlot == timeSlot;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = timeSlot;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? ColorsManager.mainBlue : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? ColorsManager.mainBlue
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          '${timeSlot.start} - ${timeSlot.end}',
                          style: isSelected
                              ? TextStyles.font12WhiteMedium
                              : TextStyles.font14DarkBlueMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (Optional)',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any special requests or notes...',
                hintStyle: TextStyles.font14Grey400Weight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: ColorsManager.mainBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescheduleSummary() {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Booking Summary',
              style: TextStyles.font16DarkBlueBold,
            ),
            Gap(12.h),
            _buildSummaryRow('Date', dateFormat.format(_selectedDate!)),
            Gap(8.h),
            _buildSummaryRow('Time',
                '${_selectedTimeSlot!.start} - ${_selectedTimeSlot!.end}'),
            Gap(8.h),
            _buildSummaryRow('Duration',
                '${_selectedTimeSlot!.durationInHours.toStringAsFixed(1)} hours'),
            Gap(8.h),
            _buildSummaryRow(
                'Amount', '\$${widget.booking.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.font14Grey400Weight,
        ),
        Text(
          value,
          style: TextStyles.font14DarkBlueMedium,
        ),
      ],
    );
  }

  Widget _buildRescheduleButton() {
    final canReschedule = _selectedDate != null && _selectedTimeSlot != null;

    return AppTextButton(
      buttonText: _isRescheduling ? 'Rescheduling...' : 'Reschedule Booking',
      textStyle: TextStyles.font16WhiteSemiBold,
      backgroundColor: canReschedule ? ColorsManager.mainBlue : Colors.grey,
      onPressed: canReschedule && !_isRescheduling ? _rescheduleBooking : null,
    );
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingTimeSlots = true;
      _availableTimeSlots = [];
    });

    try {
      final timeSlots = await _venueService.getAvailableTimeSlots(
        venueId: widget.booking.venueId,
        date: _selectedDate!,
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
            content: Text('Failed to load available time slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    setState(() {
      _isRescheduling = true;
    });

    try {
      await _venueService.rescheduleVenueBooking(
        bookingId: widget.booking.id,
        newDate: _selectedDate!,
        newTimeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rescheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }
}
