import 'package:shared_preferences/shared_preferences.dart';

const favoriteIdsStorageKey = 'favorite_ids';

const List<String> defaultNaverDomesticFavoriteSymbols = [
  '251340',
  '005930',
  '066570',
  '005380',
  '035720',
  '035420',
  '010950',
  '247540',
  '068270',
  '022100',
  '035900',
];

final Set<String> defaultNaverDomesticFavoriteIds = {
  for (final symbol in defaultNaverDomesticFavoriteSymbols)
    canonicalDomesticFavoriteId(symbol),
};

String canonicalDomesticFavoriteId(String symbol) =>
    'domestic:${symbol.trim()}';

String? domesticSymbolFromFavoriteId(String favoriteId) {
  const prefix = 'domestic:';
  if (!favoriteId.startsWith(prefix)) {
    return null;
  }

  final symbol = favoriteId.substring(prefix.length).trim();
  if (!RegExp(r'^\d{6}$').hasMatch(symbol)) {
    return null;
  }

  return symbol;
}

class FavoriteIdsLocalStore {
  const FavoriteIdsLocalStore(this._sharedPreferences);

  final SharedPreferences? _sharedPreferences;

  bool get hasStoredIds =>
      _sharedPreferences?.containsKey(favoriteIdsStorageKey) ?? false;

  Future<Set<String>> loadRawIds() async {
    final stored = _sharedPreferences?.getStringList(favoriteIdsStorageKey);
    if (stored == null) {
      return <String>{};
    }
    return stored
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> saveRawIds(Set<String> ids) async {
    if (_sharedPreferences == null) {
      return;
    }

    await _sharedPreferences.setStringList(
      favoriteIdsStorageKey,
      ids.toList(growable: false),
    );
  }
}
