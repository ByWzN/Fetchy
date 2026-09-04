import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fetchy/app/app.dart';
import 'package:fetchy/core/settings/locale_controller.dart';
import 'package:fetchy/core/settings/theme_controller.dart';

void main() {
  testWidgets('FetchyApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      FetchyApp(
        themeController: ThemeController(),
        localeController: LocaleController(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
