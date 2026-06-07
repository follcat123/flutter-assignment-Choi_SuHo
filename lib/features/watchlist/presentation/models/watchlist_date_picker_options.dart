import 'package:flutter/foundation.dart';

import '../../domain/services/watchlist_sorting.dart';

DateTime normalizeWatchlistDate(DateTime value) {
  return normalizeAsOfDate(value);
}

@immutable
class WatchlistDatePickerOptions {
  const WatchlistDatePickerOptions._(this.availableDates);

  factory WatchlistDatePickerOptions.fromDates(List<DateTime> dates) {
    final normalized = <DateTime>[];
    final seen = <String>{};
    final sorted = dates.map(normalizeWatchlistDate).toList()
      ..sort((left, right) => right.compareTo(left));

    for (final date in sorted) {
      if (seen.add(formatApiDate(date))) {
        normalized.add(date);
      }
    }

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        dates,
        'dates',
        'available dates must not be empty',
      );
    }

    return WatchlistDatePickerOptions._(List.unmodifiable(normalized));
  }

  final List<DateTime> availableDates;

  List<int> get years => _uniqueValues(availableDates.map((date) => date.year));

  List<int> monthsForYear(int year) {
    return _uniqueValues(
      availableDates
          .where((date) => date.year == year)
          .map((date) => date.month),
    );
  }

  List<int> daysForMonth({required int year, required int month}) {
    return _uniqueValues(
      availableDates
          .where((date) => date.year == year && date.month == month)
          .map((date) => date.day),
    );
  }

  DateTime coerce(DateTime candidate) {
    final normalized = normalizeWatchlistDate(candidate);
    final candidateKey = formatApiDate(normalized);
    for (final date in availableDates) {
      if (formatApiDate(date) == candidateKey) {
        return date;
      }
    }

    final years = this.years;
    final year = years.contains(normalized.year)
        ? normalized.year
        : years.first;
    final months = monthsForYear(year);
    final month = months.contains(normalized.month)
        ? normalized.month
        : months.first;
    final days = daysForMonth(year: year, month: month);
    final day = days.contains(normalized.day) ? normalized.day : days.first;

    return DateTime(year, month, day);
  }

  DateTime resolve({required int year, required int month, required int day}) {
    return coerce(DateTime(year, month, day));
  }

  List<int> _uniqueValues(Iterable<int> values) {
    final unique = values.toSet().toList()
      ..sort((left, right) => right.compareTo(left));
    return List.unmodifiable(unique);
  }
}
