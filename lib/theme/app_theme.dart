// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

class AppColors {
  static const bg = _AppColorsBg();
  static const border = _AppColorsBorder();
  static const text = _AppColorsText();
  static const mainAndAccent = _AppColorsMainAndAccent();
  static const labels = _AppColorsLabels();
  static const point = _AppColorsPoint();
  static const darkTheme = _AppColorsDarkTheme();
  static const grays = _AppColorsGrays();
}

class AppDerivedColors {
  static const searchDivider = Color(0xFF616161);
  static const modalScrim = Color(0x99000000);
  static const searchToastBackground = Color(0xB3252525);
  static const searchToastBorder = Color(0x33B980FF);
  static const searchToastGlow = Color(0x40B980FF);
  static const flat = Color(0xFF9E9E9E);
  static const skeleton = Color(0xFF2A2A2A);
  static const skeletonHighlight = Color(0xFF383838);
  static const chipBackground = Color(0xFF1B1B1B);
  static const chartWick = Color(0xFF585858);
  static const openTag = Color(0xFF14A68C);
  static const highTag = Color(0xFFE35065);
  static const lowTag = Color(0xFF5681F7);
}

class _AppColorsBg {
  const _AppColorsBg();

  final Color bg_121212 = const Color(0xFF121212); // BG/BG_121212
  final Color bg_2_212121 = const Color(0xFF212121); // BG/BG 2_212121
  final Color bg_4_333333 = const Color(0xFF333333); // BG/BG 4_333333
}

class _AppColorsBorder {
  const _AppColorsBorder();

  final Color border_333333 = const Color(0xFF333333); // Border/Border_333333
  final Color border_4_424242 = const Color(
    0xFF424242,
  ); // Border/Border 4_424242
  final Color border_5_3b3e53 = const Color(
    0xFF3B3E53,
  ); // Border/Border 5_3B3E53
}

class _AppColorsText {
  const _AppColorsText();

  final Color text_fafafa = const Color(0xFFFAFAFA); // Text/Text_FAFAFA
  final Color text_2_bdbdbd = const Color(0xFFBDBDBD); // Text/Text 2_BDBDBD
  final Color text_3_9e9e9e = const Color(0xFF9E9E9E); // Text/Text 3_9E9E9E
  final Color text_5_e0e0e0 = const Color(0xFFE0E0E0); // Text/Text 5_E0E0E0
  final Color text_9_fafafa = const Color(0xFFFAFAFA); // Text/Text 9_FAFAFA
  final Color text_10_424242 = const Color(0xFF424242); // Text/Text 10_424242
  final Color text_ffffff = const Color(0xFFFFFFFF); // Text/Text_FFFFFF
}

class _AppColorsMainAndAccent {
  const _AppColorsMainAndAccent();

  final Color down_4780ff = const Color(
    0xFF4780FF,
  ); // Main & Accent/Down_4780FF
  final Color up_f93f62 = const Color(0xFFF93F62); // Main & Accent/Up_F93F62
  final Color primary_ff8a00 = const Color(
    0xFFFF8A00,
  ); // Main & Accent/Primary_FF8A00
  final Color point_b980ff = const Color(
    0xFFB980FF,
  ); // Main & Accent/Point_B980FF
}

class _AppColorsLabels {
  const _AppColorsLabels();

  final Color primary_dark = const Color(0xFFFFFFFF); // Labels/Primary - Dark
}

class _AppColorsPoint {
  const _AppColorsPoint();

  final Color jongmoksearch_b980ff = const Color(0xFFB980FF); // Point/종목검색
}

class _AppColorsDarkTheme {
  const _AppColorsDarkTheme();

  final Color c_424242 = const Color(0xFF424242); // Dark theme/424242
  final Color fafafa = const Color(0xFFFAFAFA); // Dark theme/FAFAFA
  final Color bdbdbd = const Color(0xFFBDBDBD); // Dark theme/BDBDBD
}

class _AppColorsGrays {
  const _AppColorsGrays();

  final Color white = const Color(0xFFFFFFFF); // Grays/White
}

class AppFonts {
  static const pretendard = 'Pretendard';
}

const _tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

TextStyle tabularTextStyle(TextStyle style) {
  return style.copyWith(fontFeatures: _tabularFigures);
}

class AppTypography {
  static final header = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 30 / 24,
    letterSpacing: 0,
    color: AppColors.mainAndAccent.primary_ff8a00,
  );

  static final filter = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_5_e0e0e0,
  );

  static final date = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_2_bdbdbd,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.text.text_2_bdbdbd,
  );

  static final listName = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 16 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final listMetric = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
    fontFeatures: _tabularFigures,
  );

  static final detailPrice = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 18 / 15,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
    fontFeatures: _tabularFigures,
  );

  static final detailChange = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
    fontFeatures: _tabularFigures,
  );

  static final detailMetric = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 13 / 11,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
    fontFeatures: _tabularFigures,
  );

  static final detailLabel = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 12 / 10,
    letterSpacing: 0,
    color: AppColors.labels.primary_dark,
  );

  static final action = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final sheetTitle = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 22 / 18,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final sheetOption = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_2_bdbdbd,
  );

  static final sheetPickerValue = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
    fontFeatures: _tabularFigures,
  );

  static final sheetPickerLabel = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_3_9e9e9e,
  );

  static final sheetButton = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0,
  );

  static final nav = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final searchQuery = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 14 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final searchName = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 16 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final searchMeta = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_3_9e9e9e,
    fontFeatures: _tabularFigures,
  );

  static final searchEmptyTitle = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 16 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );

  static final searchEmptyDescription = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.text.text_3_9e9e9e,
  );

  static final searchToast = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.text.text_fafafa,
  );
}

ThemeData buildAppTheme() {
  final textTheme = TextTheme(
    headlineSmall: AppTypography.header,
    bodyLarge: AppTypography.listName,
    bodyMedium: AppTypography.filter,
    labelSmall: AppTypography.nav,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppFonts.pretendard,
    scaffoldBackgroundColor: AppColors.bg.bg_121212,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: textTheme,
    colorScheme: ColorScheme.dark(
      primary: AppColors.mainAndAccent.primary_ff8a00,
      secondary: AppColors.mainAndAccent.primary_ff8a00,
      surface: AppColors.bg.bg_2_212121,
      onSurface: AppColors.text.text_fafafa,
      error: AppColors.mainAndAccent.up_f93f62,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.bg.bg_2_212121,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: textTheme.bodyMedium,
    ),
    dividerColor: AppColors.border.border_333333,
  );
}
