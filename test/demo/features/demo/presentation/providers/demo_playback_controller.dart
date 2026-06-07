import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/demo_models.dart';

final demoPlaybackControllerProvider =
    NotifierProvider<DemoPlaybackController, DemoPlaybackState>(
      DemoPlaybackController.new,
    );

class DemoPlaybackController extends Notifier<DemoPlaybackState> {
  @override
  DemoPlaybackState build() => const DemoPlaybackState();

  int get _stepCount => state.scenario.steps.length;

  void selectScenario(DemoScenarioId scenarioId) {
    state = DemoPlaybackState(scenarioId: scenarioId);
  }

  void play() {
    if (_stepCount == 0) {
      return;
    }

    if (state.isComplete) {
      state = DemoPlaybackState(
        scenarioId: state.scenarioId,
        isPlaying: true,
        commandId: state.commandId + 1,
      );
      return;
    }

    if (state.isPlaying) {
      return;
    }

    state = state.copyWith(isPlaying: true, commandId: state.commandId + 1);
  }

  void pause() {
    if (!state.isPlaying) {
      return;
    }
    state = state.copyWith(isPlaying: false);
  }

  void next() {
    if (state.isComplete) {
      return;
    }

    state = state.copyWith(isPlaying: false, commandId: state.commandId + 1);
  }

  void requestAutoplayStep() {
    if (!state.isPlaying || state.isComplete) {
      return;
    }

    state = state.copyWith(commandId: state.commandId + 1);
  }

  void markStepCompleted() {
    if (state.isComplete) {
      return;
    }

    final nextStepIndex = state.nextStepIndex + 1;
    state = state.copyWith(
      nextStepIndex: nextStepIndex,
      isPlaying: nextStepIndex >= _stepCount ? false : state.isPlaying,
    );
  }

  void restart({bool autoplay = false}) {
    state = DemoPlaybackState(
      scenarioId: state.scenarioId,
      isPlaying: autoplay,
      commandId: autoplay ? state.commandId + 1 : state.commandId,
    );
  }

  void restorePendingStep(int index) {
    final boundedIndex = index.clamp(0, _stepCount);
    state = state.copyWith(nextStepIndex: boundedIndex, isPlaying: false);
  }
}

@immutable
class DemoPlaybackState {
  const DemoPlaybackState({
    this.scenarioId = DemoScenarioId.searchSync,
    this.nextStepIndex = 0,
    this.isPlaying = false,
    this.commandId = 0,
  });

  final DemoScenarioId scenarioId;
  final int nextStepIndex;
  final bool isPlaying;
  final int commandId;

  DemoScenario get scenario => demoScenarios[scenarioId]!;

  bool get isComplete => nextStepIndex >= scenario.steps.length;

  int get totalSteps => scenario.steps.length;

  int get completedSteps => nextStepIndex.clamp(0, totalSteps);

  String get currentStepLabel {
    if (isComplete) {
      return '시나리오 완료';
    }
    return scenario.steps[nextStepIndex].label;
  }

  DemoPlaybackState copyWith({
    DemoScenarioId? scenarioId,
    int? nextStepIndex,
    bool? isPlaying,
    int? commandId,
  }) {
    return DemoPlaybackState(
      scenarioId: scenarioId ?? this.scenarioId,
      nextStepIndex: nextStepIndex ?? this.nextStepIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      commandId: commandId ?? this.commandId,
    );
  }
}
