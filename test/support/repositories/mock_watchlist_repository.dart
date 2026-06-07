import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:sample/features/watchlist/domain/services/watchlist_sorting.dart';

import 'mock_favorite_ids_store.dart';

class MockWatchlistRepository implements WatchlistRepository {
  MockWatchlistRepository({
    this.latency = const Duration(milliseconds: 350),
    this.detailLatency = const Duration(milliseconds: 250),
    this.sharedPreferences,
    Set<String>? initialFavoriteIds,
    WatchlistSnapshot? snapshot,
    Map<DateTime, WatchlistSnapshot>? snapshotsByDate,
    Map<String, WatchlistDetail>? detailOverrides,
    Map<DateTime, Map<String, WatchlistDetail>>? detailOverridesByDate,
    this.shouldThrow = false,
    this.failingDetailSymbols = const {},
  }) : _snapshotsByDate = _resolveSnapshotsByDate(
         snapshot: snapshot,
         snapshotsByDate: snapshotsByDate,
       ),
       _detailOverridesByDate = _resolveDetailOverridesByDate(
         snapshot: snapshot,
         detailOverrides: detailOverrides,
         detailOverridesByDate: detailOverridesByDate,
       ),
       _initialFavoriteIds = _resolveInitialFavoriteIds(
         initialFavoriteIds: initialFavoriteIds,
         snapshot: snapshot,
         snapshotsByDate: snapshotsByDate,
       ),
       _favoriteIdsLocalStore = TestFavoriteIdsLocalStore(sharedPreferences);

  final Duration latency;
  final Duration detailLatency;
  final SharedPreferences? sharedPreferences;
  final bool shouldThrow;
  final Set<String> failingDetailSymbols;
  final Map<String, WatchlistSnapshot> _snapshotsByDate;
  final Map<String, Map<String, WatchlistDetail>> _detailOverridesByDate;
  final Set<String> _initialFavoriteIds;
  final TestFavoriteIdsLocalStore _favoriteIdsLocalStore;

  Set<String>? _favoriteIdsCache;

  static final List<DateTime> _defaultAvailableDates = [
    DateTime(2024, 2, 15),
    DateTime(2024, 2, 14),
    DateTime(2024, 2, 13),
    DateTime(2024, 1, 12),
    DateTime(2023, 12, 11),
  ];

  static const List<WatchlistItem> _watchlistSeedItems = [
    WatchlistItem(
      id: 'kodex-2x',
      market: MarketType.domestic,
      symbol: '233740',
      name: 'KODEX 코스닥150선물인버스',
      currency: 'KRW',
      currentPrice: 3885,
      changeRate: -1.65,
      tradeVolume: 1082375,
      marketCap: 178000000000,
    ),
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
    WatchlistItem(
      id: 'lg-electronics',
      market: MarketType.domestic,
      symbol: '066570',
      name: 'LG전자',
      currency: 'KRW',
      currentPrice: 100900,
      changeRate: 0.20,
      tradeVolume: 4302211,
      marketCap: 16500000000,
    ),
    WatchlistItem(
      id: 'hyundai-motor',
      market: MarketType.domestic,
      symbol: '005380',
      name: '현대차',
      currency: 'KRW',
      currentPrice: 191100,
      changeRate: 0.21,
      tradeVolume: 2911100,
      marketCap: 40100000000,
    ),
    WatchlistItem(
      id: 'kakao',
      market: MarketType.domestic,
      symbol: '035720',
      name: '카카오',
      currency: 'KRW',
      currentPrice: 43950,
      changeRate: 0.46,
      tradeVolume: 6043120,
      marketCap: 19500000000,
    ),
    WatchlistItem(
      id: 'naver',
      market: MarketType.domestic,
      symbol: '035420',
      name: '네이버',
      currency: 'KRW',
      currentPrice: 201500,
      changeRate: 0.25,
      tradeVolume: 2401500,
      marketCap: 32800000000,
    ),
    WatchlistItem(
      id: 's-oil',
      market: MarketType.domestic,
      symbol: '010950',
      name: 'S-Oil',
      currency: 'KRW',
      currentPrice: 79200,
      changeRate: 1.93,
      tradeVolume: 1792200,
      marketCap: 9200000000,
    ),
    WatchlistItem(
      id: 'ecoprobm',
      market: MarketType.domestic,
      symbol: '247540',
      name: '에코프로비엠',
      currency: 'KRW',
      currentPrice: 253000,
      changeRate: -0.59,
      tradeVolume: 1345800,
      marketCap: 24800000000,
    ),
    WatchlistItem(
      id: 'celltrion',
      market: MarketType.domestic,
      symbol: '091990',
      name: '셀트리온헬스케어',
      currency: 'KRW',
      currentPrice: 63400,
      changeRate: 2.27,
      tradeVolume: 34263400,
      marketCap: 11800000000,
    ),
    WatchlistItem(
      id: 'posco-dx',
      market: MarketType.domestic,
      symbol: '022100',
      name: '포스코DX',
      currency: 'KRW',
      currentPrice: 54200,
      changeRate: 3.83,
      tradeVolume: 9254200,
      marketCap: 8200000000,
    ),
    WatchlistItem(
      id: 'jyp',
      market: MarketType.domestic,
      symbol: '035900',
      name: 'JYP Ent.',
      currency: 'KRW',
      currentPrice: 112300,
      changeRate: 0.36,
      tradeVolume: 723112300,
      marketCap: 4200000000,
    ),
  ];

