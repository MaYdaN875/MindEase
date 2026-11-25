import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/onboarding_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() {
  testWidgets('wide viewport keeps the mobile-first welcome layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1070, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: OnboardingScreen(onFinishOnboarding: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Tu bienestar,\na tu ritmo.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byTooltip('Cerrar'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mobile viewport keeps both actions on screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: OnboardingScreen(onFinishOnboarding: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Tu bienestar,\na tu ritmo.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(tester.getBottomRight(find.text('Get Started')).dy, lessThan(844));
    expect(tester.getBottomRight(find.text('Log In')).dy, lessThan(844));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('compact phone keeps registration available without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: OnboardingScreen(onFinishOnboarding: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.getBottomRight(find.text('Get Started')).dy, lessThan(568));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
