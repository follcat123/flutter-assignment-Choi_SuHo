import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_test_harness.dart';
import '../../../support/repositories/mock_watchlist_repository.dart';

void main() {
  Future<void> pumpSearch(WidgetTester tester) {
    return pumpSearchTab(
      tester,
      repository: MockWatchlistRepository(
        latency: Duration.zero,
        detailLatency: Duration.zero,
      ),
    );
  }

  Iterable<TextSpan> flattenTextSpans(InlineSpan span) sync* {
    if (span is TextSpan) {
      yield span;
      final children = span.children;
      if (children != null) {
        for (final child in children) {
          yield* flattenTextSpans(child);
        }
      }
    }
  }

  testWidgets('smoke: expands one search result at a time', (tester) async {
    await pumpSearch(tester);

    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('search-result-sk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-actions-sk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-result-sk-square')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-actions-sk')), findsNothing);
    expect(find.byKey(const Key('search-actions-sk-square')), findsOneWidget);
  });

  testWidgets('smoke: shows the empty state when nothing matches', (
    tester,
  ) async {
    await pumpSearch(tester);

    await tester.enterText(find.byKey(const Key('search-input')), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('search-empty-group')), findsOneWidget);
  });

  testWidgets('smoke: clears search results and selection on clear', (
    tester,
  ) async {
    await pumpSearch(tester);

    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-result-sk')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('search-input')),
    );
    expect(textField.controller?.text, isEmpty);
    expect(find.byKey(const Key('search-actions-sk')), findsNothing);
  });

  testWidgets(
    'assignment: builds highlighted RichText for title and subtitle',
    (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byKey(const Key('search-input')), 'sk');
      await tester.pumpAndSettle();

      final richTexts = tester.widgetList<RichText>(
        find.descendant(
          of: find.byKey(const Key('search-result-row-sk')),
          matching: find.byType(RichText),
        ),
      );

      expect(
        richTexts.length,
        2,
        reason:
            'TODO(assignment): SearchResultRow 안에 제목/서브텍스트 2줄을 '
            'RichText로 구성하세요.',
      );

      final allSpans = richTexts.expand(
        (widget) => flattenTextSpans(widget.text),
      );
      final hasHighlightedSpan = allSpans.any(
        (span) => span.style?.color == const Color(0xFFB980FF),
      );

      expect(
        hasHighlightedSpan,
        isTrue,
        reason:
            'TODO(assignment): query highlight를 TextSpan으로 구성하고, '
            '강조 색상을 적용하세요.',
      );
    },
  );

  testWidgets('assignment: selected result renders the two action buttons', (
    tester,
  ) async {
    await pumpSearch(tester);

    await tester.enterText(find.byKey(const Key('search-input')), 'sk');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-result-sk')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('search-action-뉴스')),
      findsOneWidget,
      reason:
          'TODO(assignment): selected SearchResultRow 아래에 뉴스 액션 버튼을 '
          '구성하세요.',
    );
    expect(
      find.byKey(const Key('search-action-종목토론')),
      findsOneWidget,
      reason:
          'TODO(assignment): selected SearchResultRow 아래에 종목토론 액션 버튼을 '
          '구성하세요.',
    );
    expect(find.byKey(const Key('search-action-content-뉴스')), findsOneWidget);
    expect(find.byKey(const Key('search-action-content-종목토론')), findsOneWidget);
  });

  testWidgets(
    'assignment: builds the toast with blur and heart-check composition',
    (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byKey(const Key('search-input')), 'sk');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('search-heart-sk')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byType(BackdropFilter),
        findsOneWidget,
        reason:
            'TODO(assignment): SearchToast 바깥 shell에 blur glass 효과를 '
            '구성하세요.',
      );
      expect(
        find.byKey(const Key('search-toast-favorite-icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('search-toast-check-icon')),
        findsOneWidget,
        reason: 'TODO(assignment): 하트 위에 check 아이콘을 합성해서 배치하세요.',
      );
      expect(
        find.textContaining('관심그룹'),
        findsOneWidget,
        reason: 'TODO(assignment): 토스트 문구를 Figma 구조대로 조합하세요.',
      );
    },
  );
}
