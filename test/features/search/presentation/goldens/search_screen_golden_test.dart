import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/app.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import '../../../../support/repositories/mock_watchlist_repository.dart';

void main() {
  Future<void> pumpSearch(WidgetTester tester) async {
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
    await tester.tap(find.byKey(const Key('bottom-nav-search')));
    await tester.pumpAndSettle();
  }

  testWidgets('matches the search results screen at 360 width', (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-result-sk')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('search_results_selected.png'),
    );
  });

  testWidgets('matches the empty search screen at 360 width', (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byKey(const Key('search-input')), 'zzzz');
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('search_results_empty.png'),
    );
  });

  testWidgets('matches the favorite toast state at 360 width', (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-heart-sk')));
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('search_results_toast.png'),
    );
  });
}
