import 'package:shared_preferences/shared_preferences.dart';

const testFavoriteIdsStorageKey = 'favorite_ids';

const Map<String, String> legacyMockDomesticSymbolByFavoriteId = {
  'kodex-2x': '251340',
  'samsung': '005930',
  'lg-electronics': '066570',
  'hyundai-motor': '005380',
  'kakao': '035720',
  'naver': '035420',
  's-oil': '010950',
  'ecoprobm': '247540',
  'celltrion': '068270',
  'posco-dx': '022100',
  'jyp': '035900',
};

final Map<String, String> legacyMockDomesticFavoriteIdBySymbol = {
  for (final entry in legacyMockDomesticSymbolByFavoriteId.entries)
    entry.value: entry.key,
};

String? testLegacyMockFavoriteIdFromCanonicalId(String favoriteId) {
  const prefix = 'domestic:';
  if (!favoriteId.startsWith(prefix)) {
    return null;
  }

  final symbol = favoriteId.substring(prefix.length).trim();
  if (symbol.isEmpty) {
    return null;
  }

  return legacyMockDomesticFavoriteIdBySymbol[symbol];
}

class TestFavoriteIdsLocalStore {
  const TestFavoriteIdsLocalStore(this._sharedPreferences);

  final SharedPreferences? _sharedPreferences;

  Future<Set<String>> loadRawIds() async {
    final stored = _sharedPreferences?.getStringList(testFavoriteIdsStorageKey);
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
      testFavoriteIdsStorageKey,
      ids.toList(growable: false),
    );
  }
}
