import 'package:flutter/material.dart';

import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../layout/search_layout_spec.dart';

class SearchActionBar extends StatelessWidget {
  const SearchActionBar({
    required this.layout,
    required this.onActionTap,
    super.key,
  });

  final SearchLayoutSpec layout;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SearchLayoutSpec.expandedActionHeight,
      decoration: BoxDecoration(
        color: AppColors.bg.bg_2_212121,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border.border_5_3b3e53),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchActionButton(
            layout: layout,
            action: '뉴스',
            assetPath: AppAssets.actionNews,
            contentStartInset: 60,
            onTap: onActionTap,
          ),
          const _SearchActionDivider(),
          _SearchActionButton(
            layout: layout,
            action: '종목토론',
            assetPath: AppAssets.actionDiscussion,
            contentStartInset: 50,
            onTap: onActionTap,
          ),
        ],
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({
    required this.layout,
    required this.action,
    required this.assetPath,
    required this.contentStartInset,
    required this.onTap,
  });

  final SearchLayoutSpec layout;
  final String action;
  final String assetPath;
  final double contentStartInset;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('search-action-$action'),
          onTap: () => onTap(action),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: contentStartInset * layout.horizontalScale,
              ),
              child: Row(
                key: Key('search-action-content-$action'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAssetSlotIcon(
                    assetPath: assetPath,
                    slotWidth: 16,
                    slotHeight: 16,
                    assetWidth: assetPath == AppAssets.actionNews
                        ? AppAssetSizes.actionNews.width
                        : AppAssetSizes.actionDiscussion.width,
                    assetHeight: assetPath == AppAssets.actionNews
                        ? AppAssetSizes.actionNews.height
                        : AppAssetSizes.actionDiscussion.height,
                    color: AppColors.text.text_fafafa,
                  ),
                  const SizedBox(width: 6),
                  Text(action, style: AppTypography.action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchActionDivider extends StatelessWidget {
  const _SearchActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.border.border_333333,
    );
  }
}
