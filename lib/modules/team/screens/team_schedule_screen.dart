import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../helpers/time_extensions.dart';
import '../models/models.dart';
import '../services/team_service.dart';

/// Screen for managing team schedule and events
class TeamScheduleScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamScheduleScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends State<TeamScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.teamName} Schedule',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        actions: [
          IconButton(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorsManager.mainBlue,
          unselectedLabelColor: ColorsManager.gray,
          indicatorColor: ColorsManager.mainBlue,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'List View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildListViewTab(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        // Calendar
        Container(
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar<TeamScheduleEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyles.font14DarkBlue500Weight,
              defaultTextStyle: TextStyles.font14DarkBlue500Weight,
              selectedTextStyle: TextStyles.font14White600Weight,
              todayTextStyle: TextStyles.font14White600Weight,
              selectedDecoration: BoxDecoration(
                color: ColorsManager.mainBlue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ColorsManager.warning,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: ColorsManager.success,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: ColorsManager.mainBlue,
                borderRadius: BorderRadius.circular(12.r),
              ),
              formatButtonTextStyle: TextStyles.font12White500Weight,
              titleTextStyle: TextStyles.font16DarkBlue600Weight,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        // Selected day events
        Expanded(
          child: _buildSelectedDayEvents(),
        ),
      ],
    );
  }

  Widget _buildListViewTab() {
    return StreamBuilder<List<TeamScheduleEvent>>(
      stream: _teamService.getTeamSchedule(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading schedule',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 64.sp,
                  color: ColorsManager.gray,
                ),
                Gap(16.h),
                Text(
                  'No events scheduled',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Create your first team event',
                  style: TextStyles.font13Grey400Weight,
                  textAlign: TextAlign.center,
                ),
                Gap(16.h),
                ElevatedButton(
                  onPressed: _showCreateEventDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Create Event',
                    style: TextStyles.font14White500Weight,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort events by start time
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) return const SizedBox.shrink();

    return StreamBuilder<List<TeamScheduleEvent>>(
      stream: _teamService.getTeamSchedule(
        widget.teamId,
        startDate: DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
        endDate: DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, 23, 59, 59),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 48.sp,
                  color: ColorsManager.gray,
                ),
                Gap(12.h),
                Text(
                  'No events on ${_formatDate(_selectedDay!)}',
                  style: TextStyles.font16DarkBlue500Weight,
                ),
                Gap(8.h),
                Text(
                  'Tap + to create an event',
                  style: TextStyles.font13Grey400Weight,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(TeamScheduleEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  event.type.icon,
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyles.font16DarkBlue600Weight,
                    ),
                    Text(
                      event.type.displayName,
                      style: TextStyles.font13Grey400Weight,
                    ),
                  ],
                ),
              ),
              if (event.isToday)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyles.font12DarkBlue400Weight.copyWith(
                      color: ColorsManager.success,
                    ),
                  ),
                ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.sp,
                color: ColorsManager.gray,
              ),
              Gap(4.w),
              Text(
                '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                style: TextStyles.font14Grey400Weight,
              ),
              Gap(16.w),
              if (event.location != null) ...[
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: ColorsManager.gray,
                ),
                Gap(4.w),
                Expanded(
                  child: Text(
                    event.location!,
                    style: TextStyles.font14Grey400Weight,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            Gap(8.h),
            Text(
              event.description!,
              style: TextStyles.font14DarkBlue500Weight,
            ),
          ],
          Gap(8.h),
          Row(
            children: [
              Text(
                'Duration: ${event.durationString}',
                style: TextStyles.font12Grey400Weight,
              ),
              const Spacer(),
              if (event.requiredMembers.isNotEmpty)
                Text(
                  '${event.requiredMembers.length} required',
                  style: TextStyles.font12Grey400Weight,
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<TeamScheduleEvent> _getEventsForDay(DateTime day) {
    // This would be populated from the stream data
    // For now, return empty list
    return [];
  }

  Color _getEventTypeColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.practice:
        return ColorsManager.mainBlue;
      case ScheduleEventType.match:
        return ColorsManager.success;
      case ScheduleEventType.tournament:
        return ColorsManager.warning;
      case ScheduleEventType.meeting:
        return ColorsManager.gray;
      case ScheduleEventType.other:
        return ColorsManager.darkBlue;
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateEventDialog(
        teamId: widget.teamId,
        teamService: _teamService,
        onEventCreated: () {
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Dialog for creating new team events
class _CreateEventDialog extends StatefulWidget {
  final String teamId;
  final TeamService teamService;
  final VoidCallback onEventCreated;

  const _CreateEventDialog({
    required this.teamId,
    required this.teamService,
    required this.onEventCreated,
  });

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  ScheduleEventType _selectedType = ScheduleEventType.practice;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Event'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter event title';
                    }
                    return null;
                  },
                ),
                Gap(16.h),
                // Event Type
                DropdownButtonFormField<ScheduleEventType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ScheduleEventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                Gap(16.h),
                // Date Selection
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
                Gap(8.h),
                // Time Selection
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(_startTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectStartTime,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(_endTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),
                Gap(16.h),
                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Gap(16.h),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                Gap(16.h),
                // Recurring
                CheckboxListTile(
                  title: const Text('Recurring Event'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final event = TeamScheduleEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teamId: widget.teamId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        type: _selectedType,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        isRecurring: _isRecurring,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.teamService.createScheduleEvent(event);

      if (mounted) {
        Navigator.pop(context);
        widget.onEventCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
