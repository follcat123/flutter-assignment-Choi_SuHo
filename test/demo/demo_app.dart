import 'package:flutter/material.dart';
import 'package:sample/theme/app_theme.dart';

import 'features/demo/presentation/screens/demo_shell.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key, this.stepDelayFactor = 1});

  final double stepDelayFactor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '관심종목 데모',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: DemoShell(stepDelayFactor: stepDelayFactor),
    );
  }
}
