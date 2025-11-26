import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../services/web_services.dart';
import 'pacifierWarning_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;
  final CameraController cameraController;
  final tfl.Interpreter interpreter;

  const WebViewScreen({
    super.key,
    required this.initialUrl,
    required this.cameraController,
    required this.interpreter,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewService webViewService;
  bool _isCapturing = true;
  bool _isProcessing = false;
  bool isLoading = true;
  bool isPopupOpen = false;
  bool _isDisposed = false;
  Timer? _loopTimer;

  static const platform = MethodChannel("com.example.webview/audio");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    webViewService = WebViewService(
      context: context,
      onPageFinished: (_) => setState(() => isLoading = false),
    );
    webViewService.loadUrl(widget.initialUrl);

    if (widget.cameraController.value.isInitialized) {
      _startImageCaptureLoop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Câmera não inicializada.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isCapturing = false;
    _isDisposed = true;
    _loopTimer?.cancel();
    if (widget.cameraController.value.isStreamingImages) {
      widget.cameraController.stopImageStream();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _isCapturing = false;
      widget.cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed && !_isCapturing) {
      _isCapturing = true;
      if (widget.cameraController.value.isInitialized) {
        widget.cameraController.startImageStream((_) {});
        _startImageCaptureLoop();
      }
    }
  }

  void _startImageCaptureLoop() {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isCapturing || _isDisposed) return;
      await _captureAndAnalyzeImage();
    });
  }

  Future<void> _captureAndAnalyzeImage() async {
    if (!_isCapturing ||
        !widget.cameraController.value.isInitialized ||
        _isProcessing ||
        _isDisposed) {
      return;
    }

    _isProcessing = true;
    try {
      final image = await widget.cameraController.takePicture();
      final imageBytes = await File(image.path).readAsBytes();

      // Processamento pesado (resize e normalização) em isolate
      final input = await compute(_preprocessImage, imageBytes);
      if (input.isEmpty) {
        debugPrint("Falha ao pré-processar imagem");
        return;
      }

      // Execução do modelo no main isolate (seguro)
      final output = List.generate(
        1,
        (_) => List.generate(5, (_) => List.filled(8400, 0.0)),
      );

      widget.interpreter.run(input, output);

      // Extrai confiança máxima
      double maxConfidence = 0.0;
      for (int i = 0; i < output[0][0].length; i++) {
        if (output[0][4][i] > maxConfidence) {
          maxConfidence = output[0][4][i];
        }
      }

      debugPrint("Confiança obtida: $maxConfidence");

      if (maxConfidence >= 0.8 && !_isDisposed) {
        _showPacifierPopup();
      }
    } catch (e) {
      debugPrint("Erro no processamento: $e");
    } finally {
      _isProcessing = false;
    }
  }

  static List _preprocessImage(Uint8List bytes) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return [];

    final resized = img.copyResize(decoded, width: 640, height: 640);

    return List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(640, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );
  }

  Future<void> muteWebView() async {
    try {
      await platform.invokeMethod("mute");
    } catch (e) {
      debugPrint("Erro ao mutar áudio: $e");
    }
  }

  Future<void> unmuteWebView() async {
    try {
      await platform.invokeMethod("unmute");
    } catch (e) {
      debugPrint("Erro ao desmutar áudio: $e");
    }
  }

  void _showPacifierPopup() {
    if (isPopupOpen || _isDisposed) return;

    isPopupOpen = true;
    _isCapturing = false;
    widget.cameraController.stopImageStream();
    muteWebView();

    webViewService.controller.runJavaScript('''
      document.querySelectorAll('video, iframe').forEach(v => {
        try {
          if (v.src && v.src.includes('youtube.com')) {
            v.contentWindow.postMessage(
              '{"event":"command","func":"pauseVideo","args":""}', '*');
          } else if (v.tagName === 'VIDEO') {
            v.pause();
          }
        } catch (e) {}
      });
    ''');

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => PacifierWarningScreen(
          cameraController: widget.cameraController,
          interpreter: widget.interpreter,
          initialUrl: widget.initialUrl,
        ),
      ),
    )
        .then((_) {
      if (_isDisposed) return;

      isPopupOpen = false;
      _isCapturing = true;
      unmuteWebView();

      webViewService.controller.runJavaScript('''
        document.querySelectorAll('video, iframe').forEach(v => {
          try {
            if (v.src && v.src.includes('youtube.com')) {
              v.contentWindow.postMessage(
                '{"event":"command","func":"playVideo","args":""}', '*');
            } else if (v.tagName === 'VIDEO') {
              v.play();
            }
          } catch (e) {}
        });
      ''');

      if (widget.cameraController.value.isInitialized) {
        widget.cameraController.startImageStream((_) {});
        _startImageCaptureLoop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voltar')),
      body: Stack(
        children: [
          WebViewWidget(controller: webViewService.controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
        ],
      ),
    );
  }
}
