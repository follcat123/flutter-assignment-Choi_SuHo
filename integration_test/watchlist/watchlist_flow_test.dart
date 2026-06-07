import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/app_test_harness.dart';
import '../../test/support/watchlist_test_repositories.dart';

void main() {
  ensureConfiguredIntegrationBinding();

  testWidgets('applies a new date and refreshes the selected detail', (
    tester,
  ) async {
    final repository = DateAwareWatchlistRepository();

    await pumpSampleApp(tester, repository: repository);
    await settleDesktopIntegration(
      tester,
      duration: const Duration(seconds: 1),
    );

    await tester.tap(find.byKey(const Key('watchlist-row-samsung')));
    await settleDesktopIntegration(tester);

    await tester.tap(find.byKey(const Key('watchlist-date-trigger')));
    await settleDesktopIntegration(tester);
    await tester.tap(find.byKey(const Key('watchlist-date-item-day-14')));
    await settleDesktopIntegration(tester);
    await tester.tap(find.byKey(const Key('watchlist-date-confirm')));
    await settleDesktopIntegration(
      tester,
      duration: const Duration(milliseconds: 450),
    );

    expect(find.text('2024.02.14'), findsOneWidget);
    expect(find.byKey(const Key('watchlist-detail-samsung')), findsOneWidget);
    expect(find.text('3,901,200 (41.33%)'), findsOneWidget);
  });

  testWidgets('shows detail error and retries successfully', (tester) async {
    final repository = DetailRetryRepository();

    await pumpSampleApp(tester, repository: repository);
    await settleDesktopIntegration(
      tester,
      duration: const Duration(seconds: 1),
    );

    await tester.tap(find.byKey(const Key('watchlist-row-samsung')));
    await settleDesktopIntegration(
      tester,
      duration: const Duration(milliseconds: 450),
    );

    expect(
      find.byKey(const Key('watchlist-detail-error-samsung')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('watchlist-detail-retry-samsung')));
    await tester.pump();
    await settleDesktopIntegration(
      tester,
      duration: const Duration(milliseconds: 450),
    );

    expect(find.byKey(const Key('watchlist-detail-samsung')), findsOneWidget);
  });
}
