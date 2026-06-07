import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sample/features/root/presentation/widgets/app_bottom_nav.dart';
import 'package:sample/features/search/presentation/providers/search_controller.dart';
import 'package:sample/features/search/presentation/screens/search_screen.dart';
import 'package:sample/features/watchlist/data/providers/watchlist_repository_provider.dart';
import 'package:sample/features/watchlist/domain/models/watchlist_models.dart';
import 'package:sample/features/watchlist/domain/services/watchlist_sorting.dart';
import 'package:sample/features/watchlist/presentation/providers/favorite_ids_controller.dart';
import 'package:sample/features/watchlist/presentation/providers/watchlist_controller.dart';
import 'package:sample/features/watchlist/presentation/providers/watchlist_detail_controller.dart';
import 'package:sample/features/watchlist/presentation/screens/watchlist_screen.dart';
import 'package:sample/features/watchlist/presentation/widgets/watchlist_date_bottom_sheet.dart';
import 'package:sample/theme/app_theme.dart';

import '../../data/repositories/demo_watchlist_repository.dart';
import '../models/demo_models.dart';
import '../providers/demo_playback_controller.dart';
import '../widgets/demo_control_panel.dart';

class DemoShell extends ConsumerStatefulWidget {
  const DemoShell({super.key, this.stepDelayFactor = 1});

  final double stepDelayFactor;

  @override
  ConsumerState<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends ConsumerState<DemoShell> {
  late final ProviderSubscription<DemoPlaybackState> _playbackSubscription;

  AppTab _currentTab = AppTab.watchlist;
  bool _isHandlingCommand = false;
  bool _rerunCommand = false;
  int _lastHandledCommandId = -1;
  int _commandEpoch = 0;

  WatchlistSnapshot? _demoDateSheetSnapshot;
  List<DateTime>? _demoAvailableDates;
  WatchlistDateBottomSheetController? _dateSheetController;
  Completer<void>? _dateSheetCompletion;

  @override
  void initState() {
    super.initState();
    _playbackSubscription = ref.listenManual<DemoPlaybackState>(
      demoPlaybackControllerProvider,
      (previous, next) {
        if (previous?.commandId != next.commandId) {
          unawaited(_handlePendingCommand(next.commandId));
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resetScenario(DemoScenarioId.searchSync));
    });
  }

  @override
  void dispose() {
    _playbackSubscription.close();
    super.dispose();
  }

  Future<void> _handlePendingCommand(int commandId) async {
    if (_isHandlingCommand) {
      _rerunCommand = true;
      return;
    }

    final state = ref.read(demoPlaybackControllerProvider);
    if (commandId == _lastHandledCommandId || state.isComplete) {
      return;
    }

    _isHandlingCommand = true;
    _lastHandledCommandId = commandId;
    final commandEpoch = _commandEpoch;

    try {
      final currentState = ref.read(demoPlaybackControllerProvider);
      if (currentState.isComplete) {
        return;
      }

      final step = currentState.scenario.steps[currentState.nextStepIndex];
      await _executeStepAction(step.action);
      if (!mounted || commandEpoch != _commandEpoch) {
        return;
      }

      ref.read(demoPlaybackControllerProvider.notifier).markStepCompleted();

      final updatedState = ref.read(demoPlaybackControllerProvider);
      if (!updatedState.isPlaying) {
        return;
      }

      final delay = _scaleDelay(step.delay);
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      } else {
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted || commandEpoch != _commandEpoch) {
        return;
      }

      ref.read(demoPlaybackControllerProvider.notifier).requestAutoplayStep();
    } finally {
      _isHandlingCommand = false;
      if (_rerunCommand) {
        _rerunCommand = false;
        unawaited(
          _handlePendingCommand(
            ref.read(demoPlaybackControllerProvider).commandId,
          ),
        );
      }
    }
  }

  Duration _scaleDelay(Duration baseDelay) {
    final factor = widget.stepDelayFactor;
    if (factor <= 0) {
      return Duration.zero;
    }
    return Duration(microseconds: (baseDelay.inMicroseconds * factor).round());
  }

  Future<void> _selectScenario(DemoScenarioId scenarioId) async {
    ref.read(demoPlaybackControllerProvider.notifier).pause();
    await _resetScenario(scenarioId);
    ref
        .read(demoPlaybackControllerProvider.notifier)
        .selectScenario(scenarioId);
  }

  Future<void> _restartScenario() async {
    final playbackState = ref.read(demoPlaybackControllerProvider);
    ref.read(demoPlaybackControllerProvider.notifier).pause();
    await _resetScenario(playbackState.scenarioId);
    ref.read(demoPlaybackControllerProvider.notifier).restart();
  }

