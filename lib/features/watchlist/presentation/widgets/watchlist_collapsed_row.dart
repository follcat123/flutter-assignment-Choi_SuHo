import 'package:flutter/material.dart';

import '../../domain/models/watchlist_models.dart';
import '../../domain/services/watchlist_formatters.dart';
import '../layout/watchlist_layout_spec.dart';
import '../../../../theme/app_theme.dart';
import 'watchlist_logo.dart';

class WatchlistCollapsedRow extends StatelessWidget {
  const WatchlistCollapsedRow({
    required this.item,
    required this.sortMode,
    required this.layout,
    required this.onTap,
    super.key,
  });

  final WatchlistItem item;
  final WatchlistSortMode sortMode;
  final WatchlistLayoutSpec layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('watchlist-row-${item.id}'),
        onTap: onTap,
        child: SizedBox(
          height: WatchlistLayoutSpec.collapsedRowHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
            child: Row(
              children: [
                WatchlistLogo(item: item),
                SizedBox(width: layout.logoTitleGap),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.listName,
                  ),
                ),
                SizedBox(width: layout.titleMetricGap),
                _CollapsedMetricColumn(
                  item: item,
                  sortMode: sortMode,
                  width: layout.collapsedMetricWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedMetricColumn extends StatelessWidget {
  const _CollapsedMetricColumn({
    required this.item,
    required this.sortMode,
    required this.width,
  });

  final WatchlistItem item;
  final WatchlistSortMode sortMode;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _primaryValue,
            key: Key('watchlist-primary-${item.id}'),
            textAlign: TextAlign.end,
            style: AppTypography.listMetric,
          ),
          const SizedBox(height: 4),
          Text(
            formatChangeRate(item.changeRate),
            key: Key('watchlist-change-${item.id}'),
            textAlign: TextAlign.end,
            style: AppTypography.listMetric.copyWith(color: _changeColor),
          ),
        ],
      ),
    );
  }

  String get _primaryValue {
    switch (sortMode) {
      case WatchlistSortMode.price:
      case WatchlistSortMode.changeRate:
      case WatchlistSortMode.alphabetical:
      case WatchlistSortMode.marketCap:
        return formatPrice(item);
    }
  }

  Color get _changeColor {
    switch (item.direction) {
      case PriceChangeDirection.up:
        return AppColors.mainAndAccent.up_f93f62;
      case PriceChangeDirection.down:
        return AppColors.mainAndAccent.down_4780ff;
      case PriceChangeDirection.flat:
        return AppDerivedColors.flat;
    }
  }
}
