import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:google_fonts/google_fonts.dart';
import '../services/password_service.dart';
import '../services/preferences_model.dart';
import 'aboutApp_screen.dart';
import 'webview_screen.dart';

class SiteSelectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraController cameraController;
  final tfl.Interpreter interpreter;

  const SiteSelectionScreen({
    super.key,
    required this.cameras,
    required this.cameraController,
    required this.interpreter,
  });

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoadingPreferences) {
      _loadPreferences();
    }
  }

  Future<void> _loadPreferences() async {
    final preferences = Provider.of<PreferencesModel>(context, listen: false);
    await preferences.reloadPreferences();
    if (!mounted) return; // ✅ adicional de segurança
    setState(() => _isLoadingPreferences = false);
  }

  Future<void> navigateToWebView(String url) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final preferences = Provider.of<PreferencesModel>(context, listen: false);
      bool isBlocked = _checkIfBlocked(url, preferences);
      if (!isBlocked) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              initialUrl: url,
              cameraController: widget.cameraController,
              interpreter: widget.interpreter,
            ),
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
        title: Text('Acesso Bloqueado',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text('Este site está bloqueado pelas suas preferências.',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: GoogleFonts.nunito(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
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
          title: Text('Autenticação',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Use sua digital ou senha/PIN para acessar as preferências.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar',
                  style: GoogleFonts.nunito(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Autenticar',
                  style: GoogleFonts.nunito(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              onPressed: () async {
                bool isValid =
                    await _passwordService!.authenticateWithDeviceCredentials();
                if (!mounted) return;
                Navigator.of(context).pop();
                _handleAuthResult(isValid);
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAuthResult(bool isValid) {
    if (isValid) {
      Navigator.pushNamed(context, '/preferences');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha na autenticação.', style: GoogleFonts.nunito()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escolha sua Atividade!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
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
                    child: Column(
                      children: [
                        Text(
                          'Onde vamos hoje?',
                          style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildSiteButton(
                                context,
                                title: 'YouTube',
                                icon: Icons.video_library,
                                url: 'https://m.youtube.com/?vq=medium',
                                color: Colors.red.shade400,
                              ),
                              _buildSiteButton(
                                context,
                                title: 'Pluto TV',
                                icon: Icons.live_tv,
                                url:
                                    'https://pluto.tv/br/live-tv/6479ff764f5ba500087ascan:play',
                                color: Colors.indigo.shade400,
                              ),
                              _buildSiteButton(
                                context,
                                title: 'Khan Academy',
                                icon: Icons.school,
                                url: 'https://pt.khanacademy.org',
                                color: Colors.green.shade400,
                              ),
                              _buildSiteButton(
                                context,
                                title: 'Escola Games',
                                icon: Icons.games,
                                url: 'https://www.escolagames.com.br',
                                color: Colors.orange.shade400,
                              ),
                            ],
                          ),
                        ),
                      ],
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
    required Color color,
  }) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => navigateToWebView(url),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// extensão igual
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
