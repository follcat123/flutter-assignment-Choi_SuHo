import 'repositories/mock_watchlist_repository.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';

class FlakyDetailRepository extends MockWatchlistRepository {
  FlakyDetailRepository()
    : super(latency: Duration.zero, detailLatency: Duration.zero);

  bool _failedOnce = false;

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    if (!_failedOnce && symbol == '005930') {
      _failedOnce = true;
      throw Exception('temporary detail error');
    }

    return super.fetchWatchlistDetail(
      symbol: symbol,
      market: market,
      asOf: asOf,
    );
  }
}

class MissingSelectionOnDateChangeRepository extends MockWatchlistRepository {
  MissingSelectionOnDateChangeRepository()
    : super(
        latency: Duration.zero,
        detailLatency: Duration.zero,
        snapshotsByDate: {
          DateTime(2024, 2, 15): WatchlistSnapshot(
            asOf: DateTime(2024, 2, 15),
            availableDates: [DateTime(2024, 2, 15), DateTime(2024, 2, 14)],
            items: const [
              WatchlistItem(
                id: 'apple',
                market: MarketType.overseas,
                symbol: 'AAPL',
                name: '애플',
                currency: 'USD',
                currentPrice: 172.54,
                changeRate: 0.70,
                tradeVolume: 4517254,
                marketCap: 2890000000000,
              ),
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
          ),
          DateTime(2024, 2, 14): WatchlistSnapshot(
            asOf: DateTime(2024, 2, 14),
            availableDates: [DateTime(2024, 2, 15), DateTime(2024, 2, 14)],
            items: const [
              WatchlistItem(
                id: 'apple',
                market: MarketType.overseas,
                symbol: 'AAPL',
                name: '애플',
                currency: 'USD',
                currentPrice: 170.24,
                changeRate: -0.45,
                tradeVolume: 3921044,
                marketCap: 2890000000000,
              ),
            ],
          ),
        },
        detailOverridesByDate: {
          DateTime(2024, 2, 15): {
            '005930': buildSamsungDetail(
              currentPrice: 72100,
              changeAmount: -800,
              changeRate: -1.10,
              tradeVolume: 4705556,
              volumeRatio: 48.71,
            ),
          },
        },
      );
}

class SequenceWatchlistRepository implements WatchlistRepository {
  final List<WatchlistSnapshot> _snapshots = [
    buildSnapshot(172.54, DateTime(2024, 2, 15)),
    buildSnapshot(180.10, DateTime(2024, 2, 16)),
    buildSnapshot(181.22, DateTime(2024, 2, 17)),
  ];

  final List<WatchlistDetail> _details = [
    buildDetail(tradeVolume: 4705556, volumeRatio: 48.71),
    buildDetail(tradeVolume: 5105000, volumeRatio: 51.10),
    buildDetail(tradeVolume: 6205500, volumeRatio: 61.22),
  ];

  int _snapshotIndex = 0;
  int _detailIndex = 0;

  int get snapshotFetchCount => _snapshotIndex;
  int get detailFetchCount => _detailIndex;

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    final index = _snapshotIndex < _snapshots.length
        ? _snapshotIndex++
        : _snapshots.length - 1;
    return _snapshots[index];
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    return _snapshots.first.availableDates.isEmpty
        ? <DateTime>[_snapshots.first.asOf]
        : _snapshots.first.availableDates;
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async =>
      const <StockSearchItem>[];

  @override
  Future<Set<String>> loadFavoriteIds() async {
    return _snapshots.first.items.map((item) => item.id).toSet();
  }

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
    final index = _detailIndex < _details.length
        ? _detailIndex++
        : _details.length - 1;
    return _details[index];
  }
}

class DateAwareWatchlistRepository implements WatchlistRepository {
  final Map<DateTime, WatchlistSnapshot> _snapshots = {
    DateTime(2024, 2, 15): buildSnapshot(172.54, DateTime(2024, 2, 15)),
    DateTime(2024, 2, 14): buildSnapshot(170.24, DateTime(2024, 2, 14)),
  };

  final Map<DateTime, WatchlistDetail> _details = {
    DateTime(2024, 2, 15): buildDetail(
      tradeVolume: 4705556,
      volumeRatio: 48.71,
    ),
    DateTime(2024, 2, 14): buildDetail(
      tradeVolume: 3901200,
      volumeRatio: 41.33,
    ),
  };

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    return _snapshots[asOf ?? DateTime(2024, 2, 15)]!;
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    return _snapshots.values.first.availableDates.isEmpty
        ? <DateTime>[_snapshots.values.first.asOf]
        : _snapshots.values.first.availableDates;
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async =>
      const <StockSearchItem>[];

  @override
  Future<Set<String>> loadFavoriteIds() async {
    return _snapshots.values.first.items.map((item) => item.id).toSet();
  }

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
    return _details[asOf ?? DateTime(2024, 2, 15)]!;
  }
}

class DetailRetryRepository implements WatchlistRepository {
  bool _failedOnce = false;

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    return buildSnapshot(172.54, DateTime(2024, 2, 15));
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    return buildSnapshot(172.54, DateTime(2024, 2, 15)).availableDates;
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async =>
      const <StockSearchItem>[];

