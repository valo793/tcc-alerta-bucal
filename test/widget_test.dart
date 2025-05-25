import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_alertabucal/main.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tcc_alertabucal/services/ai_service.dart'; // Importe o AIService

void main() {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  late tfl.Interpreter interpreter;

  setUpAll(() async {
    // Inicializar câmeras
    cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await cameraController.initialize();

    // Inicializar AIService
    await AIService.instance.init();
    interpreter = AIService.instance.interpreter!;
  });

  tearDownAll(() async {
    // Liberar recursos
    await cameraController.dispose();
    AIService.instance.dispose();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Instanciar MyApp com os parâmetros necessários
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp(
        cameras: cameras,
        cameraController: cameraController,
        interpreter: interpreter,
      ));
    });

    // Verificar se o app está rodando sem erro
    expect(find.byType(MyApp), findsOneWidget);
  });
}
