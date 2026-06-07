import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../search/presentation/screens/search_screen.dart';
import '../../watchlist/presentation/screens/watchlist_screen.dart';
import 'widgets/app_bottom_nav.dart';
import '../../../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _currentTab = AppTab.watchlist;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.bg.bg_2_212121,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg.bg_121212,
        body: IndexedStack(
          index: _currentTab.index,
          children: const [
            WatchlistScreen(),
            _PlaceholderScreen(label: '종목토론'),
            SearchScreen(),
            _PlaceholderScreen(label: '뉴스'),
            _PlaceholderScreen(label: '설정'),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentTab: _currentTab,
          onTabSelected: (tab) {
            setState(() {
              _currentTab = tab;
            });
          },
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg.bg_121212,
      child: Center(
        child: Text(
          '$label 화면은 준비 중입니다.',
          style: AppTypography.searchEmptyTitle,
        ),
      ),
    );
  }
}
