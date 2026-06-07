import '../models/watchlist_models.dart';

abstract interface class WatchlistRepository {
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf});

  Future<List<DateTime>> fetchAvailableDates();

  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  });

  Future<List<StockSearchItem>> searchStocks({required String query});

  Future<Set<String>> loadFavoriteIds();

  Future<void> addFavorite({required String itemId});

  Future<void> removeFavorite({required String itemId});
}
