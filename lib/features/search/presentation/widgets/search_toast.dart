import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_assets.dart';
import '../../../../theme/app_theme.dart';
import '../layout/search_layout_spec.dart';

class SearchToast extends StatelessWidget {
  const SearchToast({required this.layout, required this.message, super.key});

  final SearchLayoutSpec layout;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Figma 기준: blur + 반투명 배경 + 보더 + 그림자 + 하트+체크 아이콘 조합
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: SearchLayoutSpec.toastHeight,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * layout.horizontalScale,
          ),
          decoration: BoxDecoration(
            color: AppDerivedColors.searchToastBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppDerivedColors.searchToastBorder),
            boxShadow: [
              BoxShadow(
                color: AppDerivedColors.searchToastGlow,
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // 하트 + 체크 아이콘 조합: Stack으로 우측 하단에 체크 오버레이
              SizedBox(
                key: const Key('search-toast-favorite-icon'),
                width: 20,
                height: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppAssetSlotIcon(
                      assetPath: AppAssets.favoriteHeart,
                      slotWidth: 20,
                      slotHeight: 20,
                      assetWidth: AppAssetSizes.favoriteHeart.width,
                      assetHeight: AppAssetSizes.favoriteHeart.height,
                      color: AppColors.mainAndAccent.up_f93f62,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: AppAssetSlotIcon(
                        key: const Key('search-toast-check-icon'),
                        assetPath: AppAssets.toastCheck,
                        slotWidth: 8,
                        slotHeight: 8,
                        assetWidth: AppAssetSizes.toastCheck.width,
                        assetHeight: AppAssetSizes.toastCheck.height,
                        color: AppColors.mainAndAccent.point_b980ff,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.searchToast,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
