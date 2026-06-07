import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/watchlist_repository_provider.dart';
import '../../domain/models/watchlist_models.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../../domain/services/watchlist_sorting.dart';

final watchlistSortModeProvider = StateProvider<WatchlistSortMode>(
  (ref) => WatchlistSortMode.alphabetical,
);

final watchlistSelectedDateProvider = StateProvider<DateTime?>((ref) => null);

final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, WatchlistSnapshot>(
      WatchlistController.new,
    );

class WatchlistController extends AsyncNotifier<WatchlistSnapshot> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  DateTime? get _selectedDate => ref.read(watchlistSelectedDateProvider);

  @override
  Future<WatchlistSnapshot> build() {
    return _repository.fetchWatchlist(asOf: _selectedDate);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _repository.fetchWatchlist(asOf: _selectedDate),
    );
  }

  Future<void> setAsOf(DateTime value) async {
    ref.read(watchlistSelectedDateProvider.notifier).state = normalizeAsOfDate(
      value,
    );
    await refresh();
  }
}
