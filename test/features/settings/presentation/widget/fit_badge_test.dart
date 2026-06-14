import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/domain/model/model_fit_result.dart';
import 'package:crm/features/settings/presentation/widget/fit_badge.dart';

void main() {
  group('FitBadge', () {
    testWidgets('renders "PERFECT" in success color for Fit.perfect', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FitBadge(fit: Fit.perfect)));

      final text = tester.widget<Text>(find.text('PERFECT'));
      expect(text.style?.color, AppColors.success);
    });

    testWidgets('renders "GOOD" in info color for Fit.good', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FitBadge(fit: Fit.good)));

      final text = tester.widget<Text>(find.text('GOOD'));
      expect(text.style?.color, AppColors.info);
    });

    testWidgets('renders "CPU ONLY" in warning color for Fit.cpuOnly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FitBadge(fit: Fit.cpuOnly)));

      final text = tester.widget<Text>(find.text('CPU ONLY'));
      expect(text.style?.color, AppColors.warning);
    });

    testWidgets('renders "TOO BIG" in error color for Fit.tooBig', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FitBadge(fit: Fit.tooBig)));

      final text = tester.widget<Text>(find.text('TOO BIG'));
      expect(text.style?.color, AppColors.error);
    });
  });
}
