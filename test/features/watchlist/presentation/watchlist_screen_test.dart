import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_test_harness.dart';
import '../../../support/repositories/mock_watchlist_repository.dart';

void main() {
  Future<void> pumpWatchlist(WidgetTester tester) {
    return pumpSampleApp(
      tester,
      repository: MockWatchlistRepository(
        latency: Duration.zero,
        detailLatency: Duration.zero,
      ),
    );
  }

  testWidgets('smoke: renders the watchlist screen', (tester) async {
    await pumpWatchlist(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist-screen')), findsOneWidget);
    expect(find.byKey(const Key('watchlist-header-title')), findsOneWidget);
    expect(find.text('2024.02.15'), findsOneWidget);
    expect(find.byKey(const Key('watchlist-detail-samsung')), findsNothing);
  });

  testWidgets('smoke: opens the date sheet and cancels safely', (tester) async {
    await pumpWatchlist(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('watchlist-date-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist-date-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('watchlist-date-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('2024.02.15'), findsOneWidget);
  });

  testWidgets(
    'assignment: applies the selected date and refreshes list and detail together',
    (tester) async {
      await pumpWatchlist(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('watchlist-row-samsung')));
      await tester.pumpAndSettle();

      expect(find.text('4,705,556 (48.71%)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('watchlist-date-trigger')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('watchlist-date-item-day-14')),
        findsOneWidget,
        reason: 'TODO(assignment): 날짜 시트에서 선택 가능한 날짜 item을 구성하세요.',
      );
      await tester.tap(find.byKey(const Key('watchlist-date-item-day-14')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist-date-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('2024.02.14'),
        findsOneWidget,
        reason:
            'TODO(assignment): watchlist_screen.dart 에서 날짜를 적용한 뒤 '
            '상단 날짜 라벨을 새 거래일로 갱신하세요.',
      );
      expect(
        find.text(r'$170.24'),
        findsOneWidget,
        reason:
            'TODO(assignment): 날짜 변경 후 목록 currentPrice가 함께 '
            '갱신되어야 합니다.',
      );
      expect(
        find.text('3,901,200 (41.33%)'),
        findsOneWidget,
        reason:
            'TODO(assignment): 날짜 변경 후 선택된 상세 패널도 같은 날짜 기준으로 '
            '다시 불러와야 합니다.',
      );
    },
  );
}
