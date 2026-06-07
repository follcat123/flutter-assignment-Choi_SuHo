import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import 'package:sample/theme/app_theme.dart';

import 'demo_app.dart';
import 'features/demo/data/repositories/demo_watchlist_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg.bg_2_212121,
      systemNavigationBarDividerColor: AppColors.bg.bg_2_212121,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final repository = DemoWatchlistRepository();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(null),
        watchlistRepositoryProvider.overrideWithValue(repository),
        demoWatchlistRepositoryProvider.overrideWithValue(repository),
      ],
      child: const DemoApp(),
    ),
  );
}
