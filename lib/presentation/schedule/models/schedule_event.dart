import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../../../models/listing_model.dart';
import '../../../models/session_model.dart';

enum ScheduleEventType { booking, session, tournament }

class ScheduleEvent {
  ScheduleEvent.booking({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.startTime,
    required this.icon,
    required this.color,
    required this.metadata,
    DateTime? endTime,
  })  : type = ScheduleEventType.booking,
        endTime = endTime ?? startTime.add(const Duration(hours: 1));

  ScheduleEvent.session({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.startTime,
    required this.icon,
    required this.color,
    required this.metadata,
    DateTime? endTime,
  })  : type = ScheduleEventType.session,
        endTime = endTime ?? startTime.add(const Duration(hours: 1));

  final String id;
  final ScheduleEventType type;
  final String title;
  final String subtitle;
  final String statusLabel;
  final DateTime startTime;
  final DateTime endTime;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> metadata;

  String get timeLabel => DateFormat('h:mm a').format(startTime);

  String get rangeLabel {
    final formatter = DateFormat('h:mm a');
    return '${formatter.format(startTime)} - ${formatter.format(endTime)}';
  }

  bool get canCancelSession =>
      type == ScheduleEventType.session && metadata['isCoach'] == true;

  static DateTime combineDateAndSlot(DateTime date, TimeSlot slot) {
    final startParts = slot.start.split(':');
    final startHour = int.tryParse(startParts.first) ?? 0;
    final startMinute =
        startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;

    final endParts = slot.end.split(':');
    final endHour = int.tryParse(endParts.first) ?? startHour;
    final endMinute =
        endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : startMinute;

    return DateTime(date.year, date.month, date.day, startHour, startMinute);
  }

  static ScheduleEvent fromBooking({
    required BookingModel booking,
    required bool isOwnerView,
  }) {
    final date = combineDateAndSlot(booking.selectedDate, booking.timeSlot);
    final color = isOwnerView ? Colors.blueAccent : Colors.green;
    final subtitle = isOwnerView
        ? 'Booked by ${booking.userName}'
        : 'Hosted by ${booking.ownerName}';
    return ScheduleEvent.booking(
      id: booking.id,
      title: booking.listingTitle,
      subtitle: '$subtitle • ${booking.location}',
      statusLabel: booking.status.displayName,
      startTime: date,
      endTime: date.add(Duration(
        minutes: ((booking.timeSlot.durationInHours) * 60).toInt(),
      )),
      icon: Icons.event_available,
      color: color,
      metadata: {
        'bookingId': booking.id,
        'isOwner': isOwnerView,
      },
    );
  }

  static ScheduleEvent fromSession({
    required SessionModel session,
    required bool isCoachView,
    required String currentUserId,
  }) {
    final participantNames = session.participants
        .map((participant) => participant.displayName ?? participant.email)
        .where((name) => name.isNotEmpty)
        .toList();
    final subtitle = isCoachView
        ? 'Participants: ${participantNames.join(', ')}'
        : 'Coach: ${session.coachName}';

    return ScheduleEvent.session(
      id: session.id,
      title: '${session.sport.displayName} Session',
      subtitle: subtitle,
      statusLabel: session.status.displayName,
      startTime: session.startTime,
      endTime: session.endTime,
      icon: Icons.fitness_center,
      color: isCoachView ? Colors.orange : Colors.purple,
      metadata: {
        'sessionId': session.id,
        'isCoach': isCoachView,
        'currentUserId': currentUserId,
      },
    );
  }
}
