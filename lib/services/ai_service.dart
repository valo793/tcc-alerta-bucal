import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class AIService {
  static AIService? _instance;
  tfl.Interpreter? interpreter;

  AIService._();

  static AIService get instance => _instance ??= AIService._();

  Future<void> init() async {
    if (interpreter == null) {
      try {
        final options = tfl.InterpreterOptions();
        interpreter = await tfl.Interpreter.fromAsset(
          'assets/modelo.tflite',
          options: options,
        );
        print('Modelo TFLite carregado com sucesso');
      } catch (e) {
        print('Erro ao carregar modelo TFLite: $e');
        rethrow;
      }
    }
  }

  bool get isInitialized => interpreter != null;

  void dispose() {
    interpreter?.close();
    interpreter = null;
    print('Interpreter TFLite fechado');
  }
}
