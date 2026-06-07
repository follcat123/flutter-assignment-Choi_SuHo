import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/app.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import '../../../../support/repositories/mock_watchlist_repository.dart';

void main() {
  Future<void> pumpWatchlist(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(360, 915)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(
            MockWatchlistRepository(
              latency: Duration.zero,
              detailLatency: Duration.zero,
            ),
          ),
        ],
        child: const SampleApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSelectedWatchlist(WidgetTester tester) async {
    await pumpWatchlist(tester);
    await tester.tap(find.byKey(const Key('watchlist-row-samsung')));
    await tester.pumpAndSettle();
  }

  testWidgets('matches the selected watchlist screen at 360 width', (
    tester,
  ) async {
    await pumpSelectedWatchlist(tester);

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('watchlist_screen_selected.png'),
    );
  });

  testWidgets('matches the sort bottom sheet at 360 width', (tester) async {
    await pumpWatchlist(tester);

    await tester.tap(find.byKey(const Key('watchlist-sort-trigger')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('watchlist_sort_sheet.png'),
    );
  });

  testWidgets('matches the date bottom sheet at 360 width', (tester) async {
    await pumpWatchlist(tester);

    await tester.tap(find.byKey(const Key('watchlist-date-trigger')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('watchlist_date_sheet.png'),
    );
  });
}
