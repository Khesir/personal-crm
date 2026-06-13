import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/download_status.dart';
import 'package:crm/features/settings/domain/model/huggingface_download.dart';

void main() {
  group('HuggingFaceDownload.serviceCardId', () {
    test('defaults to null when not provided', () {
      const download = HuggingFaceDownload(
        repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
        quant: 'Q4_K_M',
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.idle(),
      );

      expect(download.serviceCardId, isNull);
    });

    test('can be set via constructor', () {
      const download = HuggingFaceDownload(
        repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
        quant: 'Q4_K_M',
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.idle(),
        serviceCardId: 'ollama-1',
      );

      expect(download.serviceCardId, 'ollama-1');
    });

    test('copyWith preserves serviceCardId when not overridden', () {
      const download = HuggingFaceDownload(
        repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
        quant: 'Q4_K_M',
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.idle(),
        serviceCardId: 'ollama-1',
      );

      final copy = download.copyWith(status: const DownloadStatus.added());

      expect(copy.serviceCardId, 'ollama-1');
      expect(copy.status, isA<DownloadStatusAdded>());
    });

    test('copyWith can override serviceCardId', () {
      const download = HuggingFaceDownload(
        repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
        quant: 'Q4_K_M',
        displayName: 'Llama-2-7B-Chat-GGUF',
        status: DownloadStatus.idle(),
        serviceCardId: 'ollama-1',
      );

      final copy = download.copyWith(serviceCardId: 'ollama-2');

      expect(copy.serviceCardId, 'ollama-2');
    });
  });
}
