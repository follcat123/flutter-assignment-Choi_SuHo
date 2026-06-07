import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/watchlist_repository.dart';
import '../repositories/favorite_ids_local_store.dart';
import '../repositories/naver_watchlist_repository.dart';

final naverDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
    ),
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final favoriteIdsLocalStoreProvider = Provider<FavoriteIdsLocalStore>((ref) {
  return FavoriteIdsLocalStore(ref.watch(sharedPreferencesProvider));
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  if (kIsWeb) {
    throw UnsupportedError(
      'Naver direct watchlist is not supported on Flutter web.',
    );
  }

  return NaverWatchlistRepository(
    dio: ref.watch(naverDioProvider),
    favoriteIdsLocalStore: ref.watch(favoriteIdsLocalStoreProvider),
  );
});
