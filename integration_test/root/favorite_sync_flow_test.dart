import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/theme/app_assets.dart';
import 'package:sample/theme/app_theme.dart';

import '../../test/support/app_test_harness.dart';
import '../../test/support/watchlist_test_repositories.dart';

void main() {
  ensureConfiguredIntegrationBinding();

  testWidgets('syncs favorite state between search and watchlist tabs', (
    tester,
  ) async {
    final repository = SearchFavoriteFlowRepository();

    await pumpSampleApp(tester, repository: repository);
    await settleDesktopIntegration(
      tester,
      duration: const Duration(seconds: 1),
    );

    await tester.tap(find.byKey(const Key('bottom-nav-search')));
    await settleDesktopIntegration(tester);
    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await settleDesktopIntegration(tester);

    final searchHeart = find.byKey(const Key('search-heart-sk'));
    await tester.ensureVisible(searchHeart);
    await tester.tap(searchHeart);
    await tester.pump();
    await settleDesktopIntegration(tester);

    expect(find.byKey(const Key('search-toast')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom-nav-watchlist')));
    await settleDesktopIntegration(tester);

    expect(find.byKey(const Key('watchlist-row-sk')), findsOneWidget);

    final watchlistRow = find.byKey(const Key('watchlist-row-sk'));
    await tester.ensureVisible(watchlistRow);
    await tester.tap(watchlistRow);
    await settleDesktopIntegration(tester);
    final deleteAction = find.byKey(const Key('watchlist-action-삭제-sk'));
    await tester.ensureVisible(deleteAction);
    await tester.tap(deleteAction);
    await tester.pump();
    await settleDesktopIntegration(tester);

    expect(find.byKey(const Key('watchlist-row-sk')), findsNothing);

    await tester.tap(find.byKey(const Key('bottom-nav-search')));
    await settleDesktopIntegration(tester);

    final heartIcon = tester.widget<AppSvgIcon>(searchHeartIconFinder('sk'));
    expect(heartIcon.assetPath, AppAssets.favoriteHeart);
    expect(heartIcon.color, AppColors.darkTheme.c_424242);
  });
}
