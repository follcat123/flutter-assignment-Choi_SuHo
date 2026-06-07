import 'package:flutter/material.dart';

import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../layout/search_layout_spec.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({required this.layout, super.key});

  final SearchLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: const Key('search-empty-state'),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: SearchLayoutSpec.emptyTopOffset),
        child: SizedBox(
          width: layout.resultWidth,
          child: Column(
            key: const Key('search-empty-group'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(
                key: Key('search-empty-illustration'),
                assetPath: AppAssets.searchEmptyIllustration,
                width: SearchLayoutSpec.emptyIconWidth,
                height: SearchLayoutSpec.emptyIconHeight,
              ),
              const SizedBox(height: 16),
              Text(
                '검색 결과가 없어요',
                key: const Key('search-empty-title'),
                style: AppTypography.searchEmptyTitle,
              ),
              const SizedBox(height: 8),
              Text(
                '정확한 종목명이나 종목코드를 입력해 주세요!',
                style: AppTypography.searchEmptyDescription,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
