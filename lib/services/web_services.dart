import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'preferences_model.dart';

class WebViewService {
  late final WebViewController controller;

  BuildContext context;

  WebViewService(
      {required this.context, required Function(String) onPageFinished}) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            onPageFinished(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            final preferences =
                Provider.of<PreferencesModel>(context, listen: true);

            if (preferences.blockYouTube &&
                request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            if (preferences.blockPluto && request.url.contains('pluto.tv')) {
              return NavigationDecision.prevent;
            }
            if (preferences.blockKhan &&
                request.url.contains('khanacademy.org')) {
              return NavigationDecision.prevent;
            }
            if (preferences.blockEscola &&
                request.url.contains('escolagames.com.br')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void loadUrl(String url) {
    controller.loadRequest(Uri.parse(url));
  }
}
