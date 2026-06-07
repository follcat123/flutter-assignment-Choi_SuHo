import 'package:intl/intl.dart';

import '../models/watchlist_models.dart';

List<WatchlistItem> sortWatchlistItems(
  List<WatchlistItem> items,
  WatchlistSortMode sortMode,
) {
  final sortedItems = List<WatchlistItem>.of(items);

  sortedItems.sort((left, right) {
    switch (sortMode) {
      case WatchlistSortMode.price:
        final priceCompare = right.currentPrice.compareTo(left.currentPrice);
        if (priceCompare != 0) {
          return priceCompare;
        }
        return left.name.compareTo(right.name);
      case WatchlistSortMode.changeRate:
        final changeCompare = right.changeRate.compareTo(left.changeRate);
        if (changeCompare != 0) {
          return changeCompare;
        }
        return left.name.compareTo(right.name);
      case WatchlistSortMode.alphabetical:
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.symbol.compareTo(right.symbol);
      case WatchlistSortMode.marketCap:
        final marketCapCompare = right.marketCap.compareTo(left.marketCap);
        if (marketCapCompare != 0) {
          return marketCapCompare;
        }
        return left.name.compareTo(right.name);
    }
  });

  return sortedItems;
}

DateTime normalizeAsOfDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String formatApiDate(DateTime value) {
  return DateFormat('yyyyMMdd').format(normalizeAsOfDate(value));
}
