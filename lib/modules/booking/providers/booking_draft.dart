import 'package:flutter/foundation.dart';

import '../../../data/models/listing_model.dart';

class BookingDraft extends ChangeNotifier {
  BookingDraft({required this.listing});

  final ListingModel listing;

  DateTime? selectedDate;
  DateTime? startTime;
  DateTime? endTime;
  final Map<String, double> _selectedExtras = {};
  String? notes;
  bool paymentConfirmed = false;

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTimeRange({
    required DateTime start,
    required DateTime end,
  }) {
    startTime = start;
    endTime = end;
    notifyListeners();
  }

  void toggleExtra(String id, double price) {
    if (_selectedExtras.containsKey(id)) {
      _selectedExtras.remove(id);
    } else {
      _selectedExtras[id] = price;
    }
    notifyListeners();
  }

  bool hasExtra(String id) => _selectedExtras.containsKey(id);

  Map<String, double> get selectedExtras => Map.unmodifiable(_selectedExtras);

  double get extrasTotal =>
      _selectedExtras.values.fold(0, (total, price) => total + price);

  double get basePrice => listing.basePrice;

  double get total => basePrice + extrasTotal;

  void setNotes(String? value) {
    notes = value;
    notifyListeners();
  }

  void markPaymentConfirmed() {
    paymentConfirmed = true;
    notifyListeners();
  }

  bool get isSlotSelected => startTime != null && endTime != null;
}
