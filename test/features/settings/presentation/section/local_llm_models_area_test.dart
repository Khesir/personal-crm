import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/controller/huggingface_download_tracker.dart';
import 'package:crm/features/settings/domain/model/download_status.dart';
import 'package:crm/features/settings/domain/model/health_status.dart';
import 'package:crm/features/settings/domain/model/huggingface_download.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/presentation/section/local_llm_models_area.dart';

const _ollamaCard = ServiceCard(
  id: 'card-1',
  category: ServiceCategory.localLlm,
  type: ServiceType.ollama,
  name: 'Ollama',
  fields: {},
);

const _customCard = ServiceCard(
  id: 'card-2',
  category: ServiceCategory.localLlm,
  type: ServiceType.customLocal,
  name: 'Custom Engine',
  fields: {},
);

void main() {
  group('LocalLlmModelsArea', () {
    setUp(() {
      final tracker = HuggingFaceDownloadTracker.instance;
      for (final download in List.of(tracker.state)) {
        tracker.dismiss(download.repoId, download.quant);
      }
    });

    testWidgets('with >=1 engine, chip row renders and filtering works end-to-end', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.added(),
        serviceCardId: 'card-1',
      ));
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/b',
        quant: 'Q4_K_M',
        displayName: 'Model B',
        status: DownloadStatus.added(),
        serviceCardId: 'card-2',
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: LocalLlmModelsArea(
            engines: [_ollamaCard, _customCard],
            healthStatuses: {},
            healthStream: Stream.empty(),
          ),
        ),
      );

      // Chip row renders.
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('Custom Engine'), findsOneWidget);

      // Default: All -> both shown.
      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsOneWidget);

      // Tap Ollama chip -> only Model A shown.
      await tester.tap(find.text('Ollama'));
      await tester.pump();

      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsNothing);

      // Tap Ollama chip again (toggle back to All) -> both shown.
      await tester.tap(find.text('Ollama'));
      await tester.pump();

      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsOneWidget);
    });

    testWidgets('with zero engines, no chip row and Models renders unfiltered', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.added(),
        serviceCardId: 'card-1',
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: LocalLlmModelsArea(
            engines: [],
            healthStatuses: {},
            healthStream: Stream.empty(),
          ),
        ),
      );

      expect(find.text('All'), findsNothing);
      expect(find.text('Model A'), findsOneWidget);
    });

    testWidgets('resets filter to "All" when the selected engine card is removed', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.added(),
        serviceCardId: 'card-1',
      ));
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/b',
        quant: 'Q4_K_M',
        displayName: 'Model B',
        status: DownloadStatus.added(),
        serviceCardId: 'card-2',
      ));

      final widgetKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: LocalLlmModelsArea(
            key: widgetKey,
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const <String, HealthStatus>{},
            healthStream: const Stream.empty(),
          ),
        ),
      );

      // Select Ollama -> only Model A shown.
      await tester.tap(find.text('Ollama'));
      await tester.pump();

      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsNothing);

      // Rebuild with the Ollama card removed from `engines`.
      await tester.pumpWidget(
        MaterialApp(
          home: LocalLlmModelsArea(
            key: widgetKey,
            engines: const [_customCard],
            healthStatuses: const <String, HealthStatus>{},
            healthStream: const Stream.empty(),
          ),
        ),
      );
      await tester.pump();

      // Filter resets to All -> both models shown again, no chip highlighted
      // as Ollama (it no longer exists in the chip row).
      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsOneWidget);
      expect(find.text('Ollama'), findsNothing);
    });
  });
}