  static const List<WatchlistItem> _searchOnlyItems = [
    WatchlistItem(
      id: 'sk',
      market: MarketType.domestic,
      symbol: '034730',
      name: 'SK',
      currency: 'KRW',
      currentPrice: 70800,
      changeRate: 0.57,
      tradeVolume: 2154000,
      marketCap: 7250000000,
    ),
    WatchlistItem(
      id: 'sk-telecom-adr',
      market: MarketType.domestic,
      symbol: 'SKM',
      name: 'SK텔레콤 ADR',
      currency: 'KRW',
      currentPrice: 103300,
      changeRate: 1.18,
      tradeVolume: 1812500,
      marketCap: 3150000000,
    ),
    WatchlistItem(
      id: 'sk-woo',
      market: MarketType.domestic,
      symbol: '03473K',
      name: 'SK우',
      currency: 'KRW',
      currentPrice: 8470,
      changeRate: 0.36,
      tradeVolume: 740300,
      marketCap: 690000000,
    ),
    WatchlistItem(
      id: 'sk-growth',
      market: MarketType.overseas,
      symbol: 'SKGR',
      name: 'SK 그로스 오퍼튜니티스',
      currency: 'USD',
      currentPrice: 46.35,
      changeRate: 3.00,
      tradeVolume: 410500,
      marketCap: 180000000,
    ),
    WatchlistItem(
      id: 'sk-gas',
      market: MarketType.domestic,
      symbol: '018670',
      name: 'SK가스',
      currency: 'KRW',
      currentPrice: 198600,
      changeRate: 3.12,
      tradeVolume: 920100,
      marketCap: 2290000000,
    ),
    WatchlistItem(
      id: 'sk-square',
      market: MarketType.domestic,
      symbol: '402340',
      name: 'SK스퀘어',
      currency: 'KRW',
      currentPrice: 49050,
      changeRate: 0.41,
      tradeVolume: 1586200,
      marketCap: 6180000000,
    ),
    WatchlistItem(
      id: 'sk-securities',
      market: MarketType.domestic,
      symbol: '001510',
      name: 'SK증권',
      currency: 'KRW',
      currentPrice: 249000,
      changeRate: 9.69,
      tradeVolume: 2352100,
      marketCap: 970000000,
    ),
    WatchlistItem(
      id: 'sk-chemical',
      market: MarketType.domestic,
      symbol: '285130',
      name: 'SK케미칼',
      currency: 'KRW',
      currentPrice: 159100,
      changeRate: 1.47,
      tradeVolume: 802500,
      marketCap: 1540000000,
    ),
    WatchlistItem(
      id: 'sk-dnd',
      market: MarketType.domestic,
      symbol: '210980',
      name: 'SK디엔디',
      currency: 'KRW',
      currentPrice: 95,
      changeRate: 0,
      tradeVolume: 230500,
      marketCap: 240000000,
    ),
    WatchlistItem(
      id: 'sk-rent-a-car',
      market: MarketType.domestic,
      symbol: '068400',
      name: 'SK렌터카',
      currency: 'KRW',
      currentPrice: 58800,
      changeRate: 1.91,
      tradeVolume: 1205100,
      marketCap: 1840000000,
    ),
    WatchlistItem(
      id: 'sk-telecom',
      market: MarketType.domestic,
      symbol: '017670',
      name: 'SK텔레콤',
      currency: 'KRW',
      currentPrice: 98500,
      changeRate: 0.92,
      tradeVolume: 1250400,
      marketCap: 10800000000,
    ),
  ];

