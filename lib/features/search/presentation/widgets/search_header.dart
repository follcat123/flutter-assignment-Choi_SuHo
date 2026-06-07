import 'package:flutter/material.dart';

import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../layout/search_layout_spec.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.layout,
    required this.showClearButton,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchLayoutSpec layout;
  final bool showClearButton;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SearchLayoutSpec.headerHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppDerivedColors.searchDivider),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
      child: Row(
        children: [
          AppAssetSlotIcon(
            assetPath: AppAssets.searchIcon,
            slotWidth: 24,
            slotHeight: 24,
            assetWidth: AppAssetSizes.searchIcon.width,
            assetHeight: AppAssetSizes.searchIcon.height,
            color: AppColors.text.text_2_bdbdbd,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('search-input'),
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: false,
              cursorColor: AppColors.point.jongmoksearch_b980ff,
              style: AppTypography.searchQuery,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '',
              ),
            ),
          ),
          if (showClearButton)
            GestureDetector(
              key: const Key('search-clear'),
              onTap: onClear,
              child: const AppSvgIcon(
                assetPath: AppAssets.searchClearButton,
                width: 16,
                height: 16,
              ),
            ),
        ],
      ),
    );
  }
}
