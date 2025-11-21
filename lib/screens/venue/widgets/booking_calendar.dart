import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class BookingCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const BookingCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
  }

  @override
  void didUpdateWidget(BookingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _selectedDay = widget.selectedDate;
      _focusedDay = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ColorsManager.primary;
    final surface = const Color(0xFF14122E);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1A3A),
            Color(0xFF090817),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDateSelected(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        daysOfWeekVisible: true,
        rowHeight: 46,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyles.font16White600Weight,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: accent,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: accent,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          weekendStyle: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
          disabledTextStyle: TextStyle(
            color: Colors.white.withOpacity(0.25),
          ),
          selectedDecoration: BoxDecoration(
            gradient: ColorsManager.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          todayDecoration: BoxDecoration(
            border: Border.all(color: accent.withOpacity(0.6), width: 2),
            color: accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          defaultDecoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
          ),
          weekendDecoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
          ),
          cellMargin: const EdgeInsets.all(6),
          cellPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