  static final Set<String> _defaultFavoriteIds = {
    for (final item in _watchlistSeedItems) item.id,
  };

  static final List<WatchlistItem> _catalogItems = [
    ..._watchlistSeedItems,
    ..._searchOnlyItems,
  ];

  static final Map<String, WatchlistItem> _catalogById = {
    for (final item in _catalogItems) item.id: item,
  };

  static const List<_SearchCatalogEntry> _searchCatalogEntries = [
    _SearchCatalogEntry(itemId: 'sk', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-telecom-adr', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-woo', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-growth', marketLabel: 'NASDAQ'),
    _SearchCatalogEntry(itemId: 'sk-gas', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-square', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-securities', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-chemical', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-dnd', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-rent-a-car', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'sk-telecom', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'apple', marketLabel: 'NASDAQ'),
    _SearchCatalogEntry(itemId: 'samsung', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'kakao', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 'naver', marketLabel: 'KOSPI'),
    _SearchCatalogEntry(itemId: 's-oil', marketLabel: 'KOSPI'),
  ];

  static final Map<String, WatchlistSnapshot> _defaultSnapshotsByDate =
      _buildDefaultSnapshotsByDate();

  static final Map<String, Map<String, WatchlistDetail>>
  _defaultDetailByDateAndSymbol = _buildDefaultDetailByDateAndSymbol();

  String get _latestDateKey => _sortedDateKeys.first;

  List<String> get _sortedDateKeys {
    final keys = _snapshotsByDate.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return keys;
  }

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    await Future<void>.delayed(latency);
    if (shouldThrow) {
      throw Exception('관심종목 데이터를 불러오지 못했습니다.');
    }

    final dateKey = _resolveDateKey(asOf);
    final snapshot = _snapshotsByDate[dateKey];
    if (snapshot == null) {
      throw Exception('등록된 거래일 데이터가 없습니다: $dateKey');
    }

    final favoriteIds = await loadFavoriteIds();
    final filteredItems = snapshot.items
        .where((item) => favoriteIds.contains(item.id))
        .toList(growable: false);

    return WatchlistSnapshot(
      asOf: snapshot.asOf,
      items: filteredItems,
      availableDates: snapshot.availableDates,
    );
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    final latestSnapshot = _snapshotsByDate[_latestDateKey];
    if (latestSnapshot == null) {
      return const <DateTime>[];
    }

    if (latestSnapshot.availableDates.isNotEmpty) {
      return latestSnapshot.availableDates;
    }

    return <DateTime>[latestSnapshot.asOf];
  }

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    await Future<void>.delayed(detailLatency);

    if (failingDetailSymbols.contains(symbol)) {
      throw Exception('종목 상세 데이터를 불러오지 못했습니다.');
    }

    final dateKey = _resolveDateKey(asOf);
    final details = _detailOverridesByDate[dateKey];
    final detail = details?[symbol];
    if (detail == null || detail.market != market) {
      throw Exception('등록된 상세 데이터가 없습니다: $symbol');
    }
    return detail;
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async {
    await Future<void>.delayed(latency);
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const <StockSearchItem>[];
    }

    final normalizedQuery = _normalizeQuery(trimmedQuery);
    final favoriteIds = await loadFavoriteIds();

    return _searchCatalogEntries
        .map((entry) {
          final item = _catalogById[entry.itemId];
          if (item == null) {
            return null;
          }
          final matches =
              _normalizeQuery(item.name).contains(normalizedQuery) ||
              _normalizeQuery(item.symbol).contains(normalizedQuery);
          if (!matches) {
            return null;
          }
          return StockSearchItem(
            id: item.id,
            market: item.market,
            marketLabel: entry.marketLabel,
            symbol: item.symbol,
            name: item.name,
            isFavorite: favoriteIds.contains(item.id),
            logoUrl: item.logoUrl,
          );
        })
        .whereType<StockSearchItem>()
        .toList(growable: false);
  }

