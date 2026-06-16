import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/presentation/widget/composer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Composer', () {
    testWidgets('shows the active model badge by default', (tester) async {
      await tester.pumpWidget(
        _wrap(Composer(
          activeModel: 'claude-sonnet-4-6',
          isStreaming: false,
          onSend: (_) {},
        )),
      );

      expect(find.text('claude-sonnet-4-6'), findsOneWidget);
    });

    testWidgets('hides the active model badge when showModelBadge is false', (tester) async {
      await tester.pumpWidget(
        _wrap(Composer(
          activeModel: 'claude-sonnet-4-6',
          isStreaming: false,
          onSend: (_) {},
          showModelBadge: false,
        )),
      );

      expect(find.text('claude-sonnet-4-6'), findsNothing);
    });
  });
}
