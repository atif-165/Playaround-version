import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Custom JSON converter for DateTime that handles both Firestore Timestamp and String
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }

  @override
  Object? toJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.toIso8601String();
  }
}

/// Custom JSON converter for non-nullable DateTime
class NonNullableTimestampConverter implements JsonConverter<DateTime, Object> {
  const NonNullableTimestampConverter();

  @override
  DateTime fromJson(Object value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    throw ArgumentError('Cannot convert $value to DateTime');
  }

  @override
  Object toJson(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