  @override
  Future<Set<String>> loadFavoriteIds() async {
    return buildSnapshot(
      172.54,
      DateTime(2024, 2, 15),
    ).items.map((item) => item.id).toSet();
  }

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
    if (!_failedOnce) {
      _failedOnce = true;
      throw Exception('detail unavailable');
    }
    return buildDetail(tradeVolume: 4705556, volumeRatio: 48.71);
  }
}

class SearchFavoriteFlowRepository implements WatchlistRepository {
  final Set<String> _favoriteIds = <String>{};

  static const WatchlistItem _watchlistItem = WatchlistItem(
    id: 'sk',
    market: MarketType.domestic,
    symbol: '034730',
    name: 'SK',
    currency: 'KRW',
    currentPrice: 70800,
    changeRate: 0.57,
    tradeVolume: 2154000,
    marketCap: 7250000000,
  );

  static const StockSearchItem _searchItem = StockSearchItem(
    id: 'sk',
    market: MarketType.domestic,
    marketLabel: 'KOSPI',
    symbol: '034730',
    name: 'SK',
    isFavorite: false,
  );

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    return WatchlistSnapshot(
      asOf: DateTime(2024, 2, 15),
      availableDates: [DateTime(2024, 2, 15), DateTime(2024, 2, 14)],
      items: _favoriteIds.contains(_watchlistItem.id)
          ? const [_watchlistItem]
          : const <WatchlistItem>[],
    );
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    return <DateTime>[DateTime(2024, 2, 15), DateTime(2024, 2, 14)];
  }

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    return WatchlistDetail(
      itemId: 'sk',
      symbol: '034730',
      market: MarketType.domestic,
      currency: 'KRW',
      currentPrice: 70800,
      changeAmount: 400,
      changeRate: 0.57,
      tradeVolume: 2154000,
      volumeRatio: 22.18,
      openPrice: 70400,
      openChangeRate: 0.14,
      highPrice: 71100,
      highChangeRate: 0.99,
      lowPrice: 70100,
      lowChangeRate: -0.28,
      candles: [
        CandlePoint(
          time: DateTime(2024, 2, 15, 9),
          open: 70400,
          high: 71100,
          low: 70100,
          close: 70800,
          direction: PriceChangeDirection.up,
        ),
      ],
    );
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async {
    if (!query.toLowerCase().contains('sk')) {
      return const <StockSearchItem>[];
    }

    return [
      _searchItem.copyWith(isFavorite: _favoriteIds.contains(_searchItem.id)),
    ];
  }

  @override
  Future<Set<String>> loadFavoriteIds() async {
    return Set<String>.from(_favoriteIds);
  }

  @override
  Future<void> addFavorite({required String itemId}) async {
    _favoriteIds.add(itemId);
  }

  @override
  Future<void> removeFavorite({required String itemId}) async {
    _favoriteIds.remove(itemId);
  }
}

WatchlistSnapshot buildSnapshot(double applePrice, DateTime asOf) {
  final availableDates = [DateTime(2024, 2, 15), DateTime(2024, 2, 14)];

  return WatchlistSnapshot(
    asOf: asOf,
    availableDates: availableDates,
    items: [
      WatchlistItem(
        id: 'apple',
        market: MarketType.overseas,
        symbol: 'AAPL',
        name: '애플',
        currency: 'USD',
        currentPrice: applePrice,
        changeRate: asOf.day == 14 ? -0.45 : 0.70,
        tradeVolume: 4517254,
        marketCap: 2890000000000,
      ),
      const WatchlistItem(
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
}

WatchlistDetail buildDetail({
  required int tradeVolume,
  required double volumeRatio,
}) {
  return WatchlistDetail(
    itemId: 'samsung',
    symbol: '005930',
    market: MarketType.domestic,
    currency: 'KRW',
    currentPrice: 72100,
    changeAmount: -800,
    changeRate: -1.10,
    tradeVolume: tradeVolume,
    volumeRatio: volumeRatio,
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

WatchlistDetail buildSamsungDetail({
  required double currentPrice,
  required double changeAmount,
  required double changeRate,
  required int tradeVolume,
  required double volumeRatio,
}) {
  return WatchlistDetail(
    itemId: 'samsung',
    symbol: '005930',
    market: MarketType.domestic,
    currency: 'KRW',
    currentPrice: currentPrice,
    changeAmount: changeAmount,
    changeRate: changeRate,
    tradeVolume: tradeVolume,
    volumeRatio: volumeRatio,
    openPrice: currentPrice + 100,
    openChangeRate: changeRate / 2,
    highPrice: currentPrice + 300,
    highChangeRate: changeRate + 0.3,
    lowPrice: currentPrice - 200,
    lowChangeRate: changeRate - 0.3,
    candles: [
      CandlePoint(
        time: DateTime(2024, 2, 15, 9),
        open: currentPrice + 40,
        high: currentPrice + 90,
        low: currentPrice - 80,
        close: currentPrice,
        direction: changeAmount >= 0
            ? PriceChangeDirection.up
            : PriceChangeDirection.down,
      ),
    ],
  );
}
