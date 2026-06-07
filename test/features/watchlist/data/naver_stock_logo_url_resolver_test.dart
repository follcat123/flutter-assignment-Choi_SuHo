import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/watchlist/data/clients/naver_stock_logo_url_resolver.dart';

void main() {
  test('builds the desktop Naver stock logo URL for a domestic symbol', () {
    const resolver = NaverStockLogoUrlResolver();

    expect(
      resolver.resolveDomesticStockLogoUrl('005930'),
      'https://ssl.pstatic.net/imgstock/fn/real/logo/stock/Stock005930.svg',
    );
  });
}
