import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/watchlist_models.dart';
import '../../../../theme/app_theme.dart';

class WatchlistCandlestickChart extends StatelessWidget {
  const WatchlistCandlestickChart({
    required this.candles,
    required this.width,
    super.key,
  });

  final List<CandlePoint> candles;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 111,
      child: CustomPaint(painter: _WatchlistCandlestickPainter(candles)),
    );
  }
}

class _WatchlistCandlestickPainter extends CustomPainter {
  _WatchlistCandlestickPainter(this.candles);

  final List<CandlePoint> candles;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) {
      return;
    }

    final lowPrice = candles
        .map((candle) => candle.low)
        .fold<double>(candles.first.low, math.min);
    final highPrice = candles
        .map((candle) => candle.high)
        .fold<double>(candles.first.high, math.max);
    final priceRange = math.max(highPrice - lowPrice, 1).toDouble();
    final candleWidth = size.width / candles.length;
    final bodyWidth = math.max(candleWidth * 0.68, 2).toDouble();
    final wickPaint = Paint()
      ..color = AppDerivedColors.chartWick
      ..strokeWidth = 1;

    for (var index = 0; index < candles.length; index++) {
      final candle = candles[index];
      final centerX = candleWidth * index + candleWidth / 2;
      final highY = _priceToY(candle.high, lowPrice, priceRange, size.height);
      final lowY = _priceToY(candle.low, lowPrice, priceRange, size.height);
      final openY = _priceToY(candle.open, lowPrice, priceRange, size.height);
      final closeY = _priceToY(candle.close, lowPrice, priceRange, size.height);
      final top = math.min(openY, closeY);
      final bottom = math.max(openY, closeY);
      final bodyHeight = math.max(bottom - top, 2).toDouble();

      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, top + bodyHeight / 2),
          width: bodyWidth,
          height: bodyHeight,
        ),
        Paint()..color = _bodyColor(candle.direction),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WatchlistCandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles;
  }

  double _priceToY(double value, double minPrice, double range, double height) {
    final normalized = (value - minPrice) / range;
    return height - (normalized * (height - 4)) - 2;
  }

  Color _bodyColor(PriceChangeDirection direction) {
    switch (direction) {
      case PriceChangeDirection.up:
        return AppColors.mainAndAccent.up_f93f62;
      case PriceChangeDirection.down:
        return AppColors.mainAndAccent.down_4780ff;
      case PriceChangeDirection.flat:
        return AppDerivedColors.chartWick;
    }
  }
}
