import 'package:flutter/foundation.dart';

enum WatchlistSortMode {
  price('현재가순'),
  changeRate('등락률순'),
  alphabetical('가나다순'),
  marketCap('시총순');

  const WatchlistSortMode(this.label);

  final String label;
}

enum MarketType { domestic, overseas }

extension MarketTypeX on MarketType {
  String get apiValue {
    switch (this) {
      case MarketType.domestic:
        return 'domestic';
      case MarketType.overseas:
        return 'overseas';
    }
  }
}

enum PriceChangeDirection { up, down, flat }

@immutable
class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.market,
    required this.symbol,
    required this.name,
    required this.currency,
    required this.currentPrice,
    required this.changeRate,
    required this.tradeVolume,
    this.marketCap = 0,
    this.logoUrl,
  });

  final String id;
  final MarketType market;
  final String symbol;
  final String name;
  final String currency;
  final double currentPrice;
  final double changeRate;
  final int tradeVolume;
  final int marketCap;
  final String? logoUrl;

  PriceChangeDirection get direction => directionFromDelta(changeRate);
}

@immutable
class StockSearchItem {
  const StockSearchItem({
    required this.id,
    required this.market,
    required this.marketLabel,
    required this.symbol,
    required this.name,
    required this.isFavorite,
    this.logoUrl,
  });

  final String id;
  final MarketType market;
  final String marketLabel;
  final String symbol;
  final String name;
  final bool isFavorite;
  final String? logoUrl;

  StockSearchItem copyWith({
    String? id,
    MarketType? market,
    String? marketLabel,
    String? symbol,
    String? name,
    bool? isFavorite,
    Object? logoUrl = _sentinel,
  }) {
    return StockSearchItem(
      id: id ?? this.id,
      market: market ?? this.market,
      marketLabel: marketLabel ?? this.marketLabel,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      logoUrl: logoUrl == _sentinel ? this.logoUrl : logoUrl as String?,
    );
  }
}

@immutable
class CandlePoint {
  const CandlePoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.direction,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final PriceChangeDirection direction;
}

@immutable
class WatchlistDetail {
  const WatchlistDetail({
    required this.itemId,
    required this.symbol,
    required this.market,
    required this.currency,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.tradeVolume,
    required this.volumeRatio,
    required this.openPrice,
    required this.openChangeRate,
    required this.highPrice,
    required this.highChangeRate,
    required this.lowPrice,
    required this.lowChangeRate,
    required this.candles,
  });

  final String itemId;
  final String symbol;
  final MarketType market;
  final String currency;
  final double currentPrice;
  final double changeAmount;
  final double changeRate;
  final int tradeVolume;
  final double volumeRatio;
  final double openPrice;
  final double openChangeRate;
  final double highPrice;
  final double highChangeRate;
  final double lowPrice;
  final double lowChangeRate;
  final List<CandlePoint> candles;

  PriceChangeDirection get direction => directionFromDelta(changeAmount);
}

@immutable
class WatchlistSnapshot {
  const WatchlistSnapshot({
    required this.asOf,
    required this.items,
    this.availableDates = const [],
  });

  final DateTime asOf;
  final List<WatchlistItem> items;
  final List<DateTime> availableDates;
}

PriceChangeDirection directionFromDelta(double value) {
  if (value > 0) {
    return PriceChangeDirection.up;
  }
  if (value < 0) {
    return PriceChangeDirection.down;
  }
  return PriceChangeDirection.flat;
}

const _sentinel = Object();
