import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/watchlist_models.dart';
import '../../domain/services/watchlist_formatters.dart';
import '../layout/watchlist_layout_spec.dart';
import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import 'watchlist_action_bar.dart';
import 'watchlist_candlestick_chart.dart';
import 'watchlist_logo.dart';

class WatchlistExpandedRow extends StatelessWidget {
  const WatchlistExpandedRow({
    required this.item,
    required this.detailState,
    required this.layout,
    required this.onHeaderTap,
    required this.onRetry,
    required this.onActionTap,
    super.key,
  });

  final WatchlistItem item;
  final AsyncValue<WatchlistDetail>? detailState;
  final WatchlistLayoutSpec layout;
  final VoidCallback onHeaderTap;
  final VoidCallback onRetry;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WatchlistLayoutSpec.expandedRowHeight,
      child: Column(
        children: [
          SizedBox(
            height: WatchlistLayoutSpec.collapsedRowHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('watchlist-row-${item.id}'),
                onTap: onHeaderTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                    vertical: WatchlistLayoutSpec.topSectionVerticalPadding,
                  ),
                  child: Row(
                    children: [
                      WatchlistLogo(item: item),
                      SizedBox(width: layout.logoTitleGap),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.listName,
                        ),
                      ),
                      SizedBox(width: layout.chartMetricGap),
                      _ExpandedMetricColumn(
                        detailState: detailState,
                        item: item,
                        width: layout.expandedHeaderMetricWidth,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ExpandedBody(
            item: item,
            detailState: detailState,
            layout: layout,
            onRetry: onRetry,
            onActionTap: onActionTap,
          ),
        ],
      ),
    );
  }
}

class _ExpandedMetricColumn extends StatelessWidget {
  const _ExpandedMetricColumn({
    required this.detailState,
    required this.item,
    required this.width,
  });

  final AsyncValue<WatchlistDetail>? detailState;
  final WatchlistItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final detail = detailState?.valueOrNull;
    if (detail == null) {
      return _FallbackExpandedMetric(item: item, width: width);
    }

    final direction = detail.direction;
    final color = _directionColor(direction);

    return SizedBox(
      width: width,
      height: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatDetailPrice(detail),
                key: Key('watchlist-primary-${item.id}'),
                textAlign: TextAlign.end,
                style: AppTypography.detailPrice.copyWith(color: color),
              ),
            ),
          ),
          SizedBox(
            height: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (direction == PriceChangeDirection.flat)
                  Text(
                    '•',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      height: 14 / 8,
                      color: color,
                    ),
                  )
                else
                  RotatedBox(
                    quarterTurns: direction == PriceChangeDirection.up ? 2 : 0,
                    child: AppSvgIcon(
                      assetPath: AppAssets.detailChangeIndicator,
                      width: 8,
                      height: 14,
                      color: color,
                    ),
                  ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${formatAbsoluteChangeAmount(detail)} (${formatSignedPercent(detail.changeRate)})',
                    key: Key('watchlist-change-${item.id}'),
                    textAlign: TextAlign.end,
                    style: AppTypography.detailChange.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _directionColor(PriceChangeDirection direction) {
    switch (direction) {
      case PriceChangeDirection.up:
        return AppColors.mainAndAccent.up_f93f62;
      case PriceChangeDirection.down:
        return AppColors.mainAndAccent.down_4780ff;
      case PriceChangeDirection.flat:
        return AppDerivedColors.flat;
    }
  }
}

class _FallbackExpandedMetric extends StatelessWidget {
  const _FallbackExpandedMetric({required this.item, required this.width});

