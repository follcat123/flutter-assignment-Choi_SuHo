import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/watchlist_models.dart';
import '../../domain/services/watchlist_formatters.dart';
import '../../domain/services/watchlist_sorting.dart';
import '../../data/providers/watchlist_repository_provider.dart';
import '../layout/watchlist_layout_spec.dart';
import '../providers/favorite_ids_controller.dart';
import '../providers/watchlist_controller.dart';
import '../providers/watchlist_detail_controller.dart';
import '../widgets/watchlist_date_bottom_sheet.dart';
import '../widgets/watchlist_collapsed_row.dart';
import '../widgets/watchlist_expanded_row.dart';
import '../widgets/watchlist_sort_bottom_sheet.dart';
import '../widgets/watchlist_states.dart';
import '../widgets/watchlist_top_filter.dart';
import '../../../../theme/app_theme.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  late final AppLifecycleListener _appLifecycleListener;
  List<DateTime>? _availableDatesCache;
  Future<List<DateTime>>? _availableDatesFuture;

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(onResume: _handleResume);
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    super.dispose();
  }

  void _handleResume() {
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    _clearAvailableDatesCache();
    await ref.read(watchlistControllerProvider.notifier).refresh();
    await _syncSelectedDetailWithSnapshot();
  }

  void _clearAvailableDatesCache() {
    _availableDatesCache = null;
    _availableDatesFuture = null;
  }

  Future<List<DateTime>> _loadAvailableDates() {
    final cached = _availableDatesCache;
    if (cached != null) {
      return Future<List<DateTime>>.value(cached);
    }

    return _availableDatesFuture ??= ref
        .read(watchlistRepositoryProvider)
        .fetchAvailableDates()
        .then((dates) {
          _availableDatesCache = dates;
          return dates;
        });
  }

  Future<void> _syncSelectedDetailWithSnapshot() async {
    final snapshot = ref.read(watchlistControllerProvider).valueOrNull;
    final detailController = ref.read(
      watchlistDetailControllerProvider.notifier,
    );

    if (snapshot == null) {
      detailController.clearAll();
      return;
    }

    await detailController.invalidateCacheAndReselect(snapshot.items);
  }

  Future<void> _showSortBottomSheet(WatchlistSortMode currentSortMode) async {
    final selectedMode = await showModalBottomSheet<WatchlistSortMode>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppDerivedColors.modalScrim,
      builder: (context) {
        return WatchlistSortBottomSheet(currentSortMode: currentSortMode);
      },
    );

    if (selectedMode == null || !mounted) {
      return;
    }

    ref.read(watchlistSortModeProvider.notifier).state = selectedMode;
  }

  Future<void> _showDateBottomSheet(WatchlistSnapshot snapshot) async {
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppDerivedColors.modalScrim,
      builder: (context) {
        return _LazyWatchlistDateBottomSheet(
          loadAvailableDates: _loadAvailableDates,
          initialDate: snapshot.asOf,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final normalizedDate = normalizeAsOfDate(selectedDate);
    if (formatApiDate(normalizedDate) == formatApiDate(snapshot.asOf)) {
      return;
    }

    // 선택한 거래일을 watchlist 컨트롤러에 적용하고 상세 패널도 함께 갱신한다.
    await ref.read(watchlistControllerProvider.notifier).setAsOf(normalizedDate);
    await _syncSelectedDetailWithSnapshot();
  }

  Future<void> _handleActionTap(WatchlistItem item, String action) async {
    if (action == '삭제') {
      await ref.read(favoriteIdsControllerProvider.notifier).remove(item.id);
      _clearAvailableDatesCache();
      await ref.read(watchlistControllerProvider.notifier).refresh();
      await _syncSelectedDetailWithSnapshot();
      if (!mounted) {
        return;
      }
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$action 기능은 준비 중입니다. ${item.name}에 연결될 예정입니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<WatchlistSnapshot>>(watchlistControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        unawaited(_syncSelectedDetailWithSnapshot());
      }
    });

    final snapshotAsync = ref.watch(watchlistControllerProvider);
    final sortMode = ref.watch(watchlistSortModeProvider);
    final detailUiState = ref.watch(watchlistDetailControllerProvider);
    final snapshot = snapshotAsync.valueOrNull;
    final items = snapshot == null
        ? const <WatchlistItem>[]
        : sortWatchlistItems(snapshot.items, sortMode);
    final selectedItemId = detailUiState.selectedItemId;

    return ColoredBox(
      color: AppColors.bg.bg_121212,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = WatchlistLayoutSpec.fromWidth(constraints.maxWidth);

            return Column(
              key: const Key('watchlist-screen'),
              children: [
                _WatchlistHeader(layout: layout),
                const SizedBox(height: WatchlistLayoutSpec.headerToFilterGap),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                  ),
                  child: WatchlistTopFilter(
                    currentSortMode: sortMode,
                    asOfLabel: snapshot == null
                        ? '--.--.--'
                        : formatAsOfDate(snapshot.asOf),
                    enabled: snapshot != null,
                    onSortTap: () => _showSortBottomSheet(sortMode),
                    onDateTap: snapshot == null
                        ? () {}
                        : () => _showDateBottomSheet(snapshot),
                  ),
                ),
                const SizedBox(height: WatchlistLayoutSpec.filterToListGap),
                Expanded(
                  child: snapshotAsync.when(
                    data: (data) {
                      if (data.items.isEmpty) {
                        return WatchlistEmptyState(onRefresh: _refresh);
                      }

                      return RefreshIndicator.adaptive(
                        color: AppColors.mainAndAccent.primary_ff8a00,
                        backgroundColor: AppColors.bg.bg_2_212121,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          key: const Key('watchlist-list'),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = item.id == selectedItemId;
                            final detailState = detailUiState.detailFor(
                              item.id,
                            );
                            final detailController = ref.read(
                              watchlistDetailControllerProvider.notifier,
                            );

                            if (isSelected) {
                              return WatchlistExpandedRow(
                                item: item,
                                detailState: detailState,
                                layout: layout,
                                onHeaderTap: () {
                                  unawaited(
                                    detailController.toggleSelection(item),
                                  );
                                },
                                onRetry: () {
                                  unawaited(
                                    detailController.fetchDetail(
                                      item,
                                      force: true,
                                    ),
                                  );
                                },
                                onActionTap: (action) {
                                  unawaited(_handleActionTap(item, action));
                                },
                              );
                            }

                            return WatchlistCollapsedRow(
                              item: item,
                              sortMode: sortMode,
                              layout: layout,
                              onTap: () {
                                unawaited(
                                  detailController.toggleSelection(item),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: WatchlistSkeleton.new,
                    error: (error, stackTrace) {
                      return WatchlistErrorState(onRetry: _refresh);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LazyWatchlistDateBottomSheet extends StatefulWidget {
  const _LazyWatchlistDateBottomSheet({
    required this.loadAvailableDates,
    required this.initialDate,
  });

  final Future<List<DateTime>> Function() loadAvailableDates;
  final DateTime initialDate;

  @override
  State<_LazyWatchlistDateBottomSheet> createState() =>
      _LazyWatchlistDateBottomSheetState();
}

class _LazyWatchlistDateBottomSheetState
    extends State<_LazyWatchlistDateBottomSheet> {
  late Future<List<DateTime>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadAvailableDates();
  }

  void _retry() {
    setState(() {
      _future = widget.loadAvailableDates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DateTime>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DateBottomSheetLoading();
        }

        if (snapshot.hasError) {
          return _DateBottomSheetError(onRetry: _retry);
        }

        final availableDates = snapshot.data;
        return WatchlistDateBottomSheet(
          availableDates: availableDates == null || availableDates.isEmpty
              ? [widget.initialDate]
              : availableDates,
          initialDate: widget.initialDate,
        );
      },
    );
  }
}

class _DateBottomSheetLoading extends StatelessWidget {
  const _DateBottomSheetLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg.bg_2_212121,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.mainAndAccent.primary_ff8a00,
            ),
            const SizedBox(height: 16),
            Text('거래일 목록을 불러오는 중입니다.', style: AppTypography.searchMeta),
          ],
        ),
      ),
    );
  }
}

class _DateBottomSheetError extends StatelessWidget {
  const _DateBottomSheetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg.bg_2_212121,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '거래일 목록을 불러오지 못했습니다.',
              style: AppTypography.searchEmptyTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '잠시 후 다시 시도해 주세요.',
              style: AppTypography.searchMeta.copyWith(
                color: AppColors.text.text_3_9e9e9e,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainAndAccent.primary_ff8a00,
                ),
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  const _WatchlistHeader({required this.layout});

  final WatchlistLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WatchlistLayoutSpec.headerHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.border_333333),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: layout.horizontalPadding),
            child: Text(
              '관심',
              key: const Key('watchlist-header-title'),
              style: AppTypography.header,
            ),
          ),
        ),
      ),
    );
  }
}