  @override
  Future<Set<String>> loadFavoriteIds() async {
    if (_favoriteIdsCache != null) {
      return Set<String>.unmodifiable(_favoriteIdsCache!);
    }

    final storedFavoriteIds = await _favoriteIdsLocalStore.loadRawIds();
    final resolvedFavoriteIds = <String>{};
    for (final itemId in storedFavoriteIds) {
      if (_catalogById.containsKey(itemId)) {
        resolvedFavoriteIds.add(itemId);
        continue;
      }

      final legacyItemId = testLegacyMockFavoriteIdFromCanonicalId(itemId);
      if (legacyItemId != null && _catalogById.containsKey(legacyItemId)) {
        resolvedFavoriteIds.add(legacyItemId);
      }
    }

    _favoriteIdsCache = resolvedFavoriteIds.isEmpty
        ? <String>{..._initialFavoriteIds}
        : resolvedFavoriteIds;

    if (sharedPreferences != null &&
        (storedFavoriteIds.isEmpty ||
            !setEquals(storedFavoriteIds, _favoriteIdsCache))) {
      await _persistFavoriteIds();
    }

    return Set<String>.unmodifiable(_favoriteIdsCache!);
  }

  @override
  Future<void> addFavorite({required String itemId}) async {
    final favoriteIds = {...await loadFavoriteIds(), itemId}
      ..removeWhere((id) => !_catalogById.containsKey(id));
    _favoriteIdsCache = favoriteIds;
    await _persistFavoriteIds();
  }

  @override
  Future<void> removeFavorite({required String itemId}) async {
    final favoriteIds = {...await loadFavoriteIds()}..remove(itemId);
    _favoriteIdsCache = favoriteIds;
    await _persistFavoriteIds();
  }

  Future<void> _persistFavoriteIds() async {
    final favoriteIds = _favoriteIdsCache;
    if (favoriteIds == null) {
      return;
    }

    await _favoriteIdsLocalStore.saveRawIds(favoriteIds);
  }

  String _resolveDateKey(DateTime? asOf) {
    if (asOf == null) {
      return _latestDateKey;
    }

    return formatApiDate(normalizeAsOfDate(asOf));
  }

  static Set<String> _resolveInitialFavoriteIds({
    required Set<String>? initialFavoriteIds,
    required WatchlistSnapshot? snapshot,
    required Map<DateTime, WatchlistSnapshot>? snapshotsByDate,
  }) {
    if (initialFavoriteIds != null && initialFavoriteIds.isNotEmpty) {
      return Set<String>.unmodifiable(initialFavoriteIds);
    }
    if (snapshotsByDate != null && snapshotsByDate.isNotEmpty) {
      final latestSnapshot = snapshotsByDate.entries.toList()
        ..sort((left, right) => right.key.compareTo(left.key));
      return Set<String>.unmodifiable(
        latestSnapshot.first.value.items.map((item) => item.id),
      );
    }
    if (snapshot != null) {
      return Set<String>.unmodifiable(snapshot.items.map((item) => item.id));
    }
    return Set<String>.unmodifiable(_defaultFavoriteIds);
  }

  static Map<String, WatchlistSnapshot> _resolveSnapshotsByDate({
    WatchlistSnapshot? snapshot,
    Map<DateTime, WatchlistSnapshot>? snapshotsByDate,
  }) {
    if (snapshotsByDate != null && snapshotsByDate.isNotEmpty) {
      return _normalizeSnapshotsByDate(snapshotsByDate);
    }
    if (snapshot != null) {
      return _normalizeSnapshotsByDate({snapshot.asOf: snapshot});
    }
    return _defaultSnapshotsByDate;
  }

  static Map<String, Map<String, WatchlistDetail>>
  _resolveDetailOverridesByDate({
    WatchlistSnapshot? snapshot,
    Map<String, WatchlistDetail>? detailOverrides,
    Map<DateTime, Map<String, WatchlistDetail>>? detailOverridesByDate,
  }) {
    if (detailOverridesByDate != null && detailOverridesByDate.isNotEmpty) {
      return _normalizeDetailOverridesByDate(detailOverridesByDate);
    }
    if (detailOverrides != null && detailOverrides.isNotEmpty) {
      final snapshotDate = normalizeAsOfDate(
        snapshot?.asOf ?? _defaultAvailableDates.first,
      );
      return {formatApiDate(snapshotDate): Map.unmodifiable(detailOverrides)};
    }
    return _defaultDetailByDateAndSymbol;
  }

