import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class PacifierWarningScreen extends StatefulWidget {
  final CameraController cameraController;
  final tfl.Interpreter interpreter;
  final String initialUrl;

  const PacifierWarningScreen({
    super.key,
    required this.cameraController,
    required this.interpreter,
    required this.initialUrl,
  });

  @override
  State<PacifierWarningScreen> createState() => _PacifierWarningScreenState();
}

class _PacifierWarningScreenState extends State<PacifierWarningScreen> {
  late CameraController _cameraController;
  bool _isChecking = true;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController = widget.cameraController;
      if (!_cameraController.value.isInitialized) {
        await _cameraController.initialize();
      }
      if (mounted) {
        _startImageCheckLoop();
      }
    } catch (e) {
      debugPrint('Erro ao inicializar câmera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao inicializar câmera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startImageCheckLoop() {
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isChecking || !mounted) {
        timer.cancel();
        return;
      }
      await _checkImage();
    });
  }

  Future<void> _checkImage() async {
    if (!_isChecking || !mounted || !_cameraController.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController.takePicture();
      final imageBytes = await File(image.path).readAsBytes();

      final confidence = await compute(_processImage, {
        'bytes': imageBytes,
        'modelAddress': widget.interpreter.address,
      });

      debugPrint('Confiança na PacifierWarningScreen: $confidence');
      if (confidence < 0.8) {
        _isChecking = false;
        _captureTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Por favor, retire a chupeta para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
