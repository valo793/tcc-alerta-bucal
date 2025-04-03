import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/password_service.dart';
import '../services/preferences_model.dart';
import 'webview_screen.dart';
import 'package:camera/camera.dart';

class SiteSelectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SiteSelectionScreen({super.key, required this.cameras});

  @override
  State<SiteSelectionScreen> createState() => _SiteSelectionScreenState();
}

class _SiteSelectionScreenState extends State<SiteSelectionScreen> {
  final _passwordController = TextEditingController();
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
          title: const Text('Insira sua senha'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Por favor, insira sua senha para acessar as preferências.'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                ),
              ],
            ),
          ),
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
                bool isValid = await _passwordService
                    .validatePassword(_passwordController.text);
                if (isValid) {
                  _passwordController.clear();
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/preferences');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Senha incorreta. Tente novamente.')),
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
