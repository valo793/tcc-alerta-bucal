import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/password_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/splash_screen.dart';
import 'services/preferences_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PreferencesModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaBucal',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/password': (context) => const PasswordScreen(),
        '/webview': (context) => const WebViewScreen(),
        '/preferences': (context) => const PreferencesScreen(),
      },
    );
  }
}
