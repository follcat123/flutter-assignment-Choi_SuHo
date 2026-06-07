import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/app.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:sample/theme/app_assets.dart';

import '../demo/demo_app.dart';
import '../demo/features/demo/data/repositories/demo_watchlist_repository.dart';

Future<void> pumpSampleApp(
  WidgetTester tester, {
  WatchlistRepository? repository,
  Size size = const Size(390, 915),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          watchlistRepositoryProvider.overrideWithValue(repository),
      ],
      child: const SampleApp(),
    ),
  );
}

Future<void> pumpSearchTab(
  WidgetTester tester, {
  WatchlistRepository? repository,
  Size size = const Size(360, 915),
}) async {
  await pumpSampleApp(tester, repository: repository, size: size);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('bottom-nav-search')));
  await tester.pumpAndSettle();
}

Future<void> settleDesktopIntegration(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 350),
  int ticks = 2,
}) async {
  for (var index = 0; index < ticks; index += 1) {
    await tester.pump(duration);
  }
}

Future<void> pumpDemoApp(
  WidgetTester tester, {
  DemoWatchlistRepository? repository,
  Size size = const Size(390, 915),
  double stepDelayFactor = 0,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final demoRepository = repository ?? DemoWatchlistRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
        watchlistRepositoryProvider.overrideWithValue(demoRepository),
        demoWatchlistRepositoryProvider.overrideWithValue(demoRepository),
      ],
      child: DemoApp(stepDelayFactor: stepDelayFactor),
    ),
  );
}

Finder searchHeartIconFinder(String itemId) {
  return find.descendant(
    of: find.byKey(Key('search-heart-$itemId')),
    matching: find.byType(AppSvgIcon),
  );
}

TestWidgetsFlutterBinding ensureConfiguredIntegrationBinding() {
  return TestWidgetsFlutterBinding.ensureInitialized();
}
