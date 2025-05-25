import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/password_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/siteselection_screen.dart';
import 'services/preferences_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'services/ai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar câmeras
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );
  final cameraController = CameraController(
    frontCamera,
    ResolutionPreset.medium,
    imageFormatGroup: ImageFormatGroup.jpeg,
  );
  await cameraController.initialize();

  // Inicializar AIService
  await AIService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => PreferencesModel(),
      child: MyApp(
        cameras: cameras,
        cameraController: cameraController,
        interpreter: AIService.instance.interpreter!,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final CameraController cameraController;
  final tfl.Interpreter interpreter;

  const MyApp({
    super.key,
    required this.cameras,
    required this.cameraController,
    required this.interpreter,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaBucal',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/password': (context) => const PasswordScreen(),
        '/preferences': (context) => const PreferencesScreen(),
        '/site-selection': (context) => SiteSelectionScreen(
              cameras: cameras,
              cameraController: cameraController,
              interpreter: interpreter,
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/webview') {
          final args = settings.arguments as String?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => WebViewScreen(
                initialUrl: args,
                cameraController: cameraController,
                interpreter: interpreter,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
