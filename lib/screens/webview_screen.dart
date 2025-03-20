import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/web_services.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;

  const WebViewScreen({super.key, required this.initialUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewService webViewService;
  bool isLoading = true;

  CameraController? _cameraController;
  XFile? _lastCapturedImage;

  @override
  void initState() {
    super.initState();
    webViewService = WebViewService(
      context: context,
      onPageFinished: _handlePageFinished,
    );
    webViewService.loadUrl(widget.initialUrl);
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController?.initialize();
      _startImageCaptureLoop();
    } catch (e) {
      debugPrint('Erro ao inicializar a câmera: $e');
    }
  }

  Future<void> _startImageCaptureLoop() async {
    while (mounted) {
      try {
        final image = await _cameraController?.takePicture();
        if (image != null) {
          setState(() {
            _lastCapturedImage = image;
          });
        }
      } catch (e) {
        print('Erro ao capturar imagem: $e');
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  void _handlePageFinished(String url) {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegador Web'),
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
          if (_lastCapturedImage != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: Image.file(
                File(_lastCapturedImage!.path),
                width: 100,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
