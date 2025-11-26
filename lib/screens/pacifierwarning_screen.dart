import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';

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
  bool _isProcessing = false; // Added to prevent concurrent processing
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = widget.cameraController;
    if (!_cameraController.value.isInitialized) {
      debugPrint("Câmera não inicializada, tentando inicializar...");
      try {
        await _cameraController.initialize();
      } catch (e) {
        debugPrint('Erro ao inicializar câmera: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar câmera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    if (mounted) {
      _startImageCheckLoop();
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
    if (!_isChecking ||
        !mounted ||
        !_cameraController.value.isInitialized ||
        _isProcessing) {
      debugPrint(
          "Verificação cancelada: _isChecking=$_isChecking, mounted=$mounted, cameraInitialized=${_cameraController.value.isInitialized}, isProcessing=$_isProcessing");
      return;
    }

    _isProcessing = true;
    try {
      debugPrint("Iniciando verificação de imagem...");
      final image = await _cameraController.takePicture();
      debugPrint("Imagem capturada: ${image.path}");
      final imageBytes = await File(image.path).readAsBytes();

      debugPrint("Processando imagem com Interpreter...");
      final confidence = await compute(_processImage, {
        'bytes': imageBytes,
        'interpreter': widget.interpreter, // Pass Interpreter directly
      });
      debugPrint('Confiança na PacifierWarningScreen: $confidence');

      if (confidence < 0.8) {
        debugPrint("Chupeta não detectada, voltando para WebViewScreen...");
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
    } finally {
      _isProcessing = false;
    }
  }

  static double _processImage(Map args) {
    final Uint8List bytes = args['bytes'];
    final tfl.Interpreter interpreter =
        args['interpreter']; // Receive Interpreter directly
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
  void dispose() {
    _captureTimer?.cancel();
    _isChecking = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 252, 250),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animação Lottie
            SizedBox(
              width: 250,
              height: 250,
              child: Lottie.asset(
                'assets/pacifier_warning.json',
                repeat: true, // deixa em loop
                animate: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),

            // Legenda clara
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Por favor, tire a chupeta para continuar!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Indicador
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}
