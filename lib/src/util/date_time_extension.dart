import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// `DateTime` convenience helpers shared by the date-backed widgets:
/// calendar-field arithmetic and the display formats used by the date picker.
extension UtopiaDateTimeExtension on DateTime {
  /// Shifts this date by the given calendar fields (each defaulting to 0).
  DateTime addTime({int? year, int? month, int? day}) {
    return copyWith(year: this.year + (year ?? 0), month: this.month + (month ?? 0), day: this.day + (day ?? 0));
  }

  /// Returns this date with its hour/minute replaced by [timeOfDay].
  DateTime withTime(TimeOfDay timeOfDay) {
    return copyWith(hour: timeOfDay.hour, minute: timeOfDay.minute);
  }

  /// Formats this date as `dd MMM yyyy HH:mm` (e.g. `02 Jul 2026 14:30`).
  String toDisplayString() {
    final dateFormat = DateFormat("dd MMM yyyy HH:mm", 'en_US');
    return dateFormat.format(this);
  }

  /// Formats this date as `dd MMM yyyy` (e.g. `02 Jul 2026`), dropping the time.
  String toDisplayStringWithoutHours() {
    final dateFormat = DateFormat("dd MMM yyyy", 'en_US');
    return dateFormat.format(this);
  }

  /// Subtracts [time]'s hour/minute from this date as a duration.
  DateTime subtractTimeOfDay(TimeOfDay time) => subtract(Duration(hours: time.hour, minutes: time.minute));
}
