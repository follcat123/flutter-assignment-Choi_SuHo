import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../watchlist/data/providers/watchlist_repository_provider.dart';
import '../../../watchlist/domain/models/watchlist_models.dart';
import '../../../watchlist/domain/repositories/watchlist_repository.dart';
import '../../../watchlist/presentation/providers/favorite_ids_controller.dart';

final searchControllerProvider =
    NotifierProvider<SearchController, SearchUiState>(SearchController.new);

class SearchController extends Notifier<SearchUiState> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  Timer? _toastTimer;
  int _requestSequence = 0;

  @override
  SearchUiState build() {
    ref.onDispose(() => _toastTimer?.cancel());
    // 즐겨찾기 상태가 바뀔 때마다 현재 검색 결과의 isFavorite를 다시 매핑한다.
    ref.listen(favoriteIdsControllerProvider, (previous, next) {
      _applyFavoriteIds(next.valueOrNull);
    });
    return const SearchUiState();
  }

  Future<void> setQuery(String query) async {
    _requestSequence += 1;
    final currentRequestId = _requestSequence;
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _toastTimer?.cancel();
      state = state.copyWith(
        query: query,
        results: const AsyncData(<StockSearchItem>[]),
        selectedItemId: null,
        toast: null,
      );
      return;
    }

    final existingResults = state.results;
    final loadingResults = existingResults.hasValue
        ? const AsyncLoading<List<StockSearchItem>>().copyWithPrevious(
            existingResults,
          )
        : const AsyncLoading<List<StockSearchItem>>();

    state = state.copyWith(
      query: query,
      results: loadingResults,
      selectedItemId: null,
      toast: null,
    );

    final result = await AsyncValue.guard(
      () => _repository.searchStocks(query: trimmedQuery),
    );
    if (currentRequestId != _requestSequence) {
      return;
    }

    // 검색 결과가 나왔을 때 현재 즐겨찾기 상태를 즉시 반영한다.
    final currentFavoriteIds = ref
        .read(favoriteIdsControllerProvider)
        .valueOrNull;
    final mappedResult = currentFavoriteIds != null && result.hasValue
        ? AsyncData(
            result.value!
                .map((item) => item.copyWith(
                      isFavorite: currentFavoriteIds.contains(item.id),
                    ))
                .toList(growable: false),
          )
        : result;

    state = state.copyWith(
      results: mappedResult,
      selectedItemId: null,
    );
  }

  void clearQuery() {
    _requestSequence += 1;
    _toastTimer?.cancel();
    state = state.copyWith(
      query: '',
      results: const AsyncData(<StockSearchItem>[]),
      selectedItemId: null,
      toast: null,
    );
  }

  void setFocused(bool isFocused) {
    if (state.isFocused == isFocused) {
      return;
    }
    state = state.copyWith(isFocused: isFocused);
  }

  void toggleSelection(StockSearchItem item) {
    state = state.copyWith(
      selectedItemId: state.selectedItemId == item.id ? null : item.id,
    );
  }

  void clearSelection() {
    if (state.selectedItemId == null) {
      return;
    }
    state = state.copyWith(selectedItemId: null);
  }

  Future<bool> toggleFavorite(StockSearchItem item) async {
    final isAdded = await ref
        .read(favoriteIdsControllerProvider.notifier)
        .toggle(item.id);

    // toggle 후 최신 즐겨찾기 상태를 검색 결과에 반영하고 토스트를 제어한다.
    final favoriteIds = ref.read(favoriteIdsControllerProvider).valueOrNull;
    _applyFavoriteIds(favoriteIds);

    if (isAdded) {
      _showToast(const SearchToastData(message: '관심그룹에 추가되었습니다.'));
    } else {
      dismissToast();
    }

    return isAdded;
  }

  void dismissToast() {
    _toastTimer?.cancel();
    if (state.toast == null) {
      return;
    }
    state = state.copyWith(toast: null);
  }

  void _showToast(SearchToastData toast) {
    _toastTimer?.cancel();
    state = state.copyWith(toast: toast);
    _toastTimer = Timer(const Duration(seconds: 2), dismissToast);
  }

  void _applyFavoriteIds(Set<String>? favoriteIds) {
    if (favoriteIds == null) {
      return;
    }

    final currentResults = state.results;
    if (!currentResults.hasValue) {
      return;
    }

    final updatedItems = currentResults.value!
        .map((item) => item.copyWith(isFavorite: favoriteIds.contains(item.id)))
        .toList(growable: false);

    // 선택된 항목이 여전히 결과에 있는지 확인
    final selectedItemId = state.selectedItemId;
    final selectedStillExists =
        selectedItemId == null ||
        updatedItems.any((item) => item.id == selectedItemId);

    state = state.copyWith(
      results: AsyncData(updatedItems),
      selectedItemId: selectedStillExists ? selectedItemId : null,
    );
  }
}

@immutable
class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.results = const AsyncData(<StockSearchItem>[]),
    this.selectedItemId,
    this.isFocused = false,
    this.toast,
  });

  final String query;
  final AsyncValue<List<StockSearchItem>> results;
  final String? selectedItemId;
  final bool isFocused;
  final SearchToastData? toast;

  SearchUiState copyWith({
    String? query,
    AsyncValue<List<StockSearchItem>>? results,
    Object? selectedItemId = _sentinel,
    bool? isFocused,
    Object? toast = _sentinel,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      results: results ?? this.results,
      selectedItemId: selectedItemId == _sentinel
          ? this.selectedItemId
          : selectedItemId as String?,
      isFocused: isFocused ?? this.isFocused,
      toast: toast == _sentinel ? this.toast : toast as SearchToastData?,
    );
  }
}

@immutable
class SearchToastData {
  const SearchToastData({required this.message});

  final String message;
}

const _sentinel = Object();
