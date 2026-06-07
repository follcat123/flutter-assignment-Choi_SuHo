import 'package:flutter/material.dart';

import '../../domain/models/watchlist_models.dart';
import '../layout/watchlist_layout_spec.dart';
import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';

class WatchlistActionBar extends StatelessWidget {
  const WatchlistActionBar({
    required this.item,
    required this.layout,
    required this.onActionTap,
    super.key,
  });

  final WatchlistItem item;
  final WatchlistLayoutSpec layout;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          _ActionButton(
            item: item,
            layout: layout,
            action: '뉴스',
            assetPath: AppAssets.actionNews,
            contentStartInset: 33,
            onTap: onActionTap,
          ),
          const _ActionDivider(),
          _ActionButton(
            item: item,
            layout: layout,
            action: '종목토론',
            assetPath: AppAssets.actionDiscussion,
            contentStartInset: 23,
            onTap: onActionTap,
          ),
          const _ActionDivider(),
          _ActionButton(
            item: item,
            layout: layout,
            action: '삭제',
            assetPath: AppAssets.actionDelete,
            contentStartInset: 33,
            onTap: onActionTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.item,
    required this.layout,
    required this.action,
    required this.assetPath,
    required this.contentStartInset,
    required this.onTap,
  });

  final WatchlistItem item;
  final WatchlistLayoutSpec layout;
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
          key: Key('watchlist-action-${action.toLowerCase()}-${item.id}'),
          borderRadius: BorderRadius.circular(4),
          onTap: () => onTap(action),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: contentStartInset * layout.horizontalScale,
              ),
              child: Row(
                key: Key('watchlist-action-content-$action-${item.id}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAssetSlotIcon(
                    assetPath: assetPath,
                    slotWidth: 16,
                    slotHeight: 16,
                    assetWidth: assetPath == AppAssets.actionNews
                        ? AppAssetSizes.actionNews.width
                        : assetPath == AppAssets.actionDiscussion
                        ? AppAssetSizes.actionDiscussion.width
                        : AppAssetSizes.actionDelete.width,
                    assetHeight: assetPath == AppAssets.actionNews
                        ? AppAssetSizes.actionNews.height
                        : assetPath == AppAssets.actionDiscussion
                        ? AppAssetSizes.actionDiscussion.height
                        : AppAssetSizes.actionDelete.height,
                    color: AppColors.text.text_fafafa,
                  ),
                  SizedBox(width: layout.actionIconGap),
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

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.border.border_333333,
    );
  }
}
