class NaverStockLogoUrlResolver {
  const NaverStockLogoUrlResolver({
    this.assetBaseUrl = 'https://ssl.pstatic.net/imgstock/fn',
    this.environment = 'real',
  });

  final String assetBaseUrl;
  final String environment;

  String resolveDomesticStockLogoUrl(String symbol) {
    final trimmedSymbol = symbol.trim();
    return '$assetBaseUrl/$environment/logo/stock/Stock$trimmedSymbol.svg';
  }
}
