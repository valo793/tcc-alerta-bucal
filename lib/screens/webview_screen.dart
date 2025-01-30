import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/web_services.dart';
import '../services/preferences_model.dart';
import '../services/password_service.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewService webViewService;
  String currentUrl = 'https://youtube.com'; // URL inicial padrão
  bool isLoading = true;
  final _passwordController = TextEditingController();
  final PasswordService _passwordService = PasswordService();

  @override
  void initState() {
    super.initState();
    webViewService = WebViewService(
      context: context,
      onPageFinished: _handlePageFinished,
    );
    // Não carregar mais diretamente no initState
    // A navegação inicial será feita manualmente após verificar as preferências
    Future.microtask(() => loadSite(currentUrl));
  }

  // Função chamada quando o carregamento da página termina
  void _handlePageFinished(String url) {
    setState(() {
      isLoading = false;
    });
  }

  // Função para exibir o pop-up de senha
  Future<void> _showPasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // O usuário precisa inserir a senha ou cancelar
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
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                // Validação da senha utilizando a instância do serviço
                bool isValid = await _passwordService
                    .validatePassword(_passwordController.text);
                if (isValid) {
                  _passwordController.clear(); // Limpa o campo da senha
                  Navigator.of(context).pop(); // Fecha o diálogo
                  Navigator.pushNamed(
                      context, '/preferences'); // Vai para as preferências
                } else {
                  // Exibe uma mensagem de erro
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

  // Função para carregar uma nova URL no WebView, verificando bloqueios
  void loadSite(String url) {
    final preferences = Provider.of<PreferencesModel>(context, listen: false);

    // Verifica bloqueios
    if (preferences.blockYouTube && url.startsWith('https://www.youtube.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('YouTube está bloqueado pelas preferências.')),
      );
      return;
    }

    if (preferences.blockTikTok && url.startsWith('https://www.tiktok.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('TikTok está bloqueado pelas preferências.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      currentUrl = url;
    });

    webViewService.loadUrl(currentUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showPasswordDialog(); // Exibe o pop-up
            },
          ),
          ElevatedButton(
            onPressed: () => loadSite('https://www.youtube.com'),
            child: const Text('YouTube'),
          ),
          ElevatedButton(
            onPressed: () => loadSite('https://www.youtubekids.com'),
            child: const Text('YouTube Kids'),
          ),
          ElevatedButton(
            onPressed: () => loadSite('https://www.tiktok.com'),
            child: const Text('TikTok'),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: webViewService.controller,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
