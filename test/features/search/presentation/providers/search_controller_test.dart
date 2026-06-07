import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/search/presentation/providers/search_controller.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:sample/features/watchlist/presentation/providers/favorite_ids_controller.dart';

void main() {
  ProviderContainer createContainer({Set<String>? initialFavoriteIds}) {
    final container = ProviderContainer(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(
          _SearchControllerAssignmentRepository(
            initialFavoriteIds: initialFavoriteIds ?? const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> searchForSk(ProviderContainer container) async {
    await container.read(favoriteIdsControllerProvider.future);
    await container.read(searchControllerProvider.notifier).setQuery('sk');
  }

  StockSearchItem findSearchItem(ProviderContainer container, String itemId) {
    final items = container.read(searchControllerProvider).results.requireValue;
    return items.firstWhere((item) => item.id == itemId);
  }

  test(
    'assignment: setQuery applies initial favorite ids from provider state',
    () async {
      final container = createContainer(initialFavoriteIds: {'sk'});

      await searchForSk(container);

      expect(
        findSearchItem(container, 'sk').isFavorite,
        isTrue,
        reason:
            'TODO(assignment): setQuery()에서 favoriteIdsControllerProvider의 '
            '현재 값을 읽어 초기 검색 결과의 isFavorite를 동기화하세요.',
      );
    },
  );

  test(
    'assignment: search results update when favorite provider state changes',
    () async {
      final container = createContainer(initialFavoriteIds: {});

      await searchForSk(container);
      expect(findSearchItem(container, 'sk').isFavorite, isFalse);

      await container.read(favoriteIdsControllerProvider.notifier).add('sk');

      expect(
        findSearchItem(container, 'sk').isFavorite,
        isTrue,
        reason:
            'TODO(assignment): build()에서 ref.listen(...)을 연결해 favorite '
            '상태가 바뀌면 현재 검색 결과도 다시 그리세요.',
      );
    },
  );

  test(
    'assignment: toggleFavorite syncs current results and toast state',
    () async {
      final container = createContainer(initialFavoriteIds: {});

      await searchForSk(container);
      final controller = container.read(searchControllerProvider.notifier);
      final item = findSearchItem(container, 'sk');

      final added = await controller.toggleFavorite(item);
      expect(added, isTrue);
      expect(
        findSearchItem(container, 'sk').isFavorite,
        isTrue,
        reason:
            'TODO(assignment): toggleFavorite() 이후 최신 favorite 상태를 '
            '현재 검색 결과에 다시 반영하세요.',
      );
      expect(
        container.read(searchControllerProvider).toast?.message,
        '관심그룹에 추가되었습니다.',
        reason: 'TODO(assignment): favorite 추가 시 SearchToastData를 설정하세요.',
      );

      final removed = await controller.toggleFavorite(item);
      expect(removed, isFalse);
      expect(
        container.read(searchControllerProvider).toast,
        isNull,
        reason: 'TODO(assignment): favorite 제거 시 dismissToast()를 호출하세요.',
      );
    },
  );
}

class _SearchControllerAssignmentRepository implements WatchlistRepository {
  _SearchControllerAssignmentRepository({
    required Set<String> initialFavoriteIds,
  }) : _favoriteIds = {...initialFavoriteIds};

  final Set<String> _favoriteIds;

  @override
  Future<void> addFavorite({required String itemId}) async {
    _favoriteIds.add(itemId);
  }

  @override
  Future<List<DateTime>> fetchAvailableDates() async => const <DateTime>[];

  @override
  Future<WatchlistDetail> fetchWatchlistDetail({
    required String symbol,
    required MarketType market,
    DateTime? asOf,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<WatchlistSnapshot> fetchWatchlist({DateTime? asOf}) async {
    throw UnimplementedError();
  }

  @override
  Future<Set<String>> loadFavoriteIds() async {
    return Set<String>.unmodifiable(_favoriteIds);
  }

  @override
  Future<void> removeFavorite({required String itemId}) async {
    _favoriteIds.remove(itemId);
  }

  @override
  Future<List<StockSearchItem>> searchStocks({required String query}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <StockSearchItem>[];
    }

    return const <StockSearchItem>[
      StockSearchItem(
        id: 'sk',
        market: MarketType.domestic,
        marketLabel: 'KOSPI',
        symbol: '034730',
        name: 'SK',
        isFavorite: false,
      ),
    ];
  }
}
