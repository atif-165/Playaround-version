import 'package:flutter/widgets.dart';

import 'booking_draft.dart';

class BookingDraftProvider extends InheritedNotifier<BookingDraft> {
  const BookingDraftProvider({
    super.key,
    required BookingDraft draft,
    required Widget child,
  }) : super(notifier: draft, child: child);

  static BookingDraft of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<BookingDraftProvider>();
    assert(provider != null, 'BookingDraftProvider not found in context');
    return provider!.notifier!;
  }
}
