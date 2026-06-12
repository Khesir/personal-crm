import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/model/service_type_metadata.dart';

void main() {
  group('kServiceTypeLabels', () {
    test('has a non-empty entry for every ServiceType value', () {
      for (final type in ServiceType.values) {
        expect(kServiceTypeLabels[type], isNotNull);
        expect(kServiceTypeLabels[type], isNotEmpty);
      }
    });

    test('groq label is "Groq"', () {
      expect(kServiceTypeLabels[ServiceType.groq], 'Groq');
    });

    test('gemini label is "Gemini"', () {
      expect(kServiceTypeLabels[ServiceType.gemini], 'Gemini');
    });

    test('openRouter label is "OpenRouter"', () {
      expect(kServiceTypeLabels[ServiceType.openRouter], 'OpenRouter');
    });

    test('openai label is "OpenAI"', () {
      expect(kServiceTypeLabels[ServiceType.openai], 'OpenAI');
    });

    test('deepSeek label is "DeepSeek"', () {
      expect(kServiceTypeLabels[ServiceType.deepSeek], 'DeepSeek');
    });

    test('mistral label is "Mistral"', () {
      expect(kServiceTypeLabels[ServiceType.mistral], 'Mistral');
    });

    test('nvidia label is "NVIDIA"', () {
      expect(kServiceTypeLabels[ServiceType.nvidia], 'NVIDIA');
    });

    test('openCodeZen label is "OpenCode Zen"', () {
      expect(kServiceTypeLabels[ServiceType.openCodeZen], 'OpenCode Zen');
    });
  });

  group('kServiceTypeDefaultBaseUrls', () {
    test('groq default base URL is https://api.groq.com/openai/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.groq], 'https://api.groq.com/openai/v1');
    });

    test('gemini default base URL is https://generativelanguage.googleapis.com/v1beta/openai', () {
      expect(
        kServiceTypeDefaultBaseUrls[ServiceType.gemini],
        'https://generativelanguage.googleapis.com/v1beta/openai',
      );
    });

    test('openRouter default base URL is https://openrouter.ai/api/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.openRouter], 'https://openrouter.ai/api/v1');
    });

    test('openai default base URL is https://api.openai.com/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.openai], 'https://api.openai.com/v1');
    });

    test('deepSeek default base URL is https://api.deepseek.com/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.deepSeek], 'https://api.deepseek.com/v1');
    });

    test('mistral default base URL is https://api.mistral.ai/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.mistral], 'https://api.mistral.ai/v1');
    });

    test('nvidia default base URL is https://integrate.api.nvidia.com/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.nvidia], 'https://integrate.api.nvidia.com/v1');
    });

    test('openCodeZen default base URL is https://opencode.ai/zen/v1', () {
      expect(kServiceTypeDefaultBaseUrls[ServiceType.openCodeZen], 'https://opencode.ai/zen/v1');
    });
  });
}
