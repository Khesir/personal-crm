import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';
import 'package:crm/features/settings/domain/controller/huggingface_download_tracker.dart';
import 'package:crm/features/settings/domain/model/download_status.dart';
import 'package:crm/features/settings/domain/model/huggingface_download.dart';
import 'package:crm/features/settings/presentation/section/local_llm_models_section.dart';

void main() {
  group('LocalLlmModelsSection filtering', () {
    setUp(() {
      // Reset the app-lifetime singleton between tests.
      final tracker = HuggingFaceDownloadTracker.instance;
      for (final download in List.of(tracker.state)) {
        tracker.dismiss(download.repoId, download.quant);
      }
    });

    testWidgets('filterServiceCardId null renders all non-idle entries (regression)', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.downloading(OllamaPullProgress(status: 'pulling')),
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
        const MaterialApp(home: LocalLlmModelsSection()),
      );

      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsOneWidget);
    });

    testWidgets('non-null filterServiceCardId renders only matching entries', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.downloading(OllamaPullProgress(status: 'pulling')),
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
        const MaterialApp(home: LocalLlmModelsSection(filterServiceCardId: 'card-1')),
      );

      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('Model B'), findsNothing);
    });

    testWidgets('renders nothing when the filtered list is empty', (tester) async {
      final tracker = HuggingFaceDownloadTracker.instance;
      tracker.track(const HuggingFaceDownload(
        repoId: 'repo/a',
        quant: 'Q4_K_M',
        displayName: 'Model A',
        status: DownloadStatus.downloading(OllamaPullProgress(status: 'pulling')),
        serviceCardId: 'card-1',
      ));

      await tester.pumpWidget(
        const MaterialApp(home: LocalLlmModelsSection(filterServiceCardId: 'card-does-not-exist')),
      );

      expect(find.text('Model A'), findsNothing);
      expect(find.text('Models'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
