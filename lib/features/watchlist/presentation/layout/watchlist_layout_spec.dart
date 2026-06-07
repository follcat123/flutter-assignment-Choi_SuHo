import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class WatchlistLayoutSpec {
  const WatchlistLayoutSpec({
    required this.viewportWidth,
    required this.horizontalScale,
    required this.horizontalPadding,
    required this.logoTitleGap,
    required this.titleMetricGap,
    required this.chartMetricGap,
    required this.metricLabelGap,
    required this.actionIconGap,
    required this.collapsedMetricWidth,
    required this.expandedHeaderMetricWidth,
    required this.detailMetricsWidth,
    required this.detailMetricGroupWidth,
    required this.detailMetricValueWidth,
    required this.chartWidth,
    required this.actionPanelWidth,
    required this.stackedDetailLayout,
  });

  static const double baseWidth = 360;
  static const double headerHeight = 46;
  static const double headerToFilterGap = 25;
  static const double filterHeight = 24;
  static const double filterToListGap = 12;
  static const double collapsedRowHeight = 56;
  static const double expandedRowHeight = 240;
  static const double expandedBodyHeight =
      expandedRowHeight - collapsedRowHeight;
  static const double chartHeight = 111;
  static const double actionPanelHeight = 44;
  static const double actionPanelTopGap = 8;
  static const double expandedBodyBottomPadding = 21;
  static const double topSectionVerticalPadding = 12;
  static const double logoSize = 24;
  static const double metricTagSize = 14;

  factory WatchlistLayoutSpec.fromWidth(double viewportWidth) {
    final resolvedWidth = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : baseWidth;
    final horizontalScale = resolvedWidth / baseWidth;
    final horizontalPadding = 16 * horizontalScale;
    final chartMetricGap = 16 * horizontalScale;
    final detailMetricGroupWidth = 128 * horizontalScale;
    final detailMetricsWidth = detailMetricGroupWidth;
    final availableChartWidth =
        resolvedWidth -
        (horizontalPadding * 2) -
        chartMetricGap -
        detailMetricsWidth;
    final stackedDetailLayout = availableChartWidth < 100;

    return WatchlistLayoutSpec(
      viewportWidth: resolvedWidth,
      horizontalScale: horizontalScale,
      horizontalPadding: horizontalPadding,
      logoTitleGap: 8 * horizontalScale,
      titleMetricGap: 12 * horizontalScale,
      chartMetricGap: chartMetricGap,
      metricLabelGap: 8 * horizontalScale,
      actionIconGap: 6 * horizontalScale,
      collapsedMetricWidth: math.max(77 * horizontalScale, 68),
      expandedHeaderMetricWidth: math.max(97 * horizontalScale, 86),
      detailMetricsWidth: stackedDetailLayout
          ? resolvedWidth - (horizontalPadding * 2)
          : detailMetricsWidth,
      detailMetricGroupWidth: detailMetricGroupWidth,
      detailMetricValueWidth: math.max(
        detailMetricGroupWidth - metricTagSize - (8 * horizontalScale),
        72,
      ),
      chartWidth: stackedDetailLayout
          ? resolvedWidth - (horizontalPadding * 2)
          : availableChartWidth,
      actionPanelWidth: resolvedWidth - (horizontalPadding * 2),
      stackedDetailLayout: stackedDetailLayout,
    );
  }

  final double viewportWidth;
  final double horizontalScale;
  final double horizontalPadding;
  final double logoTitleGap;
  final double titleMetricGap;
  final double chartMetricGap;
  final double metricLabelGap;
  final double actionIconGap;
  final double collapsedMetricWidth;
  final double expandedHeaderMetricWidth;
  final double detailMetricsWidth;
  final double detailMetricGroupWidth;
  final double detailMetricValueWidth;
  final double chartWidth;
  final double actionPanelWidth;
  final bool stackedDetailLayout;
}
