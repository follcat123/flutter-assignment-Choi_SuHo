import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/watchlist_repository_provider.dart';
import '../../domain/repositories/watchlist_repository.dart';

final favoriteIdsControllerProvider =
    AsyncNotifierProvider<FavoriteIdsController, Set<String>>(
      FavoriteIdsController.new,
    );

class FavoriteIdsController extends AsyncNotifier<Set<String>> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    return _repository.loadFavoriteIds();
  }

  Future<bool> toggle(String itemId) async {
    final currentFavoriteIds = {...(state.valueOrNull ?? await future)};
    if (currentFavoriteIds.contains(itemId)) {
      await remove(itemId);
      return false;
    }

    await add(itemId);
    return true;
  }

  Future<void> add(String itemId) async {
    final currentFavoriteIds = {...(state.valueOrNull ?? await future), itemId};
    state = AsyncData(currentFavoriteIds);
    await _repository.addFavorite(itemId: itemId);
  }

  Future<void> remove(String itemId) async {
    final currentFavoriteIds = {...(state.valueOrNull ?? await future)}
      ..remove(itemId);
    state = AsyncData(currentFavoriteIds);
    await _repository.removeFavorite(itemId: itemId);
  }
}
