import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import '../services/web_services.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final List<CameraDescription> cameras;

  const WebViewScreen(
      {super.key, required this.initialUrl, required this.cameras});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewService webViewService;
  bool isLoading = true;

  CameraController? _cameraController;
  XFile? _capturedImage;
  tfl.Interpreter? _interpreter;
  String _result = "Capturando imagem...";
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    webViewService = WebViewService(
      context: context,
      onPageFinished: _handlePageFinished,
    );
    webViewService.loadUrl(widget.initialUrl);
    _initializeCamera();
    _loadModel();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final frontCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first,
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

  Future<void> _loadModel() async {
    try {
      final options = tfl.InterpreterOptions();
      _interpreter = await tfl.Interpreter.fromAsset('assets/modelo.tflite',
          options: options);
    } catch (e) {
      setState(() => _result = "Erro ao carregar modelo");
    }
  }

  Future<void> _startImageCaptureLoop() async {
    while (mounted) {
      await _captureImage();
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _result = "Analisando...";
        _isLoadingAI = true;
      });
      await _analyzeImage();
      setState(() => _isLoadingAI = false);
    } catch (e) {
      debugPrint('Erro ao capturar imagem: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_interpreter == null || _capturedImage == null) {
      setState(() => _result = "Erro ao processar imagem");
      return;
    }

    try {
      final imageBytes = await File(_capturedImage!.path).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        setState(() => _result = "Erro ao decodificar imagem");
        return;
      }

      final resizedImage = img.copyResize(image, width: 640, height: 640);

      var input = List.generate(
          1,
          (_) => List.generate(
              640, (_) => List.generate(640, (_) => List.filled(3, 0.0))));
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      var output = List.generate(
          1, (_) => List.generate(5, (_) => List.filled(8400, 0.0)));
      _interpreter!.run(input, output);

      final double confidence = processDetections(output);
      const double threshold = 0.8;

      setState(() {
        _result = confidence >= threshold
            ? "Chupeta detectada!\nChance: ${(confidence * 100).toStringAsFixed(1)}%"
            : "Nenhuma chupeta encontrada\nChance: ${(confidence * 100).toStringAsFixed(1)}%";
      });
    } catch (e) {
      setState(() => _result = "Erro: $e");
    }
  }

  double processDetections(List output) {
    double maxConfidence = 0.0;
    for (var i = 0; i < output[0][0].length; i++) {
      double confidence = output[0][4][i];
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
      }
    }
    return maxConfidence;
  }

  void _handlePageFinished(String url) {
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navegador Web e IA')),
      body: Stack(
        children: [
          WebViewWidget(controller: webViewService.controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (_capturedImage != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: Image.file(
                File(_capturedImage!.path),
                width: 100,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                _isLoadingAI ? "Analisando..." : _result,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
