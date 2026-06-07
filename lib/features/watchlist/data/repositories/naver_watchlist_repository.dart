// ignore_for_file: unused_element, unused_field

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/watchlist_models.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../../domain/services/watchlist_sorting.dart';
import '../clients/naver_domestic_stock_client.dart';
import '../clients/naver_stock_logo_url_resolver.dart';
import '../dtos/naver_stock_dtos.dart';
import 'favorite_ids_local_store.dart';

class NaverWatchlistRepository implements WatchlistRepository {
  NaverWatchlistRepository({
    required Dio dio,
    required FavoriteIdsLocalStore favoriteIdsLocalStore,
    NaverStockDataClient? client,
    NaverStockLogoUrlResolver? logoUrlResolver,
    this.realtimeCacheTtl = const Duration(seconds: 10),
    this.dailyHistoryFetchBatchSize = 4,
  }) : _client = client ?? NaverDomesticStockClient(dio),
       _favoriteIdsLocalStore = favoriteIdsLocalStore,
       _logoUrlResolver = logoUrlResolver ?? const NaverStockLogoUrlResolver();

  static const _historyRowsPerPage = 10;

  final NaverStockDataClient _client;
  final FavoriteIdsLocalStore _favoriteIdsLocalStore;
  final NaverStockLogoUrlResolver _logoUrlResolver;
  final Duration realtimeCacheTtl;
  final int dailyHistoryFetchBatchSize;

  final Map<String, NaverChartMetadataDto> _metadataCache = {};
  final Map<String, NaverDailyHistoryPageDto> _dailyHistoryPageCache = {};
  final Map<String, _RealtimeQuoteCacheEntry> _realtimeQuoteCache = {};

  Set<String>? _favoriteIdsCache;
  List<DateTime>? _availableDatesCache;

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    // 즐겨찾기 id → 국내 6자리 심볼 변환
    final favoriteIds = await loadFavoriteIds();
    final symbols = favoriteIds
        .map(domesticSymbolFromFavoriteId)
        .whereType<String>()
        .toList(growable: false);

    if (symbols.isEmpty) {
      final resolvedAsOf = normalizeAsOfDate(asOf ?? DateTime.now());
      return WatchlistSnapshot(asOf: resolvedAsOf, items: []);
    }

    // 메타데이터와 실시간 시세를 병렬 로드
    final metadataMap = await _loadMetadataBatch(symbols);
    final realtimeMap = await _loadRealtimeQuotes(symbols);

    // asOf가 없으면 최신 데이터, 있으면 해당 날짜 기준
    DateTime? resolvedAsOf;
    final items = <WatchlistItem>[];

    if (asOf == null) {
      // 최신 날짜는 첫 번째 심볼의 첫 번째 히스토리 행에서 가져온다
      DateTime? latestDate;
      for (final symbol in symbols) {
        final metadata = metadataMap[symbol];
        if (metadata == null) continue;

        final entry = await _loadLatestHistoricalEntry(symbol);
        if (entry == null) continue;

        final entryDate = normalizeAsOfDate(entry.row.localDate);
        latestDate ??= entryDate;

        items.add(
          _buildWatchlistItem(
            symbol: symbol,
            metadata: metadata,
            historicalEntry: entry,
            realtimeQuote: realtimeMap[symbol],
            latestDate: latestDate,
          ),
        );
      }
      resolvedAsOf = latestDate ?? normalizeAsOfDate(DateTime.now());
    } else {
      // 선택된 거래일 기준 스냅샷
      final availableDates = await fetchAvailableDates();
      resolvedAsOf = _resolveAsOf(availableDates, asOf);

      for (final symbol in symbols) {
        final metadata = metadataMap[symbol];
        if (metadata == null) continue;

        final entry = await _loadHistoricalEntryForDate(
          symbol: symbol,
          availableDates: availableDates,
          asOf: resolvedAsOf,
        );
        if (entry == null) continue;

        items.add(
          _buildWatchlistItem(
            symbol: symbol,
            metadata: metadata,
            historicalEntry: entry,
            realtimeQuote: realtimeMap[symbol],
            latestDate: availableDates.isNotEmpty ? availableDates.first : null,
          ),
        );
      }
    }

