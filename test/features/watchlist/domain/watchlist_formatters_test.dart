import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/services/watchlist_formatters.dart';
import 'package:sample/features/watchlist/domain/services/watchlist_sorting.dart';

void main() {
  const apple = WatchlistItem(
    id: 'apple',
    market: MarketType.overseas,
    symbol: 'AAPL',
    name: '애플',
    currency: 'USD',
    currentPrice: 172.54,
    changeRate: 0.70,
    tradeVolume: 4517254,
    marketCap: 2890000000000,
  );

  const samsung = WatchlistItem(
    id: 'samsung',
    market: MarketType.domestic,
    symbol: '005930',
    name: '삼성전자',
    currency: 'KRW',
    currentPrice: 68400,
    changeRate: -0.20,
    tradeVolume: 8210456,
    marketCap: 408000000000,
  );

  const posco = WatchlistItem(
    id: 'posco-dx',
    market: MarketType.domestic,
    symbol: '022100',
    name: '포스코DX',
    currency: 'KRW',
    currentPrice: 54200,
    changeRate: 3.83,
    tradeVolume: 9254200,
    marketCap: 8200000000,
  );

  test('sorts by price, change rate, name, and market cap', () {
    final items = [apple, samsung, posco];

    final price = sortWatchlistItems(items, WatchlistSortMode.price);
    final changeRate = sortWatchlistItems(items, WatchlistSortMode.changeRate);
    final alphabetical = sortWatchlistItems([
      apple,
      samsung,
    ], WatchlistSortMode.alphabetical);
    final marketCap = sortWatchlistItems(items, WatchlistSortMode.marketCap);

    expect(price.first.name, '삼성전자');
    expect(changeRate.first.name, '포스코DX');
    expect(alphabetical.first.name, '삼성전자');
    expect(marketCap.first.name, '애플');
  });

  test('formats price, volume, change rate, and date', () {
    expect(formatPrice(apple), r'$172.54');
    expect(formatPrice(samsung), '68,400');
    expect(formatVolume(723112300), '723,112,300');
    expect(formatChangeRate(-1.65), '-1.65%');
    expect(
      formatMetricValue(currency: 'KRW', price: 72200, changeRate: -0.82),
      '72,200 (-0.82%)',
    );
    expect(
      formatVolumeWithRatio(tradeVolume: 4705556, volumeRatio: 48.71),
      '4,705,556 (48.71%)',
    );
    expect(formatAsOfDate(DateTime(2024, 2, 15)), '2024.02.15');
    expect(formatApiDate(DateTime(2024, 2, 15, 14, 30)), '20240215');
  });
}
