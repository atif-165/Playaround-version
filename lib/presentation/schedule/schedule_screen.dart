import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/booking_model.dart';
import '../../models/session_model.dart';
import '../../models/user_profile.dart';
import '../../repositories/user_repository.dart';
import '../../services/session_service.dart';
import '../../services/notification_service.dart';
import '../../modules/booking/services/booking_service.dart';
import '../../theming/colors.dart';
import 'create_session_screen.dart';
import 'models/schedule_event.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final BookingService _bookingService = BookingService();
  final SessionService _sessionService = SessionService();
  final NotificationService _notificationService = NotificationService();
  final UserRepository _userRepository = UserRepository();

  StreamSubscription<List<BookingModel>>? _bookingsAsUserSub;
  StreamSubscription<List<BookingModel>>? _bookingsAsOwnerSub;
  StreamSubscription<List<SessionModel>>? _coachSessionsSub;
  StreamSubscription<List<SessionModel>>? _participantSessionsSub;

  List<BookingModel> _bookingsAsUser = [];
  List<BookingModel> _bookingsAsOwner = [];
  List<SessionModel> _coachSessions = [];
  List<SessionModel> _participantSessions = [];

  final Map<DateTime, List<ScheduleEvent>> _eventsByDay = {};
  List<ScheduleEvent> _allEvents = [];

  User? _currentUser;
  UserRole? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _bookingsAsUserSub?.cancel();
    _bookingsAsOwnerSub?.cancel();
    _coachSessionsSub?.cancel();
    _participantSessionsSub?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to view your schedule.';
        });
        return;
      }

      final profile = await _userRepository.getUserProfile(user.uid);

      setState(() {
        _currentUser = user;
        _userRole = profile?.role ?? UserRole.player;
      });

      await _notificationService.startRealtimeListener();
      _subscribeToStreams(user.uid);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load schedule: $e';
      });
    }
  }

  void _subscribeToStreams(String userId) {
    _bookingsAsUserSub =
        _bookingService.getBookingsByUser(userId).listen((bookings) {
      _bookingsAsUser = bookings;
      _rebuildEvents();
    });

    _bookingsAsOwnerSub =
        _bookingService.getBookingsForOwner(userId).listen((bookings) {
      _bookingsAsOwner = bookings;
      _rebuildEvents();
    });

    _coachSessionsSub =
        _sessionService.watchCoachSessions(userId).listen((sessions) {
      _coachSessions = sessions;
      _rebuildEvents();
    });

    _participantSessionsSub =
        _sessionService.watchParticipantSessions(userId).listen((sessions) {
      _participantSessions = sessions;
      _rebuildEvents();
    });
  }

  void _rebuildEvents() {
    if (!mounted) return;
    final userId = _currentUser?.uid;
    if (userId == null) return;

    final Map<String, ScheduleEvent> eventMap = {};
    final now = DateTime.now();

    List<BookingModel> bookings = [
      ..._bookingsAsUser,
      ..._bookingsAsOwner,
    ];

    for (final booking in bookings) {
      final start = ScheduleEvent.combineDateAndSlot(
          booking.selectedDate, booking.timeSlot);
      if (start.isBefore(now.subtract(const Duration(hours: 1)))) continue;

      final isOwnerView = booking.ownerId == userId;
      final key = 'booking_${booking.id}';
      eventMap[key] = ScheduleEvent.fromBooking(
        booking: booking,
        isOwnerView: isOwnerView,
      );
    }

    final sessions = <SessionModel>[
      ..._coachSessions,
      ..._participantSessions,
    ];

    for (final session in sessions) {
      if (session.endTime.isBefore(now)) continue;

      final isCoachView = session.coachId == userId;
      final key = 'session_${session.id}';
      eventMap[key] = ScheduleEvent.fromSession(
        session: session,
        isCoachView: isCoachView,
        currentUserId: userId,
      );
    }

    final events = eventMap.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final Map<DateTime, List<ScheduleEvent>> grouped = {};
    for (final event in events) {
      final dayKey = DateUtils.dateOnly(event.startTime);
      grouped.putIfAbsent(dayKey, () => []).add(event);
    }

    setState(() {
      _allEvents = events;
      _eventsByDay
        ..clear()
        ..addAll(grouped);
      _isLoading = false;
      _errorMessage = null;
    });
  }

  List<ScheduleEvent> _eventsForDay(DateTime day) {
    return _eventsByDay[DateUtils.dateOnly(day)] ?? [];
  }

  Future<void> _navigateToCreateSession() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session created successfully')),
      );
    }
  }

  Future<void> _cancelSession(ScheduleEvent event) async {
    final sessionId = event.metadata['sessionId'] as String?;
    if (sessionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel session'),
        content: const Text('Are you sure you want to cancel this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _sessionService.cancelSession(sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay = _eventsForDay(_selectedDay);
    final isCoach = _userRole == UserRole.coach;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _rebuildEvents();
            },
          ),
        ],
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateSession,
              icon: const Icon(Icons.add),
              label: const Text('Create Session'),
            )
          : null,
      body: _buildBody(eventsForSelectedDay),
    );
  }

  Widget _buildBody(List<ScheduleEvent> eventsForSelectedDay) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildCalendar(),
        Expanded(
          child: eventsForSelectedDay.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventsForSelectedDay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = eventsForSelectedDay[index];
                    return _ScheduleEventCard(
                      event: event,
                      onCancelSession: event.canCancelSession
                          ? () => _cancelSession(event)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<ScheduleEvent>(
      focusedDay: _focusedDay,
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      eventLoader: _eventsForDay,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: ColorsManager.mainBlue.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: ColorsManager.mainBlue,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: ColorsManager.secondary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No events scheduled for this day.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bookings, coaching sessions, and tournaments will appear here automatically.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEventCard extends StatelessWidget {
  const _ScheduleEventCard({
    required this.event,
    this.onCancelSession,
  });

  final ScheduleEvent event;
  final VoidCallback? onCancelSession;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: event.color.withValues(alpha: 0.15),
                  child: Icon(event.icon, color: event.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      event.timeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(event.statusLabel),
                      backgroundColor: event.color.withValues(alpha: 0.12),
                      labelStyle: TextStyle(color: event.color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (onCancelSession != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancelSession,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel session'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
