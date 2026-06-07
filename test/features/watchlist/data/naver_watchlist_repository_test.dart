import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/data/clients/naver_domestic_stock_client.dart';
import 'package:sample/features/watchlist/data/dtos/naver_stock_dtos.dart';
import 'package:sample/features/watchlist/data/repositories/favorite_ids_local_store.dart';
import 'package:sample/features/watchlist/data/repositories/naver_watchlist_repository.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('resets legacy or invalid stored favorites to default domestic ids', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      favoriteIdsStorageKey: <String>['samsung', 'apple', 'domestic:005930'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = NaverWatchlistRepository(
      dio: Dio(),
      favoriteIdsLocalStore: FavoriteIdsLocalStore(preferences),
      client: _FakeNaverStockDataClient(),
    );

    final favoriteIds = await repository.loadFavoriteIds();

    expect(favoriteIds, defaultNaverDomesticFavoriteIds);
    expect(
      preferences.getStringList(favoriteIdsStorageKey)?.toSet(),
      defaultNaverDomesticFavoriteIds,
    );
  });

  test('searches domestic stocks with canonical ids, favorite flags, and logo urls', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      favoriteIdsStorageKey: <String>['domestic:005930'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = NaverWatchlistRepository(
      dio: Dio(),
      favoriteIdsLocalStore: FavoriteIdsLocalStore(preferences),
      client: _FakeNaverStockDataClient(
        searchItems: const [
          NaverAutocompleteItemDto(
            code: '005930',
            name: '삼성전자',
            typeCode: 'KOSPI',
            typeName: '코스피',
            url: '/domestic/stock/005930/total',
            nationCode: 'KOR',
            category: 'stock',
          ),
          NaverAutocompleteItemDto(
            code: 'AAPL',
            name: 'Apple',
            typeCode: 'NASDAQ',
            typeName: 'NASDAQ',
            url: '/worldstock/stock/AAPL',
            nationCode: 'USA',
            category: 'stock',
          ),
        ],
      ),
    );

    final results = await repository.searchStocks(query: '삼성');

    expect(results, hasLength(1));
    expect(results.single.id, 'domestic:005930');
    expect(results.single.marketLabel, '코스피');
    expect(results.single.isFavorite, isTrue);
    expect(
      results.single.logoUrl,
      'https://ssl.pstatic.net/imgstock/fn/real/logo/stock/Stock005930.svg',
    );
  });

  test('lazy loads and caches available dates from daily history pages', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      favoriteIdsStorageKey: <String>['domestic:005930'],
    });
    final preferences = await SharedPreferences.getInstance();
    final client = _FakeNaverStockDataClient();
    final repository = NaverWatchlistRepository(
      dio: Dio(),
      favoriteIdsLocalStore: FavoriteIdsLocalStore(preferences),
      client: client,
    );

    final first = await repository.fetchAvailableDates();
    final second = await repository.fetchAvailableDates();

    expect(first, <DateTime>[
      DateTime(2026, 3, 27),
      DateTime(2026, 3, 26),
      DateTime(2026, 3, 25),
    ]);
    expect(second, first);
    expect(client.dailyHistoryPageCallCount, 1);
  });

  test('maps latest and historical watchlist snapshots from Naver data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      favoriteIdsStorageKey: <String>['domestic:005930'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = NaverWatchlistRepository(
      dio: Dio(),
      favoriteIdsLocalStore: FavoriteIdsLocalStore(preferences),
      client: _FakeNaverStockDataClient(),
    );

    final latestSnapshot = await repository.fetchWatchlist();
    final latestItem = latestSnapshot.items.single;
    expect(latestSnapshot.asOf, DateTime(2026, 3, 27));
    expect(latestItem.id, 'domestic:005930');
    expect(latestItem.currentPrice, 179700);
    expect(latestItem.changeRate, closeTo(-0.22, 0.001));
    expect(latestItem.marketCap, greaterThan(0));
    expect(
      latestItem.logoUrl,
      'https://ssl.pstatic.net/imgstock/fn/real/logo/stock/Stock005930.svg',
    );

    final historicalSnapshot = await repository.fetchWatchlist(
      asOf: DateTime(2026, 3, 26),
    );
    final historicalItem = historicalSnapshot.items.single;
    expect(historicalSnapshot.asOf, DateTime(2026, 3, 26));
    expect(historicalItem.currentPrice, 180100);
    expect(historicalItem.changeRate, closeTo(-4.71, 0.01));
  });

  test('builds detail from a 30-day window ending at the selected date', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      favoriteIdsStorageKey: <String>['domestic:005930'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = NaverWatchlistRepository(
      dio: Dio(),
      favoriteIdsLocalStore: FavoriteIdsLocalStore(preferences),
      client: _FakeNaverStockDataClient(),
    );

    final detail = await repository.fetchWatchlistDetail(
      symbol: '005930',
      market: MarketType.domestic,
      asOf: DateTime(2026, 3, 26),
    );

    expect(detail.itemId, 'domestic:005930');
    expect(detail.currentPrice, 180100);
    expect(detail.changeAmount, -8900);
    expect(detail.changeRate, closeTo(-4.71, 0.01));
    expect(detail.volumeRatio, closeTo(1.39, 0.01));
    expect(detail.candles, hasLength(2));
  });
}

