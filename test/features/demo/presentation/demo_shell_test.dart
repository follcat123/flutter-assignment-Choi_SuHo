import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_test_harness.dart';

String currentDemoStepLabel(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('demo-current-step'))).data ??
      '';
}

void main() {
  testWidgets('smoke: renders the demo control panel and default scenario', (
    tester,
  ) async {
    await pumpDemoApp(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo-control-panel')), findsOneWidget);
    expect(find.byKey(const Key('demo-scenario-select')), findsOneWidget);
    expect(currentDemoStepLabel(tester), isNotEmpty);
  });

  testWidgets('smoke: switching scenarios updates the current step label', (
    tester,
  ) async {
    await pumpDemoApp(tester);
    await tester.pumpAndSettle();

    final before = currentDemoStepLabel(tester);

    await tester.tap(find.byKey(const Key('demo-scenario-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심 상세 데모').last);
    await tester.pumpAndSettle();

    expect(currentDemoStepLabel(tester), isNot(before));
  });

  testWidgets('smoke: play pause and restart controls stay interactive', (
    tester,
  ) async {
    await pumpDemoApp(tester, stepDelayFactor: 1);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('demo-play')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('demo-pause')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('demo-restart')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('demo-play')), findsOneWidget);
    expect(find.byKey(const Key('demo-pause')), findsOneWidget);
    expect(find.byKey(const Key('demo-restart')), findsOneWidget);
  });
}