  static Map<String, WatchlistSnapshot> _normalizeSnapshotsByDate(
    Map<DateTime, WatchlistSnapshot> snapshotsByDate,
  ) {
    final availableDates = snapshotsByDate.keys.map(normalizeAsOfDate).toList()
      ..sort((left, right) => right.compareTo(left));
    final normalizedAvailableDates = List<DateTime>.unmodifiable(
      availableDates,
    );

    return Map.unmodifiable({
      for (final entry in snapshotsByDate.entries)
        formatApiDate(normalizeAsOfDate(entry.key)): WatchlistSnapshot(
          asOf: normalizeAsOfDate(entry.value.asOf),
          items: entry.value.items,
          availableDates: entry.value.availableDates.isEmpty
              ? normalizedAvailableDates
              : entry.value.availableDates
                    .map(normalizeAsOfDate)
                    .toList(growable: false),
        ),
    });
  }

  static Map<String, Map<String, WatchlistDetail>>
  _normalizeDetailOverridesByDate(
    Map<DateTime, Map<String, WatchlistDetail>> detailOverridesByDate,
  ) {
    return Map<String, Map<String, WatchlistDetail>>.unmodifiable({
      for (final entry in detailOverridesByDate.entries)
        formatApiDate(
          normalizeAsOfDate(entry.key),
        ): Map<String, WatchlistDetail>.unmodifiable(
          Map<String, WatchlistDetail>.from(entry.value),
        ),
    });
  }

  static Map<String, WatchlistSnapshot> _buildDefaultSnapshotsByDate() {
    return _normalizeSnapshotsByDate({
      for (final date in _defaultAvailableDates)
        date: _buildSnapshotForDate(date),
    });
  }

  static Map<String, Map<String, WatchlistDetail>>
  _buildDefaultDetailByDateAndSymbol() {
    return _normalizeDetailOverridesByDate({
      for (final date in _defaultAvailableDates)
        date: {
          for (final item in _buildItemsForDate(date))
            item.symbol: item.symbol == '005930'
                ? _buildSamsungDetail(date)
                : _buildDefaultDetail(item, date),
        },
    });
  }

  static WatchlistSnapshot _buildSnapshotForDate(DateTime asOf) {
    return WatchlistSnapshot(
      asOf: asOf,
      availableDates: _defaultAvailableDates,
      items: _buildItemsForDate(asOf),
    );
  }

  static List<WatchlistItem> _buildItemsForDate(DateTime asOf) {
    final overrides = _itemOverridesByDate[formatApiDate(asOf)] ?? const {};

    return _catalogItems
        .map((item) {
          final override = overrides[item.symbol];
          if (override == null) {
            return item;
          }

          return WatchlistItem(
            id: item.id,
            market: item.market,
            symbol: item.symbol,
            name: item.name,
            currency: item.currency,
            currentPrice: override.currentPrice ?? item.currentPrice,
            changeRate: override.changeRate ?? item.changeRate,
            tradeVolume: override.tradeVolume ?? item.tradeVolume,
            marketCap: item.marketCap,
            logoUrl: item.logoUrl,
          );
        })
        .toList(growable: false);
  }

  static WatchlistDetail _buildSamsungDetail(DateTime asOf) {
    switch (formatApiDate(asOf)) {
      case '20240214':
        return WatchlistDetail(
          itemId: 'samsung',
          symbol: '005930',
          market: MarketType.domestic,
          currency: 'KRW',
          currentPrice: 71400,
          changeAmount: 500,
          changeRate: 0.70,
          tradeVolume: 3901200,
          volumeRatio: 41.33,
          openPrice: 70800,
          openChangeRate: -0.14,
          highPrice: 71600,
          highChangeRate: 0.98,
          lowPrice: 70600,
          lowChangeRate: -0.42,
          candles: _buildSamsungCandles(asOf, base: 71220),
        );
      case '20240213':
        return WatchlistDetail(
          itemId: 'samsung',
          symbol: '005930',
          market: MarketType.domestic,
          currency: 'KRW',
          currentPrice: 69800,
          changeAmount: 1200,
          changeRate: 1.75,
          tradeVolume: 3324500,
          volumeRatio: 35.02,
          openPrice: 68900,
          openChangeRate: 0.44,
          highPrice: 70100,
          highChangeRate: 2.19,
          lowPrice: 68700,
          lowChangeRate: 0.15,
          candles: _buildSamsungCandles(asOf, base: 69540),
        );
      default:
        return WatchlistDetail(
          itemId: 'samsung',
          symbol: '005930',
          market: MarketType.domestic,
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
          candles: _buildSamsungCandles(asOf, base: 72140),
        );
    }
  }

