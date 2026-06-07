import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/search/domain/services/search_text_utils.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';

void main() {
  const item = StockSearchItem(
    id: 'sk-telecom',
    market: MarketType.domestic,
    marketLabel: 'KOSPI',
    symbol: 'SKM',
    name: 'SK텔레콤 ADR',
    isFavorite: false,
  );

  test('matches a search item by name and symbol ignoring case and spaces', () {
    expect(matchesSearchItem(item, 'sk'), isTrue);
    expect(matchesSearchItem(item, ' sk m '), isTrue);
    expect(matchesSearchItem(item, '텔레콤'), isTrue);
    expect(matchesSearchItem(item, 'apple'), isFalse);
  });

  test('splits highlighted text for exact search matches', () {
    final nameParts = splitSearchTextParts(item.name, 'sk');
    final subtitleParts = splitSearchTextParts(buildSearchSubtitle(item), 'sk');

    expect(nameParts.length, 2);
    expect(nameParts.first.text, 'SK');
    expect(nameParts.first.isHighlighted, isTrue);
    expect(nameParts.last.text, '텔레콤 ADR');
    expect(nameParts.last.isHighlighted, isFalse);

    expect(subtitleParts.length, 2);
    expect(subtitleParts.first.text, 'SK');
    expect(subtitleParts.first.isHighlighted, isTrue);
    expect(subtitleParts.last.text, 'M  |  KOSPI');
  });

  test('builds the subtitle with figma spacing', () {
    expect(buildSearchSubtitle(item), 'SKM  |  KOSPI');
  });
}
