import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/password_screen.dart';
import 'screens/passwordrecovery_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/siteselection_screen.dart';
import 'services/preferences_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras(); // Obtém as câmeras

  runApp(
    ChangeNotifierProvider(
      create: (_) => PreferencesModel(),
      child: MyApp(cameras: cameras), // Passa as câmeras para o app
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaBucal',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/password': (context) => const PasswordScreen(),
        '/preferences': (context) => const PreferencesScreen(),
        '/site-selection': (context) => SiteSelectionScreen(cameras: cameras),
        '/passwordrecovery': (context) => const PasswordRecoveryScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/webview') {
          final args = settings.arguments as String?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) =>
                  WebViewScreen(initialUrl: args, cameras: cameras),
            );
          }
        }
        return null;
      },
    );
  }
}
