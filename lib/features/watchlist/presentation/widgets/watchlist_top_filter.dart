import 'package:flutter/material.dart';

import '../../domain/models/watchlist_models.dart';
import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';

class WatchlistTopFilter extends StatelessWidget {
  const WatchlistTopFilter({
    required this.currentSortMode,
    required this.asOfLabel,
    required this.enabled,
    required this.onSortTap,
    required this.onDateTap,
    super.key,
  });

  final WatchlistSortMode currentSortMode;
  final String asOfLabel;
  final bool enabled;
  final VoidCallback onSortTap;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          _FilterTrigger(
            key: const Key('watchlist-sort-trigger'),
            label: currentSortMode.label,
            enabled: enabled,
            onTap: onSortTap,
            trailing: AppAssetSlotIcon(
              assetPath: AppAssets.sortFilter,
              slotWidth: 16,
              slotHeight: 16,
              assetWidth: AppAssetSizes.sortFilter.width,
              assetHeight: AppAssetSizes.sortFilter.height,
              color: AppColors.text.text_5_e0e0e0,
            ),
          ),
          const Spacer(),
          _FilterTrigger(
            key: const Key('watchlist-date-trigger'),
            label: asOfLabel,
            enabled: enabled,
            onTap: onDateTap,
            textStyle: tabularTextStyle(AppTypography.date),
          ),
        ],
      ),
    );
  }
}

class _FilterTrigger extends StatelessWidget {
  const _FilterTrigger({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.textStyle,
    this.trailing,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedTextStyle = textStyle ?? AppTypography.filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                key: ValueKey<String>('filter-label-$label'),
                style: resolvedTextStyle.copyWith(
                  color: enabled
                      ? resolvedTextStyle.color
                      : (resolvedTextStyle.color ??
                                AppColors.text.text_2_bdbdbd)
                            .withValues(alpha: 0.6),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 2), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
