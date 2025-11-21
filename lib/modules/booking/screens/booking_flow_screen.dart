import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../data/models/booking_model.dart' as data;
import '../../../data/models/listing_model.dart' as data;
import '../../../data/repositories/booking_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../providers/booking_draft.dart';
import '../providers/booking_draft_provider.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    super.key,
    required this.listing,
    this.repository,
    this.firebaseAuth,
  });

  final data.ListingModel listing;
  final BookingRepository? repository;
  final FirebaseAuth? firebaseAuth;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late final BookingDraft _draft;
  late final BookingRepository _bookingRepository;
  late final PageController _pageController;
  FirebaseAuth? _auth;

  final Map<DateTime, List<_Slot>> _slotsByDate = {};
  final List<_ExtraOption> _extraOptions = [];

  int _currentStep = 0;
  bool _processingPayment = false;
  data.BookingModel? _completedBooking;

  @override
  void initState() {
    super.initState();
    _bookingRepository = widget.repository ?? BookingRepository();
    try {
      _auth = widget.firebaseAuth ?? FirebaseAuth.instance;
    } catch (_) {
      _auth = widget.firebaseAuth;
    }
    _draft = BookingDraft(listing: widget.listing);
    _pageController = PageController();
    _prepareAvailability();
    _prepareExtras();
    _bookingRepository.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _prepareAvailability() {
    widget.listing.availability.forEach((dateKey, slots) {
      if (slots is List && slots.isNotEmpty) {
        final date = DateTime.parse(dateKey);
        final normalized = DateTime(date.year, date.month, date.day);
        _slotsByDate[normalized] =
            slots.map((slot) => _Slot.fromString(slot as String)).toList();
      }
    });
  }

  void _prepareExtras() {
    void collect(String prefix, dynamic value) {
      if (value is Map<String, dynamic>) {
        value.forEach((key, nestedValue) {
          final id = prefix.isEmpty ? key : '$prefix • $key';
          collect(id, nestedValue);
        });
      } else if (value is num) {
        _extraOptions.add(
          _ExtraOption(
            id: prefix,
            label: prefix,
            price: value.toDouble(),
          ),
        );
      }
    }

    collect('', widget.listing.extras);
  }

  Future<void> _submitBooking() async {
    if (!_draft.isSlotSelected) return;
    final user = _auth?.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to complete booking')),
      );
      return;
    }

    setState(() {
      _processingPayment = true;
    });

    final priceComponents = <data.PriceComponent>[
      data.PriceComponent(label: 'Base rate', amount: widget.listing.basePrice),
      ..._draft.selectedExtras.entries
          .map(
            (entry) => data.PriceComponent(
              label: entry.key,
              amount: entry.value,
            ),
          )
          .toList(),
    ];

    try {
      final booking = await _bookingRepository.createBooking(
        userId: user.uid,
        providerId: widget.listing.providerId,
        listingId: widget.listing.id,
        sport: widget.listing.sport,
        startTime: _draft.startTime!,
        endTime: _draft.endTime!,
        priceComponents: priceComponents,
        extras: _draft.selectedExtras,
        notes: _draft.notes,
      );

      setState(() {
        _completedBooking = booking;
        _processingPayment = false;
      });
      _draft.markPaymentConfirmed();
      _nextStep();
    } catch (error) {
      setState(() {
        _processingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $error')),
      );
    }
  }

  void _nextStep() {
    if (_currentStep >= 3) return;
    setState(() {
      _currentStep += 1;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BookingDraftProvider(
      draft: _draft,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.listing.title,
            style: TextStyles.font18DarkBlueBold,
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
        ),
        body: Column(
          children: [
            _StepIndicator(currentStep: _currentStep),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SlotSelectionStep(slotsByDate: _slotsByDate),
                  _ExtrasStep(extras: _extraOptions),
                  _PaymentStep(
                    processing: _processingPayment,
                    onConfirm: _submitBooking,
                  ),
                  _ConfirmationStep(booking: _completedBooking),
                ],
              ),
            ),
            _NavigationBar(
              currentStep: _currentStep,
              onBack: _previousStep,
              onNext: () {
                if (_currentStep == 0 && !_draft.isSlotSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a time slot first')),
                  );
                  return;
                }
                if (_currentStep == 1) {
                  _nextStep();
                } else if (_currentStep == 2) {
                  _submitBooking();
                } else if (_currentStep == 3) {
                  Navigator.of(context).pop(_completedBooking);
                } else {
                  _nextStep();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotSelectionStep extends StatelessWidget {
  const _SlotSelectionStep({
    required this.slotsByDate,
  });

  final Map<DateTime, List<_Slot>> slotsByDate;

  @override
  Widget build(BuildContext context) {
    final draft = BookingDraftProvider.of(context);
    final dates = slotsByDate.keys.toList()..sort();

    if (dates.isEmpty) {
      return const Center(
        child: Text('No availability loaded for this listing.'),
      );
    }

    final selectedDate = draft.selectedDate ?? dates.first;
    final slots = slotsByDate[selectedDate] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a date',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: dates.map((date) {
              final isSelected = date == selectedDate;
              return ChoiceChip(
                key: ValueKey('date_${date.toIso8601String()}'),
                label: Text(DateFormat.MMMd().format(date)),
                selected: isSelected,
                onSelected: (_) => draft.setDate(date),
                selectedColor: ColorsManager.mainBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              );
            }).toList(),
          ),
          Gap(24.h),
          Text(
            'Select a time slot',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(12.h),
          if (slots.isEmpty)
            const Text('No slots available for this date')
          else
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: slots.map((slot) {
                final isSelected =
                    draft.startTime == slot.start && draft.endTime == slot.end;
                return ChoiceChip(
                  key: ValueKey(
                    'slot_${slot.start.toIso8601String()}_${slot.end.toIso8601String()}',
                  ),
                  label: Text(slot.label),
                  selected: isSelected,
                  onSelected: (_) => draft.setTimeRange(
                    start: slot.start,
                    end: slot.end,
                  ),
                  selectedColor: ColorsManager.mainBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ExtrasStep extends StatelessWidget {
  const _ExtrasStep({required this.extras});

  final List<_ExtraOption> extras;

  @override
  Widget build(BuildContext context) {
    final draft = BookingDraftProvider.of(context);
    if (extras.isEmpty) {
      return const Center(
        child: Text('No add-ons available for this listing.'),
      );
    }

    return ListView.separated(
      key: const PageStorageKey('extras_list'),
      padding: EdgeInsets.all(16.w),
      itemCount: extras.length,
      separatorBuilder: (_, __) => Gap(8.h),
      itemBuilder: (context, index) {
        final extra = extras[index];
        final selected = draft.hasExtra(extra.id);
        return SwitchListTile(
          key: ValueKey('extra_${extra.id}'),
          value: selected,
          onChanged: (_) => draft.toggleExtra(extra.id, extra.price),
          title: Text(extra.label),
          subtitle: Text('\$${extra.price.toStringAsFixed(2)}'),
          activeColor: ColorsManager.mainBlue,
        );
      },
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.processing,
    required this.onConfirm,
  });

  final bool processing;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final draft = BookingDraftProvider.of(context);
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        key: const Key('payment_scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review and pay', style: TextStyles.font18DarkBlueBold),
            Gap(16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _priceRow('Base rate', draft.listing.basePrice),
                    ...draft.selectedExtras.entries.map(
                      (entry) => _priceRow(entry.key, entry.value),
                    ),
                    const Divider(),
                    _priceRow('Total', draft.total, bold: true),
                  ],
                ),
              ),
            ),
            Gap(16.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              maxLines: 3,
              onChanged: draft.setNotes,
            ),
            Gap(16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('confirm_and_pay_button'),
                onPressed: processing ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: processing
                    ? const CustomProgressIndicator()
                    : const Text('Confirm & Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? TextStyles.font14DarkBlueBold
                : TextStyles.font14Grey400Weight,
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: bold
                ? TextStyles.font14DarkBlueBold
                : TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({required this.booking});

  final data.BookingModel? booking;

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomProgressIndicator(),
              Gap(16.h),
              Text(
                'Processing your booking...',
                style: TextStyles.font16DarkBlueBold,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child:
                Icon(Icons.check_circle, color: Colors.green[600], size: 72.w),
          ),
          Gap(16.h),
          Text(
            'Booking confirmed',
            style: TextStyles.font20DarkBlueBold,
          ),
          Gap(12.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Date', dateFormat.format(booking!.startTime)),
                  _infoRow(
                    'Time',
                    '${timeFormat.format(booking!.startTime)} - ${timeFormat.format(booking!.endTime)}',
                  ),
                  _infoRow('Sport', booking!.sport),
                  _infoRow(
                      'Total paid', '\$${booking!.total.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          Gap(16.h),
          Text(
            'A confirmation has been sent and the provider has been notified. '
            'You can manage this booking from the history screen.',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyles.font14Grey400Weight),
          Text(value, style: TextStyles.font14DarkBlueBold),
        ],
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.currentStep,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            if (currentStep > 0 && currentStep < 3)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
            if (currentStep > 0 && currentStep < 3) Gap(12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  currentStep == 0
                      ? 'Continue'
                      : currentStep == 1
                          ? 'Continue'
                          : currentStep == 2
                              ? 'Confirm & Pay'
                              : 'Done',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;
  static const _labels = ['Slot', 'Extras', 'Payment', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final active = index <= currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: active ? ColorsManager.mainBlue : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Gap(6.h),
                Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: active ? ColorsManager.mainBlue : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Slot {
  _Slot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  String get label =>
      '${DateFormat.Hm().format(start)} - ${DateFormat.Hm().format(end)}';

  static _Slot fromString(String slot) {
    final normalized = slot.trim();
    String startString;
    String endString;

    final isoSeparatorIndex = normalized.indexOf('Z-');
    if (isoSeparatorIndex != -1) {
      startString = normalized.substring(0, isoSeparatorIndex + 1).trim();
      endString = normalized.substring(isoSeparatorIndex + 2).trim();
    } else {
      final separatorIndex = normalized.lastIndexOf(' - ');
      if (separatorIndex != -1) {
        startString = normalized.substring(0, separatorIndex).trim();
        endString = normalized.substring(separatorIndex + 3).trim();
      } else {
        final fallbackIndex = normalized.lastIndexOf('-');
        if (fallbackIndex == -1) {
          throw FormatException('Invalid slot format', slot);
        }
        startString = normalized.substring(0, fallbackIndex).trim();
        endString = normalized.substring(fallbackIndex + 1).trim();
      }
    }

    return _Slot(
      start: DateTime.parse(startString),
      end: DateTime.parse(endString),
    );
  }
}

class _ExtraOption {
  const _ExtraOption({
    required this.id,
    required this.label,
    required this.price,
  });

  final String id;
  final String label;
  final double price;
}