  static WatchlistDetail _buildDefaultDetail(
    WatchlistItem item,
    DateTime asOf,
  ) {
    final changeAmount = _estimateChangeAmount(item);
    final dateSeed = asOf.day - _defaultAvailableDates.last.day;
    final volumeRatio = 12 + ((item.tradeVolume + dateSeed * 31) % 55) / 1.73;
    final openRate = item.changeRate / 2;
    final highRate = item.changeRate.abs() + 0.36;
    final lowRate = -(item.changeRate.abs() + 0.42);

    return WatchlistDetail(
      itemId: item.id,
      symbol: item.symbol,
      market: item.market,
      currency: item.currency,
      currentPrice: item.currentPrice,
      changeAmount: changeAmount,
      changeRate: item.changeRate,
      tradeVolume: item.tradeVolume,
      volumeRatio: double.parse(volumeRatio.toStringAsFixed(2)),
      openPrice: _roundForCurrency(
        item.currency,
        item.currentPrice - changeAmount / 3,
      ),
      openChangeRate: openRate,
      highPrice: _roundForCurrency(
        item.currency,
        item.currentPrice + item.currentPrice * 0.005,
      ),
      highChangeRate: highRate,
      lowPrice: _roundForCurrency(
        item.currency,
        item.currentPrice - item.currentPrice * 0.006,
      ),
      lowChangeRate: lowRate,
      candles: _buildDefaultCandles(item, asOf),
    );
  }

  static double _estimateChangeAmount(WatchlistItem item) {
    final raw = item.currentPrice * (item.changeRate / 100);
    if (item.currency == 'USD') {
      return double.parse(raw.toStringAsFixed(2));
    }
    return raw.roundToDouble();
  }

  static List<CandlePoint> _buildSamsungCandles(
    DateTime asOf, {
    required double base,
  }) {
    final values = <List<double>>[
      [base + 20, base + 60, base - 30, base - 10],
      [base - 10, base + 20, base - 70, base - 40],
      [base - 40, base + 40, base - 100, base],
      [base, base + 70, base - 40, base + 50],
      [base + 50, base + 100, base + 10, base + 20],
      [base + 20, base + 70, base - 30, base - 10],
      [base - 10, base + 60, base - 40, base + 40],
      [base + 40, base + 120, base, base + 90],
      [base + 90, base + 130, base + 50, base + 80],
      [base + 80, base + 150, base + 40, base + 70],
      [base + 70, base + 120, base + 20, base + 30],
      [base + 30, base + 70, base - 10, base - 10],
      [base - 10, base + 50, base - 40, base + 10],
      [base + 10, base + 60, base - 30, base - 20],
      [base - 20, base + 20, base - 60, base - 30],
      [base - 30, base + 30, base - 70, base],
      [base, base + 50, base - 40, base + 20],
      [base + 20, base + 90, base - 20, base + 70],
      [base + 70, base + 120, base + 30, base + 100],
      [base + 100, base + 130, base + 60, base + 80],
      [base + 80, base + 120, base + 30, base + 60],
      [base + 60, base + 90, base, base + 40],
      [base + 40, base + 100, base - 10, base + 70],
      [base + 70, base + 110, base + 20, base + 80],
      [base + 80, base + 90, base + 10, base + 50],
      [base + 50, base + 70, base - 10, base + 20],
      [base + 20, base + 50, base - 30, base - 10],
      [base - 10, base + 30, base - 40, base],
      [base, base + 40, base - 50, base - 20],
      [base - 20, base + 20, base - 60, base - 10],
      [base - 10, base + 50, base - 40, base + 30],
      [base + 30, base + 90, base, base + 70],
      [base + 70, base + 110, base + 40, base + 90],
      [base + 90, base + 120, base + 40, base + 70],
      [base + 70, base + 80, base, base + 20],
      [base + 20, base + 50, base - 40, base - 20],
      [base - 20, base + 30, base - 50, base],
      [base, base + 60, base - 30, base + 40],
      [base + 40, base + 100, base + 10, base + 70],
      [base + 70, base + 90, base, base - 20],
    ];

    final start = DateTime(asOf.year, asOf.month, asOf.day, 9);
    return [
      for (var index = 0; index < values.length; index++)
        CandlePoint(
          time: start.add(Duration(minutes: index * 3)),
          open: values[index][0],
          high: values[index][1],
          low: values[index][2],
          close: values[index][3],
          direction: directionFromDelta(values[index][3] - values[index][0]),
        ),
    ];
  }

