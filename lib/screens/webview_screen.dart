import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import '../services/web_services.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final List<CameraDescription> cameras;

  const WebViewScreen({
    super.key,
    required this.initialUrl,
    required this.cameras,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewService webViewService;
  CameraController? _cameraController;
  XFile? _capturedImage;
  tfl.Interpreter? _interpreter;
  bool _isLoadingAI = false;
  bool isLoading = true;
  String _result = "Capturando imagem...";

  @override
  void initState() {
    super.initState();
    webViewService = WebViewService(
      context: context,
      onPageFinished: (_) => setState(() => isLoading = false),
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
      _interpreter = await tfl.Interpreter.fromAsset(
        'assets/modelo.tflite',
        options: options,
      );
    } catch (e) {
      setState(() => _result = "Erro ao carregar modelo");
    }
  }

  Future<void> _startImageCaptureLoop() async {
    while (mounted) {
      await _captureAndAnalyzeImage();
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> _captureAndAnalyzeImage() async {
    if (!(_cameraController?.value.isInitialized ?? false)) return;

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _result = "Analisando...";
        _isLoadingAI = true;
      });

      final imageBytes = await File(image.path).readAsBytes();

      final isolateResult = await compute(_processImage, {
        'bytes': imageBytes,
        'modelAddress': _interpreter!.address,
      });

      setState(() {
        _result = isolateResult >= 0.8
            ? "Chupeta detectada!\nChance: ${(isolateResult * 100).toStringAsFixed(1)}%"
            : "Nenhuma chupeta encontrada\nChance: ${(isolateResult * 100).toStringAsFixed(1)}%";
        _isLoadingAI = false;
      });
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() {
        _result = "Erro ao processar imagem";
        _isLoadingAI = false;
      });
    }
  }

  // Alterando para aceitar o Uint8List e fazer o processamento da imagem corretamente
  static double _processImage(Map args) {
    final Uint8List bytes = args['bytes']; // Alterando para Uint8List
    final int modelAddress = args['modelAddress'];
    final interpreter = tfl.Interpreter.fromAddress(modelAddress);
    final decoded =
        img.decodeImage(Uint8List.fromList(bytes)); // Usando Uint8List
    if (decoded == null) return 0.0;

    final resized = img.copyResize(decoded, width: 640, height: 640);

    final input = List.generate(
        1,
        (_) => List.generate(
            640,
            (y) => List.generate(640, (x) {
                  final pixel = resized.getPixel(x, y);
                  return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
                })));

    final output = List.generate(
      1,
      (_) => List.generate(5, (_) => List.filled(8400, 0.0)),
    );

    interpreter.run(input, output);

    double maxConfidence = 0.0;
    for (int i = 0; i < output[0][0].length; i++) {
      maxConfidence =
          output[0][4][i] > maxConfidence ? output[0][4][i] : maxConfidence;
    }

    return maxConfidence;
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
