import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/presentation/models/watchlist_date_picker_options.dart';

void main() {
  test('builds picker columns from descending available dates', () {
    final options = WatchlistDatePickerOptions.fromDates([
      DateTime(2024, 2, 15, 9),
      DateTime(2024, 2, 14, 15),
      DateTime(2024, 1, 30),
      DateTime(2023, 12, 29),
    ]);

    expect(options.years, [2024, 2023]);
    expect(options.monthsForYear(2024), [2, 1]);
    expect(options.daysForMonth(year: 2024, month: 2), [15, 14]);
  });

  test('coerces a missing day to the latest available value in the month', () {
    final options = WatchlistDatePickerOptions.fromDates([
      DateTime(2024, 2, 15),
      DateTime(2024, 2, 14),
      DateTime(2024, 1, 30),
    ]);

    final resolved = options.coerce(DateTime(2024, 2, 10));

    expect(resolved, DateTime(2024, 2, 15));
  });
}
