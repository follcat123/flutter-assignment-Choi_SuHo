import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/theme/app_assets.dart';
import 'package:sample/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('mirrors the Figma variable groups and values', () {
      expect(AppColors.bg.bg_121212, const Color(0xFF121212));
      expect(AppColors.bg.bg_2_212121, const Color(0xFF212121));
      expect(AppColors.bg.bg_4_333333, const Color(0xFF333333));

      expect(AppColors.border.border_333333, const Color(0xFF333333));
      expect(AppColors.border.border_4_424242, const Color(0xFF424242));
      expect(AppColors.border.border_5_3b3e53, const Color(0xFF3B3E53));

      expect(AppColors.text.text_fafafa, const Color(0xFFFAFAFA));
      expect(AppColors.text.text_2_bdbdbd, const Color(0xFFBDBDBD));
      expect(AppColors.text.text_3_9e9e9e, const Color(0xFF9E9E9E));
      expect(AppColors.text.text_5_e0e0e0, const Color(0xFFE0E0E0));
      expect(AppColors.text.text_9_fafafa, const Color(0xFFFAFAFA));
      expect(AppColors.text.text_10_424242, const Color(0xFF424242));
      expect(AppColors.text.text_ffffff, const Color(0xFFFFFFFF));

      expect(AppColors.mainAndAccent.down_4780ff, const Color(0xFF4780FF));
      expect(AppColors.mainAndAccent.up_f93f62, const Color(0xFFF93F62));
      expect(AppColors.mainAndAccent.primary_ff8a00, const Color(0xFFFF8A00));
      expect(AppColors.mainAndAccent.point_b980ff, const Color(0xFFB980FF));

      expect(AppColors.labels.primary_dark, const Color(0xFFFFFFFF));
      expect(AppColors.point.jongmoksearch_b980ff, const Color(0xFFB980FF));
      expect(AppColors.darkTheme.c_424242, const Color(0xFF424242));
      expect(AppColors.darkTheme.fafafa, const Color(0xFFFAFAFA));
      expect(AppColors.darkTheme.bdbdbd, const Color(0xFFBDBDBD));
      expect(AppColors.grays.white, const Color(0xFFFFFFFF));
    });

    test('keeps non Figma colors in AppDerivedColors', () {
      expect(AppDerivedColors.searchDivider, const Color(0xFF616161));
      expect(AppDerivedColors.modalScrim, const Color(0x99000000));
      expect(AppDerivedColors.searchToastBackground, const Color(0xB3252525));
      expect(AppDerivedColors.searchToastBorder, const Color(0x33B980FF));
      expect(AppDerivedColors.searchToastGlow, const Color(0x40B980FF));
      expect(AppDerivedColors.flat, const Color(0xFF9E9E9E));
      expect(AppDerivedColors.skeleton, const Color(0xFF2A2A2A));
      expect(AppDerivedColors.skeletonHighlight, const Color(0xFF383838));
      expect(AppDerivedColors.chipBackground, const Color(0xFF1B1B1B));
      expect(AppDerivedColors.chartWick, const Color(0xFF585858));
      expect(AppDerivedColors.openTag, const Color(0xFF14A68C));
      expect(AppDerivedColors.highTag, const Color(0xFFE35065));
      expect(AppDerivedColors.lowTag, const Color(0xFF5681F7));
    });
  });

  group('AppAssets', () {
    test('uses readable names for Figma-derived assets', () {
      expect(AppAssets.searchIcon, endsWith('icon_search.svg'));
      expect(AppAssets.searchClearButton, endsWith('button_clear.png'));
      expect(AppAssets.favoriteHeart, endsWith('icon_favorite_heart.svg'));
      expect(AppAssets.navWatchlist, endsWith('icon_nav_watchlist.svg'));
      expect(AppAssets.actionNews, endsWith('icon_action_news.svg'));
      expect(
        AppAssets.actionDiscussion,
        endsWith('icon_action_discussion.svg'),
      );
      expect(AppAssets.actionDelete, endsWith('icon_action_delete.svg'));
      expect(AppAssets.sortCheck, endsWith('icon_check.svg'));
      expect(AppAssets.sortFilter, endsWith('icon_filter_sort.svg'));
      expect(
        AppAssets.searchEmptyIllustration,
        endsWith('illustration_search_empty.png'),
      );
      expect(AppAssets.toastCheck, endsWith('icon_toast_check.svg'));
      expect(AppAssets.navDiscussion, endsWith('icon_nav_discussion.svg'));
      expect(AppAssets.navNews, endsWith('icon_nav_news.svg'));
      expect(AppAssets.navSettings, endsWith('icon_nav_settings.svg'));
      expect(
        AppAssets.detailChangeIndicator,
        endsWith('icon_detail_change.svg'),
      );
    });

    test('keeps Figma export icon sizes for non-square assets', () {
      expect(AppAssetSizes.searchIcon, const Size(20, 20));
      expect(AppAssetSizes.favoriteHeart, const Size(16, 13));
      expect(AppAssetSizes.navWatchlist, const Size(20, 20));
      expect(AppAssetSizes.toastCheck, const Size(6, 4));
      expect(AppAssetSizes.actionNews, const Size(12.1667, 14.8334));
      expect(AppAssetSizes.actionDiscussion, const Size(14.9035, 14.8333));
      expect(AppAssetSizes.actionDelete, const Size(16, 16));
      expect(AppAssetSizes.sortCheck, const Size(17, 12));
      expect(AppAssetSizes.sortFilter, const Size(7, 10));
      expect(AppAssetSizes.navDiscussion, const Size(20, 20));
      expect(AppAssetSizes.navNews, const Size(20, 20));
      expect(AppAssetSizes.navSettings, const Size(20, 20));
      expect(AppAssetSizes.detailChangeIndicator, const Size(8, 14));
    });
  });
}
