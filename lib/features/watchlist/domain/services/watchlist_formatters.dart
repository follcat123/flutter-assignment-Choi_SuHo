import 'package:intl/intl.dart';

import '../models/watchlist_models.dart';

String formatAsOfDate(DateTime value) {
  return DateFormat('yyyy.MM.dd').format(value);
}

String formatChangeRate(double value) {
  return '${value.toStringAsFixed(2)}%';
}

String formatVolume(int value) {
  return NumberFormat.decimalPattern('en_US').format(value);
}

String formatPrice(WatchlistItem item) {
  return formatCurrencyValue(currency: item.currency, value: item.currentPrice);
}

String formatDetailPrice(WatchlistDetail detail) {
  return formatCurrencyValue(
    currency: detail.currency,
    value: detail.currentPrice,
  );
}

String formatAbsoluteChangeAmount(WatchlistDetail detail) {
  return formatCurrencyValue(
    currency: detail.currency,
    value: detail.changeAmount.abs(),
  );
}

String formatMetricValue({
  required String currency,
  required double price,
  required double changeRate,
}) {
  return '${formatCurrencyValue(currency: currency, value: price)} (${formatSignedPercent(changeRate)})';
}

String formatVolumeWithRatio({
  required int tradeVolume,
  required double volumeRatio,
}) {
  return '${formatVolume(tradeVolume)} (${volumeRatio.toStringAsFixed(2)}%)';
}

String formatCurrencyValue({
  required String currency,
  required double value,
  bool includeSymbol = true,
}) {
  final symbol = switch (currency) {
    'USD' when includeSymbol => r'$',
    _ => '',
  };
  final locale = currency == 'USD' ? 'en_US' : 'ko_KR';
  final decimalDigits = currency == 'USD' ? 2 : 0;

  return NumberFormat.currency(
    locale: locale,
    symbol: symbol,
    decimalDigits: decimalDigits,
  ).format(value);
}

String formatSignedPercent(double value) {
  if (value < 0) {
    return '-${value.abs().toStringAsFixed(2)}%';
  }
  return '${value.abs().toStringAsFixed(2)}%';
}