  Future<void> _restartAndPlay() async {
    final playbackState = ref.read(demoPlaybackControllerProvider);
    await _resetScenario(playbackState.scenarioId);
    ref.read(demoPlaybackControllerProvider.notifier).restart(autoplay: true);
  }

  Future<void> _goToPreviousStep() async {
    final playbackState = ref.read(demoPlaybackControllerProvider);
    if (playbackState.nextStepIndex == 0) {
      return;
    }

    final targetPendingStep = playbackState.nextStepIndex - 1;
    ref.read(demoPlaybackControllerProvider.notifier).pause();
    await _resetScenario(playbackState.scenarioId);
    await _replayStepsUntil(
      scenario: playbackState.scenario,
      pendingStepIndex: targetPendingStep,
    );
    ref
        .read(demoPlaybackControllerProvider.notifier)
        .restorePendingStep(targetPendingStep);
  }

  Future<void> _replayStepsUntil({
    required DemoScenario scenario,
    required int pendingStepIndex,
  }) async {
    for (var index = 0; index < pendingStepIndex; index += 1) {
      await _executeStepAction(scenario.steps[index].action);
    }
  }

  Future<void> _resetScenario(DemoScenarioId scenarioId) async {
    _commandEpoch += 1;
    _rerunCommand = false;
    await _dismissDateSheetIfNeeded();
    ref.read(demoWatchlistRepositoryProvider).reset();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentTab = AppTab.watchlist;
    });

    ref.invalidate(favoriteIdsControllerProvider);
    ref.invalidate(searchControllerProvider);
    ref.invalidate(watchlistSortModeProvider);
    ref.invalidate(watchlistSelectedDateProvider);
    ref.invalidate(watchlistDetailControllerProvider);
    ref.invalidate(watchlistControllerProvider);

    await ref.read(favoriteIdsControllerProvider.future);
    await ref.read(watchlistControllerProvider.future);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _executeStepAction(DemoStepAction action) async {
    switch (action.type) {
      case DemoStepActionType.setTab:
        final tab = action.tab == DemoTargetTab.search
            ? AppTab.search
            : AppTab.watchlist;
        if (mounted) {
          setState(() {
            _currentTab = tab;
          });
        }
        await Future<void>.delayed(Duration.zero);
        break;
      case DemoStepActionType.setSearchQuery:
        await ref
            .read(searchControllerProvider.notifier)
            .setQuery(action.query ?? '');
        break;
      case DemoStepActionType.toggleSearchFavorite:
        final item = _findSearchItem(action.itemId);
        if (item == null) {
          return;
        }
        await ref.read(searchControllerProvider.notifier).toggleFavorite(item);
        await ref.read(watchlistControllerProvider.notifier).refresh();
        break;
      case DemoStepActionType.openWatchlistDetail:
        final item = _findWatchlistItem(action.itemId);
        if (item == null) {
          return;
        }
        await ref
            .read(watchlistDetailControllerProvider.notifier)
            .toggleSelection(item);
        break;
      case DemoStepActionType.deleteFavorite:
        final itemId = action.itemId;
        if (itemId == null) {
          return;
        }
        await ref.read(favoriteIdsControllerProvider.notifier).remove(itemId);
        await ref.read(watchlistControllerProvider.notifier).refresh();
        await _syncSelectedDetailWithSnapshot();
        break;
      case DemoStepActionType.showDateSheet:
        await _showDemoDateSheet();
        break;
      case DemoStepActionType.applyDateSelection:
        final date = action.date;
        if (date == null) {
          return;
        }
        await _applyDateSelection(date);
        break;
      case DemoStepActionType.armNextSamsungDetailFailure:
        ref.read(demoWatchlistRepositoryProvider).armNextSamsungDetailFailure();
        final item = _findWatchlistItem('samsung');
        if (item == null) {
          return;
        }
        await ref
            .read(watchlistDetailControllerProvider.notifier)
            .fetchDetail(item, force: true);
        break;
      case DemoStepActionType.retrySelectedDetail:
        final item = _findSelectedDetailItem();
        if (item == null) {
          return;
        }
        await ref
            .read(watchlistDetailControllerProvider.notifier)
            .fetchDetail(item, force: true);
        break;
      case DemoStepActionType.noop:
        await Future<void>.delayed(Duration.zero);
        break;
    }
  }

  StockSearchItem? _findSearchItem(String? itemId) {
    final results = ref.read(searchControllerProvider).results.valueOrNull;
    if (results == null || itemId == null) {
      return null;
    }

    for (final item in results) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  WatchlistItem? _findWatchlistItem(String? itemId) {
    final snapshot = ref.read(watchlistControllerProvider).valueOrNull;
    if (snapshot == null || itemId == null) {
      return null;
    }

    for (final item in snapshot.items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  WatchlistItem? _findSelectedDetailItem() {
    final detailState = ref.read(watchlistDetailControllerProvider);
    return _findWatchlistItem(detailState.selectedItemId);
  }

  Future<void> _showDemoDateSheet() async {
    final snapshot = ref.read(watchlistControllerProvider).valueOrNull;
    if (snapshot == null || _dateSheetController != null) {
      return;
    }

    final availableDates = await ref
        .read(watchlistRepositoryProvider)
        .fetchAvailableDates();

    final controller = WatchlistDateBottomSheetController();
    final completion = Completer<void>();
    if (!mounted) {
      return;
    }

    setState(() {
      _demoDateSheetSnapshot = snapshot;
      _demoAvailableDates = availableDates;
      _dateSheetController = controller;
      _dateSheetCompletion = completion;
    });
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _applyDateSelection(DateTime date) async {
    final controller = _dateSheetController;
    if (controller == null) {
      return;
    }

    controller.selectDate(date);
    final settleDelay = _scaleDelay(const Duration(milliseconds: 220));
    if (settleDelay > Duration.zero) {
      await Future<void>.delayed(settleDelay);
    }
    controller.confirm();
    await _dateSheetCompletion?.future;
  }

  Future<void> _dismissDateSheetIfNeeded() async {
    final controller = _dateSheetController;
    final completion = _dateSheetCompletion;
    if (controller == null || completion == null) {
      return;
    }
    controller.dismiss();
    await completion.future;
  }

  Future<void> _handleDemoDateSubmitted(DateTime selectedDate) async {
    final completion = _dateSheetCompletion;
    if (mounted) {
      setState(() {
        _demoDateSheetSnapshot = null;
        _demoAvailableDates = null;
        _dateSheetController = null;
      });
    }

    await ref
        .read(watchlistControllerProvider.notifier)
        .setAsOf(normalizeAsOfDate(selectedDate));
    await _syncSelectedDetailWithSnapshot();

    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _dateSheetCompletion = null;
  }

  void _handleDemoDateCancelled() {
    final completion = _dateSheetCompletion;
    if (mounted) {
      setState(() {
        _demoDateSheetSnapshot = null;
        _demoAvailableDates = null;
        _dateSheetController = null;
      });
    }

    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _dateSheetCompletion = null;
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

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(demoPlaybackControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.bg.bg_2_212121,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg.bg_121212,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: DemoControlPanel(
                  state: playbackState,
                  onScenarioSelected: (scenarioId) {
                    unawaited(_selectScenario(scenarioId));
                  },
                  onPlay: () {
                    if (playbackState.isComplete) {
                      unawaited(_restartAndPlay());
                      return;
                    }
                    ref.read(demoPlaybackControllerProvider.notifier).play();
                  },
                  onPause: () {
                    ref.read(demoPlaybackControllerProvider.notifier).pause();
                  },
                  onPrevious: () {
                    unawaited(_goToPreviousStep());
                  },
                  onNext: () {
                    ref.read(demoPlaybackControllerProvider.notifier).next();
                  },
                  onRestart: () {
                    unawaited(_restartScenario());
                  },
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: IndexedStack(
                      index: _currentTab.index,
                      children: const [
                        WatchlistScreen(),
                        _PlaceholderScreen(label: '종목토론'),
                        SearchScreen(),
                        _PlaceholderScreen(label: '뉴스'),
                        _PlaceholderScreen(label: '설정'),
                      ],
                    ),
                  ),
                  if (_demoDateSheetSnapshot case final sheetSnapshot?) ...[
                    Positioned.fill(
                      child: ColoredBox(color: AppDerivedColors.modalScrim),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: WatchlistDateBottomSheet(
                        availableDates:
                            _demoAvailableDates == null ||
                                _demoAvailableDates!.isEmpty
                            ? [sheetSnapshot.asOf]
                            : _demoAvailableDates!,
                        initialDate: sheetSnapshot.asOf,
                        controller: _dateSheetController,
                        onSubmitted: (selectedDate) {
                          unawaited(_handleDemoDateSubmitted(selectedDate));
                        },
                        onCancelled: _handleDemoDateCancelled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentTab: _currentTab,
          onTabSelected: (tab) {
            setState(() {
              _currentTab = tab;
            });
          },
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg.bg_121212,
      child: Center(
        child: Text(
          '$label 화면은 준비 중입니다.',
          style: AppTypography.searchEmptyTitle,
        ),
      ),
    );
  }
}
