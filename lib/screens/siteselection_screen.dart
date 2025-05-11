import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/password_service.dart';
import '../services/preferences_model.dart';
import 'aboutApp_screen.dart';
import 'webview_screen.dart';
import 'package:camera/camera.dart';

class SiteSelectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SiteSelectionScreen({super.key, required this.cameras});

  @override
  State<SiteSelectionScreen> createState() => _SiteSelectionScreenState();
}

class _SiteSelectionScreenState extends State<SiteSelectionScreen> {
  final PasswordService _passwordService = PasswordService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<PreferencesModel>(context, listen: false).reloadPreferences();
  }

  Future<void> navigateToWebView(String url) async {
    bool isBlocked = await _checkIfBlocked(url);
    if (!isBlocked) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WebViewScreen(initialUrl: url, cameras: widget.cameras),
        ),
      );
    }
  }

  Future<bool> _checkIfBlocked(String url) async {
    final preferences = Provider.of<PreferencesModel>(context, listen: false);
    bool isBlocked = (url.contains('youtube') && preferences.blockYouTube) ||
        (url.contains('pluto') && preferences.blockPluto) ||
        (url.contains('khan') && preferences.blockKhan) ||
        (url.contains('escolagames') && preferences.blockEscola);

    if (isBlocked) {
      _showBlockedDialog();
    }
    return isBlocked;
  }

  Future<void> _showBlockedDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acesso Bloqueado'),
        content:
            const Text('Este site está bloqueado pelas suas preferências.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Autenticação'),
          content: const Text(
              'Toque no sensor de impressão digital para acessar as preferências.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                bool isValid =
                    await _passwordService.authenticateWithFingerprint();
                if (!mounted) return;
                Navigator.of(context).pop();
                if (isValid) {
                  Navigator.pushNamed(context, '/preferences');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Falha na autenticação por impressão digital.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione um site!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre o app',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPasswordDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => navigateToWebView('https://www.youtube.com'),
              child: const Text('YouTube'),
            ),
            ElevatedButton(
              onPressed: () => navigateToWebView(
                  'https://pluto.tv/br/live-tv/6479ff764f5ba5000878dfe2'),
              child: const Text('Pluto Tv'),
            ),
            ElevatedButton(
              onPressed: () => navigateToWebView('https://pt.khanacademy.org'),
              child: const Text('Khan Academy'),
            ),
            ElevatedButton(
              onPressed: () =>
                  navigateToWebView('https://www.escolagames.com.br'),
              child: const Text('Escola Games'),
            ),
          ],
        ),
      ),
    );
  }
}
