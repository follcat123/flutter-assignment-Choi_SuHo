import 'package:flutter_test/flutter_test.dart';
import '../../../support/repositories/mock_watchlist_repository.dart';
import '../../../support/repositories/mock_favorite_ids_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists favorite ids and derives the watchlist from them', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = MockWatchlistRepository(
      latency: Duration.zero,
      detailLatency: Duration.zero,
      sharedPreferences: preferences,
      initialFavoriteIds: const {'sk'},
    );

    expect(await repository.loadFavoriteIds(), {'sk'});
    expect(
      (await repository.fetchWatchlist()).items.map((item) => item.id).toSet(),
      {'sk'},
    );

    await repository.addFavorite(itemId: 'apple');

    final restoredRepository = MockWatchlistRepository(
      latency: Duration.zero,
      detailLatency: Duration.zero,
      sharedPreferences: preferences,
    );

    expect(await restoredRepository.loadFavoriteIds(), {'sk', 'apple'});
    expect(
      (await restoredRepository.fetchWatchlist()).items
          .map((item) => item.id)
          .toSet(),
      {'sk', 'apple'},
    );

    await restoredRepository.removeFavorite(itemId: 'sk');

    final reloadedRepository = MockWatchlistRepository(
      latency: Duration.zero,
      detailLatency: Duration.zero,
      sharedPreferences: preferences,
    );

    expect(await reloadedRepository.loadFavoriteIds(), {'apple'});
    expect(
      (await reloadedRepository.fetchWatchlist()).items
          .map((item) => item.id)
          .toSet(),
      {'apple'},
    );
  });

  test(
    'reflects add and remove operations in search results immediately',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = MockWatchlistRepository(
        latency: Duration.zero,
        detailLatency: Duration.zero,
        sharedPreferences: preferences,
        initialFavoriteIds: const <String>{},
      );

      final initialResults = await repository.searchStocks(query: 'sk');
      expect(
        initialResults.firstWhere((item) => item.id == 'sk-square').isFavorite,
        isFalse,
      );

      await repository.addFavorite(itemId: 'sk-square');
      final addedResults = await repository.searchStocks(query: 'sk');
      expect(
        addedResults.firstWhere((item) => item.id == 'sk-square').isFavorite,
        isTrue,
      );

      await repository.removeFavorite(itemId: 'sk-square');
      final removedResults = await repository.searchStocks(query: 'sk');
      expect(
        removedResults.firstWhere((item) => item.id == 'sk-square').isFavorite,
        isFalse,
      );
    },
  );

  test('restores legacy mock ids from canonical domestic favorites', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      testFavoriteIdsStorageKey: <String>['domestic:005930', 'domestic:035720'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = MockWatchlistRepository(
      latency: Duration.zero,
      detailLatency: Duration.zero,
      sharedPreferences: preferences,
    );

    expect(await repository.loadFavoriteIds(), {'samsung', 'kakao'});
    expect(
      (await repository.fetchWatchlist()).items.map((item) => item.id).toSet(),
      {'samsung', 'kakao'},
    );
  });
}
