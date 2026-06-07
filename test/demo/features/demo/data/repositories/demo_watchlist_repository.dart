import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';

import '../../../../../support/repositories/mock_watchlist_repository.dart';

final demoWatchlistRepositoryProvider = Provider<DemoWatchlistRepository>((
  ref,
) {
  throw UnimplementedError(
    'demoWatchlistRepositoryProvider must be overridden in main_demo.dart',
  );
});

class DemoWatchlistRepository implements WatchlistRepository {
  DemoWatchlistRepository() {
    reset();
  }

  late MockWatchlistRepository _delegate;
  bool _failNextSamsungDetail = false;

  void reset() {
    _delegate = MockWatchlistRepository(
      latency: Duration.zero,
      detailLatency: Duration.zero,
      sharedPreferences: null,
    );
    _failNextSamsungDetail = false;
  }

  void armNextSamsungDetailFailure() {
    _failNextSamsungDetail = true;
  }

  @override
  Future<void> addFavorite({required String itemId}) {
    return _delegate.addFavorite(itemId: itemId);
  }

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) {
    return _delegate.fetchWatchlist(asOf: asOf);
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() {
    return _delegate.fetchAvailableDates();
  }

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    if (_failNextSamsungDetail && symbol == '005930') {
      _failNextSamsungDetail = false;
      throw Exception('종목 상세 데이터를 불러오지 못했습니다.');
    }

    return _delegate.fetchWatchlistDetail(
      symbol: symbol,
      market: market,
      asOf: asOf,
    );
  }

  @override
  Future<Set<String>> loadFavoriteIds() {
    return _delegate.loadFavoriteIds();
  }

  @override
  Future<void> removeFavorite({required String itemId}) {
    return _delegate.removeFavorite(itemId: itemId);
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) {
    return _delegate.searchStocks(query: query);
  }
}
