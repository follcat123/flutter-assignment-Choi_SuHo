import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/theme/app_assets.dart';

import '../../../support/app_test_harness.dart';
import '../../../support/repositories/mock_watchlist_repository.dart';

void main() {
  testWidgets('smoke: switches between watchlist and search tabs', (
    tester,
  ) async {
    await pumpSampleApp(
      tester,
      repository: MockWatchlistRepository(
        latency: Duration.zero,
        detailLatency: Duration.zero,
      ),
      size: const Size(360, 915),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom-nav-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom-nav-watchlist')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('watchlist-screen')), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const Key('app-bottom-nav-body'))).height,
      56,
    );

    final watchlistIcon = tester.widget<AppSvgIcon>(
      find.descendant(
        of: find.byKey(const Key('bottom-nav-watchlist')),
        matching: find.byType(AppSvgIcon),
      ),
    );
    expect(watchlistIcon.assetPath, AppAssets.navWatchlist);
  });
}
