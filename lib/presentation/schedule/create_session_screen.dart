import 'package:flutter/material.dart';

import '../../models/listing_model.dart';
import '../../services/session_service.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final SessionService _sessionService = SessionService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _participantController = TextEditingController();

  final List<String> _participants = [];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  SportType _selectedSport = SportType.other;
  int _durationMinutes = 60;
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepCancel:
              _currentStep == 0 ? null : () => setState(() => _currentStep--),
          onStepContinue: _onStepContinue,
          steps: [
            Step(
              title: const Text('Details'),
              isActive: _currentStep >= 0,
              state: _stepState(0),
              content: _buildDetailsStep(context),
            ),
            Step(
              title: const Text('Participants'),
              isActive: _currentStep >= 1,
              state: _stepState(1),
              content: _buildParticipantsStep(),
            ),
            Step(
              title: const Text('Review'),
              isActive: _currentStep >= 2,
              state: _stepState(2),
              content: _buildReviewStep(),
            ),
          ],
        ),
      ),
    );
  }

  StepState _stepState(int step) {
    if (_currentStep > step) return StepState.complete;
    if (_currentStep == step) return StepState.editing;
    return StepState.indexed;
  }

  Widget _buildDetailsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date'),
          subtitle: Text(
            _selectedDate != null
                ? MaterialLocalizations.of(context)
                    .formatFullDate(_selectedDate!)
                : 'Select a date',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDate,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start time'),
          subtitle: Text(
            _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Select a start time',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: _pickTime,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SportType>(
          value: _selectedSport,
          decoration: const InputDecoration(
            labelText: 'Sport',
            border: OutlineInputBorder(),
          ),
          items: SportType.values
              .map(
                (sport) => DropdownMenuItem(
                  value: sport,
                  child: Text(sport.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedSport = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _durationMinutes,
          decoration: const InputDecoration(
            labelText: 'Duration',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 30, child: Text('30 minutes')),
            DropdownMenuItem(value: 45, child: Text('45 minutes')),
            DropdownMenuItem(value: 60, child: Text('1 hour')),
            DropdownMenuItem(value: 90, child: Text('1 hour 30 minutes')),
            DropdownMenuItem(value: 120, child: Text('2 hours')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _durationMinutes = value);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            hintText: 'Focus areas, skill level, or preparation notes',
          ),
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Provide a description'
              : null,
        ),
      ],
    );
  }

  Widget _buildParticipantsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _participantController,
          decoration: InputDecoration(
            labelText: 'Participant email or ID',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _addParticipant,
              icon: const Icon(Icons.add),
            ),
          ),
          onFieldSubmitted: (_) => _addParticipant(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _participants
              .map(
                (participant) => Chip(
                  label: Text(participant),
                  onDeleted: () =>
                      setState(() => _participants.remove(participant)),
                ),
              )
              .toList(),
        ),
        if (_participants.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Add at least one participant using their email or user ID.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final dateText = _selectedDate != null
        ? MaterialLocalizations.of(context).formatFullDate(_selectedDate!)
        : 'Not set';
    final timeText =
        _selectedTime != null ? _selectedTime!.format(context) : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'Date', value: dateText),
        _ReviewRow(label: 'Time', value: timeText),
        _ReviewRow(
            label: 'Duration',
            value: '${_durationMinutes ~/ 60}h ${_durationMinutes % 60}m'),
        _ReviewRow(label: 'Sport', value: _selectedSport.displayName),
        const SizedBox(height: 8),
        const Text(
          'Participants',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        if (_participants.isEmpty) const Text('No participants added'),
        if (_participants.isNotEmpty)
          ..._participants.map(
            (participant) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(participant),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(_descriptionController.text),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 12),
        _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Create session'),
              ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addParticipant() {
    final value = _participantController.text.trim();
    if (value.isEmpty) return;
    if (_participants.contains(value)) {
      _participantController.clear();
      return;
    }
    setState(() {
      _participants.add(value);
      _participantController.clear();
    });
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedDate == null || _selectedTime == null) {
        setState(() {
          _error = 'Select both date and time to continue.';
        });
        return;
      }
      if (!_formKey.currentState!.validate()) return;
    }
    if (_currentStep == 1) {
      if (_participants.isEmpty) {
        setState(() {
          _error = 'Add at least one participant to continue.';
        });
        return;
      }
      setState(() => _error = null);
    }
    if (_currentStep == 2) return;
    setState(() {
      _currentStep++;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _error = 'Select date and time.';
      });
      return;
    }

    if (_participants.isEmpty) {
      setState(() {
        _error = 'Add at least one participant.';
      });
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      await _sessionService.createSession(
        date: _selectedDate!,
        time: _selectedTime!,
        sport: _selectedSport,
        participantIdentifiers: _participants,
        description: _descriptionController.text.trim(),
        durationMinutes: _durationMinutes,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