    return WatchlistSnapshot(asOf: resolvedAsOf, items: items);
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async {
    if (_availableDatesCache != null) {
      return _availableDatesCache!;
    }

    // 기준 심볼: 즐겨찾기 첫 번째 국내 종목 사용
    final favoriteIds = await loadFavoriteIds();
    final symbol = favoriteIds
        .map(domesticSymbolFromFavoriteId)
        .whereType<String>()
        .firstOrNull;

    if (symbol == null) {
      _availableDatesCache = [];
      return [];
    }

    // 1페이지 먼저 로드해서 lastPage 파악
    final firstPage = await _loadDailyHistoryPage(symbol, 1);
    final lastPage = firstPage.lastPage;

    final allPages = [firstPage];

    // 나머지 페이지를 배치로 로드
    for (var batch = 2; batch <= lastPage; batch += dailyHistoryFetchBatchSize) {
      final batchEnd = (batch + dailyHistoryFetchBatchSize - 1).clamp(batch, lastPage);
      final futures = [
        for (var p = batch; p <= batchEnd; p++) _loadDailyHistoryPage(symbol, p),
      ];
      allPages.addAll(await Future.wait(futures));
    }

    // 모든 날짜를 내림차순으로 병합 (페이지 순서대로 이미 내림차순)
    final dates = allPages
        .expand((page) => page.priceInfos)
        .map((row) => normalizeAsOfDate(row.localDate))
        .toList(growable: false);

    _availableDatesCache = dates;
    return dates;
  }

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    if (market != MarketType.domestic) {
      throw ArgumentError('Only domestic stocks are supported');
    }

    final availableDates = await fetchAvailableDates();
    final resolvedAsOf = _resolveAsOf(availableDates, asOf);
    final selectedIndex = _indexOfDate(availableDates, resolvedAsOf) ?? 0;
    final isLatest = selectedIndex == 0;

    // 선택일 포함 직전 30거래일 윈도우
    const windowSize = 30;
    final windowDates = availableDates
        .skip(selectedIndex)
        .take(windowSize)
        .toList(growable: false);

    // 윈도우에 해당하는 페이지들 로드
    final pagesNeeded = <int>{};
    for (var i = selectedIndex; i < selectedIndex + windowSize && i < availableDates.length; i++) {
      pagesNeeded.add(_pageNumberForIndex(i));
    }
    await Future.wait(pagesNeeded.map((p) => _loadDailyHistoryPage(symbol, p)));

    // 날짜 → 행 맵 구성
    final rowsByDate = <String, NaverHistoricalPriceDto>{};
    for (final pageNum in pagesNeeded) {
      final pageData = _dailyHistoryPageCache[_dailyHistoryPageCacheKey(symbol, pageNum)];
      if (pageData != null) {
        for (final row in pageData.priceInfos) {
          rowsByDate[_dateKey(row.localDate)] = row;
        }
      }
    }

    final selectedRow = rowsByDate[_dateKey(resolvedAsOf)];
    if (selectedRow == null) {
      throw StateError('No data for $symbol on $resolvedAsOf');
    }

    // 전일 종가 확인
    final previousClose = await _resolvePreviousClose(
      symbol: symbol,
      availableDates: availableDates,
      selectedIndex: selectedIndex,
      fallbackOpenPrice: selectedRow.openPrice,
      rowsByDate: rowsByDate,
    );

    // 실시간 시세는 최신 거래일에만 사용
    NaverRealtimeQuoteDto? realtimeQuote;
    if (isLatest) {
      final realtimeMap = await _loadRealtimeQuotes([symbol]);
      realtimeQuote = realtimeMap[symbol];
    }

    final currentPrice = isLatest && realtimeQuote != null
        ? realtimeQuote.currentPrice
        : selectedRow.closePrice;
    final changeAmount = currentPrice - previousClose;
    final changeRate = _percentChange(changeAmount, previousClose);
    final tradeVolume = isLatest && realtimeQuote != null
        ? realtimeQuote.accumulatedTradingVolume
        : selectedRow.accumulatedTradingVolume;

    return WatchlistDetail(
      itemId: canonicalDomesticFavoriteId(symbol),
      symbol: symbol,
      market: market,
      currency: 'KRW',
      currentPrice: currentPrice,
      changeAmount: changeAmount,
      changeRate: changeRate,
      tradeVolume: tradeVolume,
      volumeRatio: _volumeRatio(
        windowDatesDescending: windowDates,
        rowsByDate: rowsByDate,
      ),
      openPrice: selectedRow.openPrice,
      openChangeRate: _percentChange(
        selectedRow.openPrice - previousClose,
        previousClose,
      ),
      highPrice: selectedRow.highPrice,
      highChangeRate: _percentChange(
        selectedRow.highPrice - previousClose,
        previousClose,
      ),
      lowPrice: selectedRow.lowPrice,
      lowChangeRate: _percentChange(
        selectedRow.lowPrice - previousClose,
        previousClose,
      ),
      candles: _candles(
        windowDatesDescending: windowDates,
        rowsByDate: rowsByDate,
      ),
    );
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final [rawItems, favoriteIds] = await Future.wait([
      _client.searchStocks(trimmedQuery),
      loadFavoriteIds(),
    ]);

