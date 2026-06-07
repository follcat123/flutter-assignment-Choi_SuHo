import 'package:flutter/foundation.dart';

enum DemoScenarioId { searchSync, watchlistDetail }

enum DemoTargetTab { watchlist, search }

enum DemoStepActionType {
  setTab,
  setSearchQuery,
  toggleSearchFavorite,
  openWatchlistDetail,
  deleteFavorite,
  showDateSheet,
  applyDateSelection,
  armNextSamsungDetailFailure,
  retrySelectedDetail,
  noop,
}

@immutable
class DemoStepAction {
  const DemoStepAction._({
    required this.type,
    this.tab,
    this.query,
    this.itemId,
    this.date,
  });

  const DemoStepAction.setTab(DemoTargetTab tab)
    : this._(type: DemoStepActionType.setTab, tab: tab);

  const DemoStepAction.setSearchQuery(String query)
    : this._(type: DemoStepActionType.setSearchQuery, query: query);

  const DemoStepAction.toggleSearchFavorite(String itemId)
    : this._(type: DemoStepActionType.toggleSearchFavorite, itemId: itemId);

  const DemoStepAction.openWatchlistDetail(String itemId)
    : this._(type: DemoStepActionType.openWatchlistDetail, itemId: itemId);

  const DemoStepAction.deleteFavorite(String itemId)
    : this._(type: DemoStepActionType.deleteFavorite, itemId: itemId);

  const DemoStepAction.showDateSheet()
    : this._(type: DemoStepActionType.showDateSheet);

  const DemoStepAction.applyDateSelection(DateTime date)
    : this._(type: DemoStepActionType.applyDateSelection, date: date);

  const DemoStepAction.armNextSamsungDetailFailure()
    : this._(type: DemoStepActionType.armNextSamsungDetailFailure);

  const DemoStepAction.retrySelectedDetail()
    : this._(type: DemoStepActionType.retrySelectedDetail);

  const DemoStepAction.noop() : this._(type: DemoStepActionType.noop);

  final DemoStepActionType type;
  final DemoTargetTab? tab;
  final String? query;
  final String? itemId;
  final DateTime? date;
}

@immutable
class DemoStep {
  const DemoStep({
    required this.label,
    required this.action,
    this.delay = const Duration(milliseconds: 1200),
  });

  final String label;
  final DemoStepAction action;
  final Duration delay;
}

@immutable
class DemoScenario {
  const DemoScenario({
    required this.id,
    required this.label,
    required this.steps,
  });

  final DemoScenarioId id;
  final String label;
  final List<DemoStep> steps;
}

final Map<DemoScenarioId, DemoScenario> demoScenarios = {
  DemoScenarioId.searchSync: DemoScenario(
    id: DemoScenarioId.searchSync,
    label: '검색 동기화 데모',
    steps: const [
      DemoStep(
        label: '검색 탭 이동',
        action: DemoStepAction.setTab(DemoTargetTab.search),
      ),
      DemoStep(label: '검색어 입력', action: DemoStepAction.setSearchQuery('sk')),
      DemoStep(
        label: '관심 추가',
        action: DemoStepAction.toggleSearchFavorite('sk'),
      ),
      DemoStep(
        label: '관심 탭 이동',
        action: DemoStepAction.setTab(DemoTargetTab.watchlist),
      ),
      DemoStep(
        label: '상세 열기',
        action: DemoStepAction.openWatchlistDetail('sk'),
      ),
      DemoStep(label: '삭제', action: DemoStepAction.deleteFavorite('sk')),
      DemoStep(
        label: '검색 탭 복귀 및 하트 해제 확인',
        action: DemoStepAction.setTab(DemoTargetTab.search),
      ),
    ],
  ),
  DemoScenarioId.watchlistDetail: DemoScenario(
    id: DemoScenarioId.watchlistDetail,
    label: '관심 상세 데모',
    steps: [
      const DemoStep(
        label: '삼성전자 상세 열기',
        action: DemoStepAction.openWatchlistDetail('samsung'),
      ),
      const DemoStep(label: '날짜 시트 열기', action: DemoStepAction.showDateSheet()),
      DemoStep(
        label: '날짜 변경',
        action: DemoStepAction.applyDateSelection(DateTime(2024, 2, 14)),
      ),
      const DemoStep(label: '상세 갱신 확인', action: DemoStepAction.noop()),
      const DemoStep(
        label: '에러 시나리오로 전환',
        action: DemoStepAction.armNextSamsungDetailFailure(),
      ),
      const DemoStep(
        label: '재시도 성공 확인',
        action: DemoStepAction.retrySelectedDetail(),
      ),
    ],
  ),
};
