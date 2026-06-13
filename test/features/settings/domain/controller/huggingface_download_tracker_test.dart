import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';
import 'package:crm/features/settings/domain/controller/huggingface_download_tracker.dart';
import 'package:crm/features/settings/domain/model/download_status.dart';
import 'package:crm/features/settings/domain/model/huggingface_download.dart';

void main() {
  group('HuggingFaceDownloadTracker', () {
    test('statusFor returns idle for an untracked (repoId, quant)', () {
      final tracker = HuggingFaceDownloadTracker();

      expect(tracker.statusFor('TheBloke/Llama-2-7B-Chat-GGUF', 'Q4_K_M'), isA<DownloadStatusIdle>());
    });

    test('track() inserts a new entry and statusFor returns its status', () {
      final tracker = HuggingFaceDownloadTracker();

      tracker.track(const HuggingFaceDownload(
        repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
        quant: 'Q4_K_M',
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.downloading(OllamaPullProgress(status: 'starting')),
      ));

      final status = tracker.statusFor('TheBloke/Llama-2-7B-Chat-GGUF', 'Q4_K_M');
      expect(status, isA<DownloadStatusDownloading>());
      expect((status as DownloadStatusDownloading).progress.status, 'starting');
    });

    test('track() replaces the existing entry for the same (repoId, quant)', () {
      final tracker = HuggingFaceDownloadTracker();
      const repoId = 'TheBloke/Llama-2-7B-Chat-GGUF';
      const quant = 'Q4_K_M';

      tracker.track(const HuggingFaceDownload(
        repoId: repoId,
        quant: quant,
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.downloading(OllamaPullProgress(status: 'starting')),
      ));
      tracker.track(const HuggingFaceDownload(
        repoId: repoId,
        quant: quant,
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.added(),
      ));

      expect(tracker.state, hasLength(1));
      expect(tracker.statusFor(repoId, quant), isA<DownloadStatusAdded>());
    });

    test('dismiss() removes the tracked entry for (repoId, quant)', () {
      final tracker = HuggingFaceDownloadTracker();
      const repoId = 'TheBloke/Llama-2-7B-Chat-GGUF';
      const quant = 'Q4_K_M';

      tracker.track(const HuggingFaceDownload(
        repoId: repoId,
        quant: quant,
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.added(),
      ));
      tracker.dismiss(repoId, quant);

      expect(tracker.state, isEmpty);
      expect(tracker.statusFor(repoId, quant), isA<DownloadStatusIdle>());
    });

    test('dismiss() on an untracked (repoId, quant) is a no-op', () {
      final tracker = HuggingFaceDownloadTracker();

      tracker.track(const HuggingFaceDownload(
        repoId: 'a',
        quant: 'q',
        displayName: 'A',
        status: DownloadStatus.added(),
      ));
      tracker.dismiss('b', 'q');

      expect(tracker.state, hasLength(1));
    });

    test('track() emits the updated list on the stream', () async {
      final tracker = HuggingFaceDownloadTracker();
      final emissions = <List<HuggingFaceDownload>>[];
      final subscription = tracker.stream.listen(emissions.add);

      tracker.track(const HuggingFaceDownload(
        repoId: 'a',
        quant: 'q',
        displayName: 'A',
        status: DownloadStatus.added(),
      ));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.key, 'a:q');
    });
  });
}
