import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/model_name_parser.dart';

void main() {
  group('ModelNameParser', () {
    test('parseParamsBillions reads a B/b-suffixed number', () {
      expect(ModelNameParser.parseParamsBillions('llama-2-7b-chat.Q4_K_M.gguf'), 7.0);
      expect(ModelNameParser.parseParamsBillions('TheBloke/Llama-2-7B-Chat-GGUF'), 7.0);
      expect(ModelNameParser.parseParamsBillions('qwen2.5-coder:7b-instruct-q4_K_M'), 7.0);
    });

    test('parseParamsBillions uses the last B-suffixed number for MoE-style names', () {
      expect(ModelNameParser.parseParamsBillions('Mixtral-2x7B'), 7.0);
    });

    test('parseParamsBillions returns null when no number is B/b-suffixed', () {
      expect(ModelNameParser.parseParamsBillions('sentence-transformers/all-MiniLM-L6-v2'), isNull);
    });

    test('parseQuant reads a recognized GGUF quant label, normalized to uppercase', () {
      expect(ModelNameParser.parseQuant('llama-2-7b-chat.Q4_K_M.gguf'), 'Q4_K_M');
      expect(ModelNameParser.parseQuant('qwen2.5-coder:7b-instruct-q4_K_M'), 'Q4_K_M');
      expect(ModelNameParser.parseQuant('model.q8_0.gguf'), 'Q8_0');
      expect(ModelNameParser.parseQuant('model.f16.gguf'), 'F16');
    });

    test('parseQuant returns null when no recognized quant label is present', () {
      expect(ModelNameParser.parseQuant('llama3.1:8b'), isNull);
    });
  });
}
