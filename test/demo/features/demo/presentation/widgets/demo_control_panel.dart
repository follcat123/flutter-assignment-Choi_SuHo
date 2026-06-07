import 'package:flutter/material.dart';

import 'package:sample/theme/app_theme.dart';
import '../models/demo_models.dart';
import '../providers/demo_playback_controller.dart';

class DemoControlPanel extends StatelessWidget {
  const DemoControlPanel({
    required this.state,
    required this.onScenarioSelected,
    required this.onPlay,
    required this.onPause,
    required this.onPrevious,
    required this.onNext,
    required this.onRestart,
    super.key,
  });

  final DemoPlaybackState state;
  final ValueChanged<DemoScenarioId> onScenarioSelected;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('demo-control-panel'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.bg.bg_2_212121.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.border_333333),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bg.bg_4_333333,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DemoScenarioId>(
                          key: const Key('demo-scenario-select'),
                          value: state.scenarioId,
                          dropdownColor: AppColors.bg.bg_2_212121,
                          iconEnabledColor: AppColors.text.text_fafafa,
                          style: AppTypography.filter,
                          items: demoScenarios.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) {
                              onScenarioSelected(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _DemoIconButton(
                  buttonKey: const Key('demo-play'),
                  icon: Icons.play_arrow_rounded,
                  onTap: onPlay,
                ),
                const SizedBox(width: 6),
                _DemoIconButton(
                  buttonKey: const Key('demo-pause'),
                  icon: Icons.pause_rounded,
                  onTap: onPause,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${state.completedSteps}/${state.totalSteps}',
              key: const Key('demo-progress'),
              style: AppTypography.sheetOption.copyWith(
                color: AppColors.text.text_3_9e9e9e,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              state.currentStepLabel,
              key: const Key('demo-current-step'),
              style: AppTypography.filter.copyWith(
                color: AppColors.text.text_fafafa,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DemoTextButton(
                    buttonKey: const Key('demo-previous'),
                    label: '이전',
                    onTap: onPrevious,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DemoTextButton(
                    buttonKey: const Key('demo-next'),
                    label: '다음',
                    onTap: onNext,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DemoTextButton(
                    buttonKey: const Key('demo-restart'),
                    label: '재시작',
                    onTap: onRestart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoIconButton extends StatelessWidget {
  const _DemoIconButton({
    required this.buttonKey,
    required this.icon,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.bg.bg_4_333333,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: buttonKey,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, size: 20, color: AppColors.text.text_fafafa),
        ),
      ),
    );
  }
}

class _DemoTextButton extends StatelessWidget {
  const _DemoTextButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextButton(
        key: buttonKey,
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.bg.bg_4_333333,
          foregroundColor: AppColors.text.text_fafafa,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: AppTypography.action),
      ),
    );
  }
}
