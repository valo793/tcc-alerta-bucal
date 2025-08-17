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

class MyApp extends StatefulWidget {
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
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (!widget.cameraController.value.isInitialized) {
        widget.cameraController.initialize().then((_) {
          if (mounted) {
            widget.cameraController.startImageStream((_) {});
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cameraController.dispose();
    AIService.instance.dispose(); // Close Interpreter
    super.dispose();
  }

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
              cameras: widget.cameras,
              cameraController: widget.cameraController,
              interpreter: widget.interpreter,
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/webview') {
          final args = settings.arguments as String?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => WebViewScreen(
                initialUrl: args,
                cameraController: widget.cameraController,
                interpreter: widget.interpreter,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
