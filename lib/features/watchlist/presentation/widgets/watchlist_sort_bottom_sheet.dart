import 'package:flutter/material.dart';

import '../../domain/models/watchlist_models.dart';
import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';

class WatchlistSortBottomSheet extends StatelessWidget {
  const WatchlistSortBottomSheet({required this.currentSortMode, super.key});

  final WatchlistSortMode currentSortMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          key: const Key('watchlist-sort-sheet'),
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 36),
          decoration: BoxDecoration(
            color: AppColors.bg.bg_2_212121,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('정렬', style: AppTypography.sheetTitle),
                  ),
                ),
              ),
              for (final mode in WatchlistSortMode.values)
                _SortOptionRow(
                  mode: mode,
                  selected: mode == currentSortMode,
                  onTap: () => Navigator.of(context).pop(mode),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortOptionRow extends StatelessWidget {
  const _SortOptionRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final WatchlistSortMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('watchlist-sort-option-${mode.name}'),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  mode.label,
                  style: AppTypography.sheetOption.copyWith(
                    height: 18 / 14,
                    color: selected
                        ? AppColors.text.text_fafafa
                        : AppColors.text.text_2_bdbdbd,
                  ),
                ),
                const Spacer(),
                if (selected)
                  AppAssetSlotIcon(
                    assetPath: AppAssets.sortCheck,
                    slotWidth: 24,
                    slotHeight: 24,
                    assetWidth: AppAssetSizes.sortCheck.width,
                    assetHeight: AppAssetSizes.sortCheck.height,
                    color: AppColors.text.text_fafafa,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
