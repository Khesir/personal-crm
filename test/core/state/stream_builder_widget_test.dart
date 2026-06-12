import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';

class _CounterState extends StreamState<AsyncState<int>> {
  _CounterState(int initial) : super(AsyncData(initial));

  void setValue(int value) => emit(AsyncData(value));
}

void main() {
  group('AsyncStreamBuilder', () {
    testWidgets(
      'switches to the new controller\'s data when the state instance changes',
      (tester) async {
        final controllerA = _CounterState(1);
        final controllerB = _CounterState(100);

        StreamState<AsyncState<int>> active = controllerA;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AsyncStreamBuilder<int>(
                      state: active,
                      builder: (context, data) => Text('value: $data'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => active = controllerB),
                      child: const Text('switch'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        expect(find.text('value: 1'), findsOneWidget);
        expect(find.text('value: 100'), findsNothing);

        await tester.tap(find.text('switch'));
        await tester.pump();

        // Bug: after swapping to a different StreamState instance, the
        // widget should immediately reflect controllerB's data instead of
        // the stale value captured from controllerA in initState.
        expect(find.text('value: 100'), findsOneWidget);
        expect(find.text('value: 1'), findsNothing);

        controllerA.dispose();
        controllerB.dispose();
      },
    );

    testWidgets(
      'still reacts to emissions from the new controller after switching',
      (tester) async {
        final controllerA = _CounterState(1);
        final controllerB = _CounterState(100);

        StreamState<AsyncState<int>> active = controllerA;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AsyncStreamBuilder<int>(
                      state: active,
                      builder: (context, data) => Text('value: $data'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => active = controllerB),
                      child: const Text('switch'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('switch'));
        await tester.pump();

        // New emissions from controllerB should now update the UI.
        controllerB.setValue(200);
        await tester.pump();

        expect(find.text('value: 200'), findsOneWidget);

        // Emissions from the old controllerA should no longer affect the UI.
        controllerA.setValue(999);
        await tester.pump();

        expect(find.text('value: 999'), findsNothing);
        expect(find.text('value: 200'), findsOneWidget);

        controllerA.dispose();
        controllerB.dispose();
      },
    );
  });
}
