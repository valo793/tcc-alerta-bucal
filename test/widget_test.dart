// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tcc_alertabucal/main.dart';

void main() {
  late List<CameraDescription> cameras;

  setUpAll(() async {
    // Obtém as câmeras disponíveis antes de rodar os testes
    cameras = await availableCameras();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Espera as câmeras estarem disponíveis antes de rodar o teste
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp(cameras: cameras));
    });

    // Exemplo: Verifique se o app está rodando sem erro
    expect(find.byType(MyApp), findsOneWidget);
  });
}
