import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/watchlist_repository_provider.dart';
import '../../domain/models/watchlist_models.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../../domain/services/watchlist_sorting.dart';
import 'watchlist_controller.dart';

final watchlistDetailControllerProvider =
    NotifierProvider<WatchlistDetailController, WatchlistDetailState>(
      WatchlistDetailController.new,
    );

class WatchlistDetailController extends Notifier<WatchlistDetailState> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  String get _selectedDateKey {
    final selectedDate = ref.read(watchlistSelectedDateProvider);
    if (selectedDate == null) {
      return 'latest';
    }
    return formatApiDate(selectedDate);
  }

  @override
  WatchlistDetailState build() => const WatchlistDetailState();

  Future<void> toggleSelection(WatchlistItem item) async {
    if (state.selectedItemId == item.id) {
      state = state.copyWith(selectedItemId: null);
      return;
    }

    state = state.copyWith(selectedItemId: item.id);

    final existingDetail = state.detailStates[item.id];
    if (existingDetail == null || existingDetail.hasError) {
      await fetchDetail(item, force: true);
    }
  }

  Future<void> fetchDetail(WatchlistItem item, {bool force = false}) async {
    final dateKey = _selectedDateKey;
    if (state.dateKey != dateKey) {
      state = WatchlistDetailState(
        selectedItemId: state.selectedItemId,
        dateKey: dateKey,
      );
    }

    final existingDetail = state.detailStates[item.id];
    if (!force && existingDetail != null && existingDetail.hasValue) {
      return;
    }

    final loadingState = existingDetail == null
        ? const AsyncLoading<WatchlistDetail>()
        : AsyncLoading<WatchlistDetail>().copyWithPrevious(existingDetail);

    state = state.copyWith(
      detailStates: {...state.detailStates, item.id: loadingState},
    );

    final result = await AsyncValue.guard(
      () => _repository.fetchWatchlistDetail(
        symbol: item.symbol,
        market: item.market,
        asOf: ref.read(watchlistSelectedDateProvider),
      ),
    );

    state = state.copyWith(
      dateKey: dateKey,
      detailStates: {...state.detailStates, item.id: result},
    );
  }

  Future<void> invalidateCacheAndReselect(List<WatchlistItem> items) async {
    final selectedItemId = state.selectedItemId;
    if (selectedItemId == null) {
      state = const WatchlistDetailState();
      return;
    }

    WatchlistItem? selectedItem;
    for (final item in items) {
      if (item.id == selectedItemId) {
        selectedItem = item;
        break;
      }
    }

    if (selectedItem == null) {
      state = const WatchlistDetailState();
      return;
    }

    state = WatchlistDetailState(
      selectedItemId: selectedItemId,
      dateKey: _selectedDateKey,
    );
    await fetchDetail(selectedItem, force: true);
  }

  void clearAll() {
    state = const WatchlistDetailState();
  }
}

@immutable
class WatchlistDetailState {
  const WatchlistDetailState({
    this.selectedItemId,
    this.detailStates = const {},
    this.dateKey = 'latest',
  });

  final String? selectedItemId;
  final Map<String, AsyncValue<WatchlistDetail>> detailStates;
  final String dateKey;

  AsyncValue<WatchlistDetail>? detailFor(String itemId) => detailStates[itemId];

  WatchlistDetailState copyWith({
    Object? selectedItemId = _sentinel,
    Map<String, AsyncValue<WatchlistDetail>>? detailStates,
    String? dateKey,
  }) {
    return WatchlistDetailState(
      selectedItemId: selectedItemId == _sentinel
          ? this.selectedItemId
          : selectedItemId as String?,
      detailStates: detailStates ?? this.detailStates,
      dateKey: dateKey ?? this.dateKey,
    );
  }
}

const _sentinel = Object();
