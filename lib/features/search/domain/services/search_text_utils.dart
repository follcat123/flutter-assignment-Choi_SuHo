import '../../../watchlist/domain/models/watchlist_models.dart';

class SearchTextPart {
  const SearchTextPart({required this.text, required this.isHighlighted});

  final String text;
  final bool isHighlighted;
}

bool matchesSearchItem(StockSearchItem item, String query) {
  final normalizedQuery = _normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return false;
  }

  return _normalizeSearchText(item.name).contains(normalizedQuery) ||
      _normalizeSearchText(item.symbol).contains(normalizedQuery);
}

List<SearchTextPart> splitSearchTextParts(String text, String query) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) {
    return [SearchTextPart(text: text, isHighlighted: false)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = trimmedQuery.toLowerCase();
  final parts = <SearchTextPart>[];
  var start = 0;

  while (start < text.length) {
    final matchIndex = lowerText.indexOf(lowerQuery, start);
    if (matchIndex < 0) {
      parts.add(
        SearchTextPart(text: text.substring(start), isHighlighted: false),
      );
      break;
    }

    if (matchIndex > start) {
      parts.add(
        SearchTextPart(
          text: text.substring(start, matchIndex),
          isHighlighted: false,
        ),
      );
    }

    final highlightedEnd = matchIndex + trimmedQuery.length;
    parts.add(
      SearchTextPart(
        text: text.substring(matchIndex, highlightedEnd),
        isHighlighted: true,
      ),
    );
    start = highlightedEnd;
  }

  return parts.where((part) => part.text.isNotEmpty).toList(growable: false);
}

String buildSearchSubtitle(StockSearchItem item) {
  return '${item.symbol}  |  ${item.marketLabel}';
}

String _normalizeSearchText(String value) {
  return value.trim().toLowerCase().replaceAll(' ', '');
}
