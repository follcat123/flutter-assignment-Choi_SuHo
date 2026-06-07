import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../watchlist/domain/models/watchlist_models.dart';
import '../../../../theme/app_theme.dart';
import '../providers/search_controller.dart';
import '../layout/search_layout_spec.dart';
import '../widgets/search_empty_state.dart';
import '../widgets/search_header.dart';
import '../widgets/search_result_row.dart';
import '../widgets/search_toast.dart';
import '../../../watchlist/presentation/providers/watchlist_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    ref.read(searchControllerProvider.notifier).setFocused(_focusNode.hasFocus);
  }

  Future<void> _handleHeartTap(StockSearchItem item) async {
    final controller = ref.read(searchControllerProvider.notifier);
    if (!item.isFavorite) {
      controller.clearSelection();
      FocusScope.of(context).unfocus();
    }

    await controller.toggleFavorite(item);
    await ref.read(watchlistControllerProvider.notifier).refresh();
  }

  void _handlePlaceholderAction(String action, StockSearchItem item) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$action 기능은 준비 중입니다. ${item.name}에 연결될 예정입니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    if (_textController.text != state.query) {
      _textController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return ColoredBox(
      color: AppColors.bg.bg_121212,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = SearchLayoutSpec.fromWidth(constraints.maxWidth);
            final results =
                state.results.valueOrNull ?? const <StockSearchItem>[];
            final hasQuery = state.query.trim().isNotEmpty;
            final showEmpty =
                hasQuery && state.results.hasValue && results.isEmpty;
            final showError = hasQuery && state.results.hasError;
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return Stack(
              children: [
                Column(
                  key: const Key('search-screen'),
                  children: [
                    SearchHeader(
                      controller: _textController,
                      focusNode: _focusNode,
                      layout: layout,
                      showClearButton: state.query.isNotEmpty,
                      onChanged: (value) {
                        unawaited(controller.setQuery(value));
                      },
                      onClear: () {
                        controller.clearQuery();
                        _textController.clear();
                        _focusNode.requestFocus();
                      },
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (showError) {
                            return Center(
                              child: Text(
                                '검색 결과를 불러오지 못했습니다.',
                                style: AppTypography.searchEmptyTitle,
                              ),
                            );
                          }

                          if (showEmpty) {
                            return SearchEmptyState(layout: layout);
                          }

                          if (!hasQuery) {
                            return const SizedBox.expand();
                          }

                          return ListView.builder(
                            key: const Key('search-results-list'),
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: bottomInset > 0 ? 24 : 96,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final item = results[index];
                              final isSelected =
                                  state.selectedItemId == item.id;
                              return SearchResultRow(
                                item: item,
                                query: state.query,
                                isSelected: isSelected,
                                layout: layout,
                                onTap: () => controller.toggleSelection(item),
                                onHeartTap: () {
                                  unawaited(_handleHeartTap(item));
                                },
                                onActionTap: (action) =>
                                    _handlePlaceholderAction(action, item),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (state.toast case final toast?)
                  Positioned(
                    left: layout.horizontalPadding,
                    right: layout.horizontalPadding,
                    bottom: 32,
                    child: SearchToast(
                      key: const Key('search-toast'),
                      layout: layout,
                      message: toast.message,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
