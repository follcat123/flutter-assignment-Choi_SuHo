import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/presentation/widgets/watchlist_logo.dart';

void main() {
  test('builds stable fallback initials', () {
    expect(fallbackMonogram('JYP Ent.'), 'JE');
    expect(fallbackMonogram('카카오'), '카');
    expect(fallbackLogoColor('seed'), fallbackLogoColor('seed'));
  });

  test('detects svg logo urls', () {
    expect(
      isSvgLogoUrl('https://ssl.pstatic.net/imgstock/fn/real/logo/stock/Stock005930.svg'),
      isTrue,
    );
    expect(isSvgLogoUrl('https://example.com/logo.png'), isFalse);
  });

  testWidgets('falls back to a monogram when logoUrl is absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: WatchlistLogo(
            item: WatchlistItem(
              id: 'domestic:035720',
              market: MarketType.domestic,
              symbol: '035720',
              name: '카카오',
              currency: 'KRW',
              currentPrice: 0,
              changeRate: 0,
              tradeVolume: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.text('카'), findsOneWidget);
  });
}
