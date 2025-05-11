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
  bool _isLoadingPreferences = true;
  bool _isNavigating = false;
  PasswordService? _passwordService;

  static const _blockedDomains = {
    'youtube': 'blockYouTube',
    'pluto': 'blockPluto',
    'khan': 'blockKhan',
    'escolagames': 'blockEscola',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = Provider.of<PreferencesModel>(context, listen: false);
    await preferences.reloadPreferences();
    setState(() {
      _isLoadingPreferences = false;
    });
  }

  Future<void> navigateToWebView(String url) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final preferences = Provider.of<PreferencesModel>(context, listen: false);
      bool isBlocked = _checkIfBlocked(url, preferences);
      if (!isBlocked) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WebViewScreen(initialUrl: url, cameras: widget.cameras),
          ),
        );
      } else {
        await _showBlockedDialog();
      }
    } finally {
      _isNavigating = false;
    }
  }

  bool _checkIfBlocked(String url, PreferencesModel preferences) {
    for (var entry in _blockedDomains.entries) {
      if (url.contains(entry.key)) {
        return preferences.getProperty(entry.value) as bool;
      }
    }
    return false;
  }

  Future<void> _showBlockedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Acesso Bloqueado'),
        content:
            const Text('Este site está bloqueado pelas suas preferências.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog() async {
    _passwordService ??= PasswordService();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Autenticação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.fingerprint, size: 48, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Toque no sensor de impressão digital para acessar as preferências.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child:
                  const Text('Confirmar', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                bool isValid =
                    await _passwordService!.authenticateWithFingerprint();
                Navigator.of(context).pop();
                if (isValid) {
                  Navigator.pushNamed(context, '/preferences');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Falha na autenticação.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selecione um Site'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Sobre o app',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AboutAppScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configurações',
              onPressed: _showPasswordDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoadingPreferences
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          const Text(
                            'Escolha um site para acessar:',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _buildSiteButton(
                            context,
                            title: 'YouTube',
                            icon: Icons.video_library,
                            url: 'https://m.youtube.com/?vq=medium',
                          ),
                          const SizedBox(height: 12),
                          _buildSiteButton(
                            context,
                            title: 'Pluto TV',
                            icon: Icons.live_tv,
                            url:
                                'https://pluto.tv/br/live-tv/6479ff764f5ba500087ascan:play',
                          ),
                          const SizedBox(height: 12),
                          _buildSiteButton(
                            context,
                            title: 'Khan Academy',
                            icon: Icons.school,
                            url: 'https://pt.khanacademy.org',
                          ),
                          const SizedBox(height: 12),
                          _buildSiteButton(
                            context,
                            title: 'Escola Games',
                            icon: Icons.games,
                            url: 'https://www.escolagames.com.br',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSiteButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String url,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => navigateToWebView(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

extension PreferencesModelExtension on PreferencesModel {
  dynamic getProperty(String property) {
    switch (property) {
      case 'blockYouTube':
        return blockYouTube;
      case 'blockPluto':
        return blockPluto;
      case 'blockKhan':
        return blockKhan;
      case 'blockEscola':
        return blockEscola;
      default:
        return false;
    }
  }
}