  static List<CandlePoint> _buildDefaultCandles(
    WatchlistItem item,
    DateTime asOf,
  ) {
    final candles = <CandlePoint>[];
    final daySeed = asOf.day * 17;
    final seed = item.symbol.runes.fold<int>(
      daySeed,
      (sum, rune) => sum + rune,
    );
    final start = DateTime(asOf.year, asOf.month, asOf.day, 9);
    var current = item.currentPrice * 0.98;

    for (var index = 0; index < 40; index++) {
      final variance = ((seed + index * 13) % 7 + 1) * 0.0022;
      final isUp = ((seed + index) % 3) != 0;
      final open = current;
      final close = open * (isUp ? 1 + variance : 1 - variance);
      final high = (open > close ? open : close) * (1 + variance / 2);
      final low = (open < close ? open : close) * (1 - variance / 2);

      candles.add(
        CandlePoint(
          time: start.add(Duration(minutes: index * 3)),
          open: _roundForCurrency(item.currency, open),
          high: _roundForCurrency(item.currency, high),
          low: _roundForCurrency(item.currency, low),
          close: _roundForCurrency(item.currency, close),
          direction: directionFromDelta(close - open),
        ),
      );

      current = close;
    }

    return candles;
  }

  static double _roundForCurrency(String currency, double value) {
    if (currency == 'USD') {
      return double.parse(value.toStringAsFixed(2));
    }
    return value.roundToDouble();
  }

  static String _normalizeQuery(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '');
  }

  static const Map<String, Map<String, _ItemOverride>> _itemOverridesByDate = {
    '20240214': {
      'AAPL': _ItemOverride(
        currentPrice: 170.24,
        changeRate: -0.45,
        tradeVolume: 3921044,
      ),
      '005930': _ItemOverride(
        currentPrice: 67900,
        changeRate: -0.56,
        tradeVolume: 7145055,
      ),
      '035720': _ItemOverride(
        currentPrice: 43300,
        changeRate: -0.18,
        tradeVolume: 5124000,
      ),
      '034730': _ItemOverride(
        currentPrice: 70100,
        changeRate: 0.42,
        tradeVolume: 1984200,
      ),
      '402340': _ItemOverride(
        currentPrice: 48200,
        changeRate: -0.51,
        tradeVolume: 1208000,
      ),
    },
    '20240213': {
      'AAPL': _ItemOverride(
        currentPrice: 168.20,
        changeRate: -1.12,
        tradeVolume: 3789001,
      ),
      '005930': _ItemOverride(
        currentPrice: 69500,
        changeRate: 0.88,
        tradeVolume: 6502000,
      ),
      '022100': _ItemOverride(
        currentPrice: 55300,
        changeRate: 4.12,
        tradeVolume: 10452200,
      ),
      '034730': _ItemOverride(
        currentPrice: 69400,
        changeRate: -0.29,
        tradeVolume: 1853000,
      ),
      '402340': _ItemOverride(
        currentPrice: 47950,
        changeRate: -1.12,
        tradeVolume: 1154200,
      ),
    },
  };
}

class _SearchCatalogEntry {
  const _SearchCatalogEntry({required this.itemId, required this.marketLabel});

  final String itemId;
  final String marketLabel;
}

class _ItemOverride {
  const _ItemOverride({this.currentPrice, this.changeRate, this.tradeVolume});

  final double? currentPrice;
  final double? changeRate;
  final int? tradeVolume;
}
