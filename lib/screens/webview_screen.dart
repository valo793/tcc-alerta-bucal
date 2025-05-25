import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
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

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewService webViewService;
  bool _isCapturing = true;
  bool isLoading = true;
  bool isPopupOpen = false;

  @override
  void initState() {
    super.initState();
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
    _isCapturing = false;
    super.dispose();
  }

  Future<void> _startImageCaptureLoop() async {
    while (mounted && _isCapturing) {
      await _captureAndAnalyzeImage();
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> _captureAndAnalyzeImage() async {
    if (!_isCapturing || !widget.cameraController.value.isInitialized) return;

    try {
      final image = await widget.cameraController.takePicture();
      final imageBytes = await File(image.path).readAsBytes();

      final confidence = await compute(_processImage, {
        'bytes': imageBytes,
        'modelAddress': widget.interpreter.address,
      });

      if (confidence >= 0.8) {
        _showPacifierPopup();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static double _processImage(Map args) {
    final Uint8List bytes = args['bytes'];
    final int modelAddress = args['modelAddress'];
    final interpreter = tfl.Interpreter.fromAddress(modelAddress);
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return 0.0;

    final resized = img.copyResize(decoded, width: 640, height: 640);

    final input = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(640, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

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

  void _showPacifierPopup() {
    if (!isPopupOpen) {
      isPopupOpen = true;
      _isCapturing = false;

      webViewService.controller.runJavaScript('''
        function pauseYouTubeVideos() {
          var iframes = document.getElementsByTagName('iframe');
          for (var i = 0; i < iframes.length; i++) {
            var iframe = iframes[i];
            if (iframe.src.includes('youtube.com')) {
              iframe.contentWindow.postMessage(
                '{"event":"command","func":"pauseVideo","args":""}',
                '*'
              );
            }
          }
          var videos = document.getElementsByTagName('video');
          for (var i = 0; i < videos.length; i++) {
            videos[i].pause();
          }
          console.log('Vídeos pausados');
        }
        pauseYouTubeVideos();
      ''').catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao pausar vídeo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });

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
        isPopupOpen = false;
        _isCapturing = true;

        webViewService.controller.runJavaScript('''
          function resumeYouTubeVideos() {
            var iframes = document.getElementsByTagName('iframe');
            for (var i = 0; i < iframes.length; i++) {
              var iframe = iframes[i];
              if (iframe.src.includes('youtube.com')) {
                iframe.contentWindow.postMessage(
                  '{"event":"command","func":"playVideo","args":""}',
                  '*'
                );
              }
            }
            var videos = document.getElementsByTagName('video');
            for (var i = 0; i < videos.length; i++) {
              videos[i].play();
            }
            console.log('Vídeos retomados');
          }
          resumeYouTubeVideos();
        ''').catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao retomar vídeo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });

        _startImageCaptureLoop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navegador Web e IA')),
      body: Stack(
        children: [
          WebViewWidget(controller: webViewService.controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
