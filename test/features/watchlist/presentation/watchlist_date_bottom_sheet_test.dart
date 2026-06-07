import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/presentation/widgets/watchlist_date_bottom_sheet.dart';

void main() {
  final availableDates = <DateTime>[
    DateTime(2024, 2, 15),
    DateTime(2024, 2, 14),
    DateTime(2024, 1, 31),
  ];

  Future<void> pumpSheet(
    WidgetTester tester, {
    WatchlistDateBottomSheetController? controller,
    ValueChanged<DateTime>? onSubmitted,
    VoidCallback? onCancelled,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WatchlistDateBottomSheet(
            availableDates: availableDates,
            initialDate: DateTime(2024, 2, 15),
            controller: controller,
            onSubmitted: onSubmitted,
            onCancelled: onCancelled,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('smoke: renders the sheet shell and action buttons', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('watchlist-date-sheet')), findsOneWidget);
    expect(find.text('날짜 선택'), findsOneWidget);
    expect(find.byKey(const Key('watchlist-date-cancel')), findsOneWidget);
    expect(find.byKey(const Key('watchlist-date-confirm')), findsOneWidget);
  });

  testWidgets(
    'assignment: renders year, month, and day pickers with selectable items',
    (tester) async {
      await pumpSheet(tester);

      expect(
        find.byKey(const Key('watchlist-date-picker-year')),
        findsOneWidget,
        reason: 'TODO(assignment): 연/월/일 picker 구조를 직접 구성하세요.',
      );
      expect(
        find.byKey(const Key('watchlist-date-picker-month')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('watchlist-date-picker-day')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('watchlist-date-item-year-2024')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('watchlist-date-item-month-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('watchlist-date-item-day-14')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'assignment: selecting a day and confirming submits the chosen date',
    (tester) async {
      DateTime? submittedDate;
      await pumpSheet(tester, onSubmitted: (value) => submittedDate = value);

      expect(
        find.byKey(const Key('watchlist-date-item-day-14')),
        findsOneWidget,
        reason: 'TODO(assignment): 선택 가능한 날짜 item을 렌더링하고 key를 유지하세요.',
      );
      await tester.tap(find.byKey(const Key('watchlist-date-item-day-14')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist-date-confirm')));
      await tester.pumpAndSettle();

      expect(
        submittedDate,
        DateTime(2024, 2, 14),
        reason:
            'TODO(assignment): 날짜 선택 UI와 확인 버튼을 연결해서 선택 결과를 '
            '반환하세요.',
      );
    },
  );
}
