import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class SearchLayoutSpec {
  const SearchLayoutSpec({
    required this.viewportWidth,
    required this.horizontalScale,
    required this.horizontalPadding,
    required this.resultWidth,
    required this.expandedPanelWidth,
  });

  static const double baseWidth = 360;
  static const double headerHeight = 48;
  static const double resultRowHeight = 56;
  static const double expandedActionHeight = 44;
  static const double expandedActionTopGap = 8;
  static const double emptyIconWidth = 42;
  static const double emptyIconHeight = 48;
  static const double emptyTopOffset = 208;
  static const double toastHeight = 66;

  factory SearchLayoutSpec.fromWidth(double viewportWidth) {
    final resolvedWidth = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : baseWidth;
    final horizontalScale = resolvedWidth / baseWidth;
    final horizontalPadding = 16 * horizontalScale;
    return SearchLayoutSpec(
      viewportWidth: resolvedWidth,
      horizontalScale: horizontalScale,
      horizontalPadding: horizontalPadding,
      resultWidth: resolvedWidth - (horizontalPadding * 2),
      expandedPanelWidth: math.max(
        resolvedWidth - (horizontalPadding * 2),
        288,
      ),
    );
  }

  final double viewportWidth;
  final double horizontalScale;
  final double horizontalPadding;
  final double resultWidth;
  final double expandedPanelWidth;
}