  final WatchlistItem item;
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
            formatPrice(item),
            key: Key('watchlist-primary-${item.id}'),
            textAlign: TextAlign.end,
            style: AppTypography.listMetric,
          ),
          const SizedBox(height: 4),
          Text(
            formatChangeRate(item.changeRate),
            key: Key('watchlist-change-${item.id}'),
            textAlign: TextAlign.end,
            style: AppTypography.listMetric.copyWith(
              color: switch (item.direction) {
                PriceChangeDirection.up => AppColors.mainAndAccent.up_f93f62,
                PriceChangeDirection.down =>
                  AppColors.mainAndAccent.down_4780ff,
                PriceChangeDirection.flat => AppDerivedColors.flat,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.item,
    required this.detailState,
    required this.layout,
    required this.onRetry,
    required this.onActionTap,
  });

  final WatchlistItem item;
  final AsyncValue<WatchlistDetail>? detailState;
  final WatchlistLayoutSpec layout;
  final VoidCallback onRetry;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    final detail = detailState?.valueOrNull;
    final hasDetail = detail != null;
    final error = detailState?.hasError ?? false;
    final isLoading =
        detailState == null || (detailState!.isLoading && !hasDetail);

    if (isLoading) {
      return _BodyFrame(
        layout: layout,
        child: Center(
          child: SizedBox(
            key: Key('watchlist-detail-loading-${item.id}'),
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.mainAndAccent.primary_ff8a00,
            ),
          ),
        ),
      );
    }

    if (error || detail == null) {
      return _BodyFrame(
        layout: layout,
        child: Container(
          key: Key('watchlist-detail-error-${item.id}'),
          decoration: BoxDecoration(
            color: AppColors.bg.bg_2_212121.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.border_333333),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '세부 정보를 불러오지 못했습니다.',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  color: AppColors.text.text_fafafa,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시 후 다시 시도해 주세요.',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  color: AppColors.text.text_2_bdbdbd,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: Key('watchlist-detail-retry-${item.id}'),
                onPressed: onRetry,
                child: const Text(
                  '다시 시도',
                  style: TextStyle(fontFamily: AppFonts.pretendard),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _BodyFrame(
      layout: layout,
      child: Column(
        key: Key('watchlist-detail-${item.id}'),
        children: [
          if (layout.stackedDetailLayout)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: Key('watchlist-chart-${item.id}'),
                  width: layout.chartWidth,
                  height: WatchlistLayoutSpec.chartHeight,
                  child: WatchlistCandlestickChart(
                    candles: detail.candles,
                    width: layout.chartWidth,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: layout.detailMetricsWidth,
                    child: _DetailMetrics(
                      detail: detail,
                      itemId: item.id,
                      layout: layout,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  key: Key('watchlist-chart-${item.id}'),
                  width: layout.chartWidth,
                  height: WatchlistLayoutSpec.chartHeight,
                  child: WatchlistCandlestickChart(
                    candles: detail.candles,
                    width: layout.chartWidth,
                  ),
                ),
                SizedBox(width: layout.chartMetricGap),
                SizedBox(
                  width: layout.detailMetricsWidth,
                  child: _DetailMetrics(
                    detail: detail,
                    itemId: item.id,
                    layout: layout,
                  ),
                ),
              ],
            ),
          const SizedBox(height: WatchlistLayoutSpec.actionPanelTopGap),
          SizedBox(
            key: Key('watchlist-action-panel-${item.id}'),
            width: layout.actionPanelWidth,
            height: WatchlistLayoutSpec.actionPanelHeight,
            child: WatchlistActionBar(
              item: item,
              layout: layout,
              onActionTap: onActionTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyFrame extends StatelessWidget {
  const _BodyFrame({required this.layout, required this.child});

  final WatchlistLayoutSpec layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WatchlistLayoutSpec.expandedBodyHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.horizontalPadding,
          0,
          layout.horizontalPadding,
          WatchlistLayoutSpec.expandedBodyBottomPadding,
        ),
        child: child,
      ),
    );
  }
}

class _DetailMetrics extends StatelessWidget {
  const _DetailMetrics({
    required this.detail,
    required this.itemId,
    required this.layout,
  });

  final WatchlistDetail detail;
  final String itemId;
  final WatchlistLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: layout.detailMetricGroupWidth,
          child: Text(
            formatVolumeWithRatio(
              tradeVolume: detail.tradeVolume,
              volumeRatio: detail.volumeRatio,
            ),
            key: Key('watchlist-detail-volume-$itemId'),
            textAlign: TextAlign.end,
            style: AppTypography.detailMetric,
          ),
        ),
        const SizedBox(height: 16),
        _MetricStatRow(
          rowKey: Key('watchlist-detail-open-row-$itemId'),
          tagKey: Key('watchlist-detail-open-tag-$itemId'),
          valueKey: Key('watchlist-detail-open-value-$itemId'),
          layout: layout,
          tag: '시',
          tagColor: AppDerivedColors.openTag,
          value: formatMetricValue(
            currency: detail.currency,
            price: detail.openPrice,
            changeRate: detail.openChangeRate,
          ),
          valueColor: _metricColor(detail.openChangeRate),
        ),
        const SizedBox(height: 8),
        _MetricStatRow(
          rowKey: Key('watchlist-detail-high-row-$itemId'),
          tagKey: Key('watchlist-detail-high-tag-$itemId'),
          valueKey: Key('watchlist-detail-high-value-$itemId'),
          layout: layout,
          tag: '고',
          tagColor: AppDerivedColors.highTag,
          value: formatMetricValue(
            currency: detail.currency,
            price: detail.highPrice,
            changeRate: detail.highChangeRate,
          ),
          valueColor: _metricColor(detail.highChangeRate),
        ),
        const SizedBox(height: 8),
        _MetricStatRow(
          rowKey: Key('watchlist-detail-low-row-$itemId'),
          tagKey: Key('watchlist-detail-low-tag-$itemId'),
          valueKey: Key('watchlist-detail-low-value-$itemId'),
          layout: layout,
          tag: '저',
          tagColor: AppDerivedColors.lowTag,
          value: formatMetricValue(
            currency: detail.currency,
            price: detail.lowPrice,
            changeRate: detail.lowChangeRate,
          ),
          valueColor: _metricColor(detail.lowChangeRate),
        ),
      ],
    );
  }

  Color _metricColor(double value) {
    if (value > 0) {
      return AppColors.mainAndAccent.up_f93f62;
    }
    if (value < 0) {
      return AppColors.mainAndAccent.down_4780ff;
    }
    return AppColors.text.text_fafafa;
  }
}

class _MetricStatRow extends StatelessWidget {
  const _MetricStatRow({
    required this.rowKey,
    required this.tagKey,
    required this.valueKey,
    required this.layout,
    required this.tag,
    required this.tagColor,
    required this.value,
    required this.valueColor,
  });

  final Key rowKey;
  final Key tagKey;
  final Key valueKey;
  final WatchlistLayoutSpec layout;
  final String tag;
  final Color tagColor;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        key: rowKey,
        width: layout.detailMetricGroupWidth,
        height: WatchlistLayoutSpec.metricTagSize,
        child: Row(
          children: [
            Container(
              key: tagKey,
              width: WatchlistLayoutSpec.metricTagSize,
              height: WatchlistLayoutSpec.metricTagSize,
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
              child: Text(tag, style: AppTypography.detailLabel),
            ),
            SizedBox(width: layout.metricLabelGap),
            SizedBox(
              width: layout.detailMetricValueWidth,
              child: Text(
                value,
                key: valueKey,
                textAlign: TextAlign.end,
                style: AppTypography.detailMetric.copyWith(color: valueColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