class _FakeNaverStockDataClient implements NaverStockDataClient {
  _FakeNaverStockDataClient({
    List<NaverAutocompleteItemDto>? searchItems,
    Map<String, NaverChartMetadataDto>? metadataBySymbol,
    Map<String, Map<int, NaverDailyHistoryPageDto>>? pagesBySymbol,
    Map<String, NaverRealtimeQuoteDto>? realtimeBySymbol,
  }) : _searchItems = searchItems ?? _defaultSearchItems,
       _metadataBySymbol = metadataBySymbol ?? _defaultMetadataBySymbol,
       _pagesBySymbol = pagesBySymbol ?? _defaultPagesBySymbol,
       _realtimeBySymbol = realtimeBySymbol ?? _defaultRealtimeBySymbol;

  final List<NaverAutocompleteItemDto> _searchItems;
  final Map<String, NaverChartMetadataDto> _metadataBySymbol;
  final Map<String, Map<int, NaverDailyHistoryPageDto>> _pagesBySymbol;
  final Map<String, NaverRealtimeQuoteDto> _realtimeBySymbol;

  int dailyHistoryPageCallCount = 0;

  static const List<NaverAutocompleteItemDto> _defaultSearchItems = [
    NaverAutocompleteItemDto(
      code: '005930',
      name: '삼성전자',
      typeCode: 'KOSPI',
      typeName: '코스피',
      url: '/domestic/stock/005930/total',
      nationCode: 'KOR',
      category: 'stock',
    ),
  ];

  static const Map<String, NaverChartMetadataDto> _defaultMetadataBySymbol = {
    '005930': NaverChartMetadataDto(
      symbol: '005930',
      stockName: '삼성전자',
      stockExchangeNameKor: '코스피',
    ),
  };

  static final Map<String, Map<int, NaverDailyHistoryPageDto>>
  _defaultPagesBySymbol = {
    '005930': {
      1: NaverDailyHistoryPageDto(
        symbol: '005930',
        page: 1,
        lastPage: 1,
        priceInfos: [
          NaverHistoricalPriceDto(
            localDate: DateTime(2026, 3, 27),
            closePrice: 179700,
            openPrice: 172100,
            highPrice: 181700,
            lowPrice: 172000,
            accumulatedTradingVolume: 29113466,
          ),
          NaverHistoricalPriceDto(
            localDate: DateTime(2026, 3, 26),
            closePrice: 180100,
            openPrice: 185500,
            highPrice: 185900,
            lowPrice: 178900,
            accumulatedTradingVolume: 32074131,
          ),
          NaverHistoricalPriceDto(
            localDate: DateTime(2026, 3, 25),
            closePrice: 189000,
            openPrice: 193700,
            highPrice: 196400,
            lowPrice: 189000,
            accumulatedTradingVolume: 22995904,
          ),
        ],
      ),
    },
  };

  static const Map<String, NaverRealtimeQuoteDto> _defaultRealtimeBySymbol = {
    '005930': NaverRealtimeQuoteDto(
      symbol: '005930',
      currentPrice: 179700,
      previousClose: 180100,
      openPrice: 172100,
      highPrice: 181700,
      lowPrice: 172000,
      accumulatedTradingVolume: 29113466,
      countOfListedStock: 5919637922,
    ),
  };

  @override
  Future<List<NaverAutocompleteItemDto>> searchStocks(String query) async {
    return _searchItems;
  }

  @override
  Future<Map<String, NaverRealtimeQuoteDto>> fetchRealtimeQuotes(
    Iterable<String> symbols,
  ) async {
    return {
      for (final symbol in symbols)
        if (_realtimeBySymbol.containsKey(symbol))
          symbol: _realtimeBySymbol[symbol]!,
    };
  }

  @override
  Future<NaverChartMetadataDto> fetchChartMetadata(String symbol) async {
    return _metadataBySymbol[symbol]!;
  }

  @override
  Future<NaverDailyHistoryPageDto> fetchDailyHistoryPage({
    required String symbol,
    required int page,
  }) async {
    dailyHistoryPageCallCount++;
    return _pagesBySymbol[symbol]![page]!;
  }
}
