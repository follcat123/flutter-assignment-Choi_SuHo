import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:sample/features/watchlist/domain/services/watchlist_sorting.dart';
import 'package:sample/features/watchlist/presentation/providers/watchlist_detail_controller.dart';
import 'package:sample/features/watchlist/presentation/providers/watchlist_controller.dart';

void main() {
  test(
    'reuses cached detail and refetches after invalidation and date change',
    () async {
      final repository = CountingWatchlistRepository();
      final container = ProviderContainer(
        overrides: [watchlistRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        watchlistDetailControllerProvider.notifier,
      );
      final item = repository.snapshot.items.first;

      await notifier.toggleSelection(item);
      expect(repository.detailCalls, 1);

      await notifier.toggleSelection(item);
      expect(
        container.read(watchlistDetailControllerProvider).selectedItemId,
        isNull,
      );

      await notifier.toggleSelection(item);
      expect(repository.detailCalls, 1);

      await notifier.invalidateCacheAndReselect(repository.snapshot.items);
      expect(repository.detailCalls, 2);

      container.read(watchlistSelectedDateProvider.notifier).state = DateTime(
        2024,
        2,
        14,
      );
      await notifier.invalidateCacheAndReselect(repository.snapshot.items);
      expect(repository.detailCalls, 3);
      expect(
        container.read(watchlistDetailControllerProvider).dateKey,
        formatApiDate(DateTime(2024, 2, 14)),
      );
    },
  );
}

class CountingWatchlistRepository implements WatchlistRepository {
  final snapshot = WatchlistSnapshot(
    asOf: DateTime(2024, 2, 15),
    availableDates: [DateTime(2024, 2, 15), DateTime(2024, 2, 14)],
    items: const [
      WatchlistItem(
        id: 'samsung',
        market: MarketType.domestic,
        symbol: '005930',
        name: '삼성전자',
        currency: 'KRW',
        currentPrice: 68400,
        changeRate: -0.20,
        tradeVolume: 8210456,
        marketCap: 408000000000,
      ),
    ],
  );

  int detailCalls = 0;

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async => snapshot;

  @override
  Future<List<DateTime>> fetchAvailableDates() async => snapshot.availableDates;

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async =>
      const <StockSearchItem>[];

  @override
  Future<Set<String>> loadFavoriteIds() async =>
      snapshot.items.map((item) => item.id).toSet();

  @override
  Future<void> addFavorite({required String itemId}) async {}

  @override
  Future<void> removeFavorite({required String itemId}) async {}

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    detailCalls++;

    return WatchlistDetail(
      itemId: 'samsung',
      symbol: symbol,
      market: market,
      currency: 'KRW',
      currentPrice: 72100,
      changeAmount: -800,
      changeRate: -1.10,
      tradeVolume: 4705556,
      volumeRatio: 48.71,
      openPrice: 72200,
      openChangeRate: -0.82,
      highPrice: 72400,
      highChangeRate: -0.55,
      lowPrice: 71900,
      lowChangeRate: -1.24,
      candles: [
        CandlePoint(
          time: DateTime(2024, 2, 15, 9),
          open: 72140,
          high: 72180,
          low: 72090,
          close: 72110,
          direction: PriceChangeDirection.down,
        ),
      ],
    );
  }
}