    final seenSymbols = <String>{};
    final results = <StockSearchItem>[];

    for (final dto in rawItems as List<NaverAutocompleteItemDto>) {
      if (!dto.isDomesticStock) continue;
      if (!seenSymbols.add(dto.code)) continue; // 중복 제거

      final canonicalId = canonicalDomesticFavoriteId(dto.code);
      results.add(
        StockSearchItem(
          id: canonicalId,
          market: MarketType.domestic,
          marketLabel: dto.typeName,
          symbol: dto.code,
          name: dto.name,
          isFavorite: (favoriteIds as Set<String>).contains(canonicalId),
          logoUrl: _logoUrlResolver.resolveDomesticStockLogoUrl(dto.code),
        ),
      );
    }

    return results;
  }

  @override
  Future<Set<String>> loadFavoriteIds() async {
    if (_favoriteIdsCache != null) {
      return Set<String>.unmodifiable(_favoriteIdsCache!);
    }

    final rawIds = await _favoriteIdsLocalStore.loadRawIds();
    final canonicalIds = rawIds.where(_isCanonicalFavoriteId).toSet();
    final hasLegacyOrInvalidIds =
        rawIds.isNotEmpty && canonicalIds.length != rawIds.length;

    final resolvedIds = !_favoriteIdsLocalStore.hasStoredIds
        ? <String>{...defaultNaverDomesticFavoriteIds}
        : hasLegacyOrInvalidIds
        ? <String>{...defaultNaverDomesticFavoriteIds}
        : canonicalIds;

    _favoriteIdsCache = resolvedIds;

    if (!setEquals(rawIds, resolvedIds)) {
      await _favoriteIdsLocalStore.saveRawIds(resolvedIds);
    }

    return Set<String>.unmodifiable(resolvedIds);
  }

  @override
  Future<void> addFavorite({required String itemId}) async {
    final canonicalId = _requireCanonicalFavoriteId(itemId);
    final favoriteIds = {...await loadFavoriteIds(), canonicalId};
    _favoriteIdsCache = favoriteIds;
    await _favoriteIdsLocalStore.saveRawIds(favoriteIds);
  }

  @override
  Future<void> removeFavorite({required String itemId}) async {
    final canonicalId = _requireCanonicalFavoriteId(itemId);
    final favoriteIds = {...await loadFavoriteIds()}..remove(canonicalId);
    _favoriteIdsCache = favoriteIds;
    await _favoriteIdsLocalStore.saveRawIds(favoriteIds);
  }

  Future<Map<String, NaverChartMetadataDto>> _loadMetadataBatch(
    List<String> symbols,
  ) async {
    final results = <String, NaverChartMetadataDto>{};
    for (final symbol in symbols) {
      try {
        results[symbol] = await _loadMetadata(symbol);
      } catch (error, stackTrace) {
        debugPrint('Skipping Naver metadata for $symbol: $error\n$stackTrace');
      }
    }
    return results;
  }

  Future<NaverChartMetadataDto> _loadMetadata(String symbol) async {
    final cached = _metadataCache[symbol];
    if (cached != null) {
      return cached;
    }

    final metadata = await _client.fetchChartMetadata(symbol);
    _metadataCache[symbol] = metadata;
    return metadata;
  }

  Future<NaverDailyHistoryPageDto> _loadDailyHistoryPage(
    String symbol,
    int page,
  ) async {
    final cacheKey = _dailyHistoryPageCacheKey(symbol, page);
    final cached = _dailyHistoryPageCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final historyPage = await _client.fetchDailyHistoryPage(
      symbol: symbol,
      page: page,
    );
    _dailyHistoryPageCache[cacheKey] = historyPage;
    return historyPage;
  }

  Future<Map<String, NaverRealtimeQuoteDto>> _loadRealtimeQuotes(
    Iterable<String> symbols,
  ) async {
    final requestedSymbols = symbols.toSet();
    final now = DateTime.now();
    final missingSymbols = <String>[];
    final quotes = <String, NaverRealtimeQuoteDto>{};

    for (final symbol in requestedSymbols) {
      final cached = _realtimeQuoteCache[symbol];
      final isFresh =
          cached != null &&
          now.difference(cached.fetchedAt) <= realtimeCacheTtl;
      if (isFresh) {
        quotes[symbol] = cached.quote;
      } else {
        missingSymbols.add(symbol);
      }
    }

    if (missingSymbols.isNotEmpty) {
      try {
        final fetchedQuotes = await _client.fetchRealtimeQuotes(missingSymbols);
        final fetchedAt = DateTime.now();
        for (final entry in fetchedQuotes.entries) {
          _realtimeQuoteCache[entry.key] = _RealtimeQuoteCacheEntry(
            quote: entry.value,
            fetchedAt: fetchedAt,
          );
          quotes[entry.key] = entry.value;
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Falling back to historical-only Naver data for realtime batch: '
          '$error\n$stackTrace',
        );
      }
    }

    return quotes;
  }

  Future<_HistoricalEntry?> _loadHistoricalEntryForDate({
    required String symbol,
    required List<DateTime> availableDates,
    required DateTime asOf,
  }) async {
    final selectedIndex = _indexOfDate(availableDates, asOf);
    if (selectedIndex == null) {
      return null;
    }

    final selectedPageNumber = _pageNumberForIndex(selectedIndex);
    final selectedPage = await _loadDailyHistoryPage(
      symbol,
      selectedPageNumber,
    );
    final selectedRow = _rowForDate(selectedPage.priceInfos, asOf);
    if (selectedRow == null) {
      return null;
    }

    final previousClose = await _resolvePreviousClose(
      symbol: symbol,
      availableDates: availableDates,
      selectedIndex: selectedIndex,
      fallbackOpenPrice: selectedRow.openPrice,
      rowsByDate: {
        for (final row in selectedPage.priceInfos) _dateKey(row.localDate): row,
      },
    );

    return _HistoricalEntry(row: selectedRow, previousClose: previousClose);
  }

  Future<_HistoricalEntry?> _loadLatestHistoricalEntry(String symbol) async {
    final firstPage = await _loadDailyHistoryPage(symbol, 1);
    if (firstPage.priceInfos.isEmpty) {
      return null;
    }

    final selectedRow = firstPage.priceInfos.first;
    double previousClose = selectedRow.openPrice;
    if (firstPage.priceInfos.length > 1) {
      previousClose = firstPage.priceInfos[1].closePrice;
    } else {
      final nextPageRows = (await _loadDailyHistoryPage(symbol, 2)).priceInfos;
      if (nextPageRows.isNotEmpty) {
        previousClose = nextPageRows.first.closePrice;
      }
    }

    return _HistoricalEntry(row: selectedRow, previousClose: previousClose);
  }

  Future<double> _resolvePreviousClose({
    required String symbol,
    required List<DateTime> availableDates,
    required int selectedIndex,
    required double fallbackOpenPrice,
    required Map<String, NaverHistoricalPriceDto> rowsByDate,
  }) async {
    if (selectedIndex >= availableDates.length - 1) {
      return fallbackOpenPrice;
    }

    final previousDate = availableDates[selectedIndex + 1];
    final previousRowFromCache = rowsByDate[_dateKey(previousDate)];
    if (previousRowFromCache != null) {
      return previousRowFromCache.closePrice;
    }

    final page = await _loadDailyHistoryPage(
      symbol,
      _pageNumberForIndex(selectedIndex + 1),
    );
    final previousRow = _rowForDate(page.priceInfos, previousDate);
    return previousRow?.closePrice ?? fallbackOpenPrice;
  }

  WatchlistItem _buildWatchlistItem({
    required String symbol,
    required NaverChartMetadataDto metadata,
    required _HistoricalEntry historicalEntry,
    required NaverRealtimeQuoteDto? realtimeQuote,
    required DateTime? latestDate,
  }) {
    final isLatest =
        latestDate != null &&
        normalizeAsOfDate(historicalEntry.row.localDate) == latestDate;
    final currentPrice = isLatest && realtimeQuote != null
        ? realtimeQuote.currentPrice
        : historicalEntry.row.closePrice;
    final changeRate = isLatest && realtimeQuote != null
        ? realtimeQuote.changeRate
        : _percentChange(
            currentPrice - historicalEntry.previousClose,
            historicalEntry.previousClose,
          );
    final tradeVolume = isLatest && realtimeQuote != null
        ? realtimeQuote.accumulatedTradingVolume
        : historicalEntry.row.accumulatedTradingVolume;
    final marketCap = realtimeQuote == null
        ? 0
        : (realtimeQuote.countOfListedStock * realtimeQuote.currentPrice)
              .round();

    return WatchlistItem(
      id: canonicalDomesticFavoriteId(symbol),
      market: MarketType.domestic,
      symbol: symbol,
      name: metadata.stockName,
      currency: 'KRW',
      currentPrice: currentPrice,
      changeRate: changeRate,
      tradeVolume: tradeVolume,
      marketCap: marketCap,
      logoUrl: _logoUrlResolver.resolveDomesticStockLogoUrl(symbol),
    );
  }

  DateTime _resolveAsOf(
    List<DateTime> availableDates,
    DateTime? requestedAsOf,
  ) {
    if (availableDates.isEmpty) {
      return normalizeAsOfDate(requestedAsOf ?? DateTime.now());
    }

    if (requestedAsOf == null) {
      return availableDates.first;
    }

    final normalizedAsOf = normalizeAsOfDate(requestedAsOf);
    for (final date in availableDates) {
      if (date == normalizedAsOf) {
        return date;
      }
    }

    return availableDates.first;
  }

  int? _indexOfDate(List<DateTime> availableDates, DateTime asOf) {
    final normalizedAsOf = normalizeAsOfDate(asOf);
    for (var index = 0; index < availableDates.length; index += 1) {
      if (availableDates[index] == normalizedAsOf) {
        return index;
      }
    }
    return null;
  }

  int _pageNumberForIndex(int index) {
    return (index ~/ _historyRowsPerPage) + 1;
  }

  NaverHistoricalPriceDto? _rowForDate(
    Iterable<NaverHistoricalPriceDto> rows,
    DateTime date,
  ) {
    final dateKey = _dateKey(date);
    for (final row in rows) {
      if (_dateKey(row.localDate) == dateKey) {
        return row;
      }
    }
    return null;
  }

  double _volumeRatio({
    required List<DateTime> windowDatesDescending,
    required Map<String, NaverHistoricalPriceDto> rowsByDate,
  }) {
    if (windowDatesDescending.isEmpty) {
      return 0;
    }

    final selectedRow = rowsByDate[_dateKey(windowDatesDescending.first)];
    if (selectedRow == null) {
      return 0;
    }

    final previousVolumes = <int>[];
    for (
      var index = 1;
      index < windowDatesDescending.length && previousVolumes.length < 5;
      index += 1
    ) {
      final row = rowsByDate[_dateKey(windowDatesDescending[index])];
      if (row != null) {
        previousVolumes.add(row.accumulatedTradingVolume);
      }
    }

    if (previousVolumes.isEmpty) {
      return 0;
    }

    final averageVolume =
        previousVolumes.reduce((left, right) => left + right) /
        previousVolumes.length;
    if (averageVolume == 0) {
      return 0;
    }

    return double.parse(
      (selectedRow.accumulatedTradingVolume / averageVolume).toStringAsFixed(2),
    );
  }

  List<CandlePoint> _candles({
    required List<DateTime> windowDatesDescending,
    required Map<String, NaverHistoricalPriceDto> rowsByDate,
  }) {
    return windowDatesDescending.reversed
        .map((date) => rowsByDate[_dateKey(date)])
        .whereType<NaverHistoricalPriceDto>()
        .map(
          (item) => CandlePoint(
            time: item.localDate,
            open: item.openPrice,
            high: item.highPrice,
            low: item.lowPrice,
            close: item.closePrice,
            direction: directionFromDelta(item.closePrice - item.openPrice),
          ),
        )
        .toList(growable: false);
  }

  bool _isCanonicalFavoriteId(String itemId) {
    return domesticSymbolFromFavoriteId(itemId) != null;
  }

  String _requireCanonicalFavoriteId(String itemId) {
    final symbol = domesticSymbolFromFavoriteId(itemId);
    if (symbol == null) {
      throw ArgumentError.value(
        itemId,
        'itemId',
        'Naver repository only accepts canonical domestic favorite ids',
      );
    }
    return canonicalDomesticFavoriteId(symbol);
  }

  String _dailyHistoryPageCacheKey(String symbol, int page) => '$symbol::$page';

  String _dateKey(DateTime value) => formatApiDate(value);

  double _percentChange(double delta, double base) {
    if (base == 0) {
      return 0;
    }
    return double.parse(((delta / base) * 100).toStringAsFixed(2));
  }
}

class _RealtimeQuoteCacheEntry {
  const _RealtimeQuoteCacheEntry({
    required this.quote,
    required this.fetchedAt,
  });

  final NaverRealtimeQuoteDto quote;
  final DateTime fetchedAt;
}

class _HistoricalEntry {
  const _HistoricalEntry({required this.row, required this.previousClose});

  final NaverHistoricalPriceDto row;
  final double previousClose;
}
