import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/cookbook_entry.dart';
import 'package:crm/features/settings/domain/model/model_fit_result.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';

void main() {
  group('CookbookEntry', () {
    test('supportsTools defaults to true', () {
      const entry = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Claude',
        cardType: ServiceType.claudeAnthropic,
        model: 'claude-3-5-sonnet-20241022',
      );

      expect(entry.supportsTools, isTrue);
    });

    test('copyWith updates supportsTools', () {
      const entry = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.2',
        supportsTools: false,
      );

      final updated = entry.copyWith(supportsTools: true);

      expect(updated.supportsTools, isTrue);
      expect(updated.cardId, entry.cardId);
    });

    test('equality and hashCode account for supportsTools', () {
      const withTools = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.2',
        supportsTools: true,
      );
      const withoutTools = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.2',
        supportsTools: false,
      );

      expect(withTools, isNot(equals(withoutTools)));
      expect(withTools.hashCode, isNot(equals(withoutTools.hashCode)));
      expect(withTools, equals(withTools.copyWith()));
    });

    test('fitResult defaults to null', () {
      const entry = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.1:8b',
      );

      expect(entry.fitResult, isNull);
    });

    test('copyWith updates fitResult', () {
      const entry = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.1:8b',
      );
      const fit = ModelFitResult(
        vramEstimateMb: 4608,
        fit: Fit.perfect,
        mode: FitMode.gpu,
        speedTokensPerSec: 60.0,
        score: 90.0,
      );

      final updated = entry.copyWith(fitResult: fit);

      expect(updated.fitResult, fit);
      expect(updated.cardId, entry.cardId);
    });

    test('equality and hashCode account for fitResult', () {
      const fit = ModelFitResult(
        vramEstimateMb: 4608,
        fit: Fit.perfect,
        mode: FitMode.gpu,
        speedTokensPerSec: 60.0,
        score: 90.0,
      );
      const withFit = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.1:8b',
        fitResult: fit,
      );
      const withoutFit = CookbookEntry(
        cardId: 'card-1',
        cardName: 'Ollama',
        cardType: ServiceType.ollama,
        model: 'llama3.1:8b',
      );

      expect(withFit, isNot(equals(withoutFit)));
      expect(withFit.hashCode, isNot(equals(withoutFit.hashCode)));
      expect(withFit, equals(withFit.copyWith()));
    });
  });

  group('recommendedCookbookEntry', () {
    const lowScore = ModelFitResult(
      vramEstimateMb: 40000,
      fit: Fit.tooBig,
      mode: FitMode.none,
      speedTokensPerSec: 0.0,
      score: 0.14,
    );
    const highScore = ModelFitResult(
      vramEstimateMb: 4608,
      fit: Fit.perfect,
      mode: FitMode.gpu,
      speedTokensPerSec: 60.0,
      score: 91.23,
    );

    const lowEntry = CookbookEntry(
      cardId: 'ollama-1',
      cardName: 'Ollama',
      cardType: ServiceType.ollama,
      model: 'llama-2-70b-chat.Q4_K_M',
      fitResult: lowScore,
    );
    const highEntry = CookbookEntry(
      cardId: 'ollama-1',
      cardName: 'Ollama',
      cardType: ServiceType.ollama,
      model: 'llama-2-7b-chat.Q4_K_M',
      fitResult: highScore,
    );
    const noFitEntry = CookbookEntry(
      cardId: 'claude-1',
      cardName: 'Claude',
      cardType: ServiceType.claudeAnthropic,
      model: 'claude-3-5-sonnet-20241022',
    );

    test('returns the entry with the highest fitResult.score, regardless of order', () {
      expect(recommendedCookbookEntry([lowEntry, highEntry]), highEntry);
      expect(recommendedCookbookEntry([highEntry, lowEntry]), highEntry);
    });

    test('ignores entries with a null fitResult', () {
      expect(recommendedCookbookEntry([noFitEntry, lowEntry]), lowEntry);
    });

    test('returns null if no entry has a fitResult', () {
      expect(recommendedCookbookEntry([noFitEntry]), isNull);
    });

    test('returns null for an empty list', () {
      expect(recommendedCookbookEntry(const []), isNull);
    });
  });
}
