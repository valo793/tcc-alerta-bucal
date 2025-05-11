import 'package:flutter/material.dart';
import '../services/password_service.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final PasswordService passwordService = PasswordService();
  bool canUseBiometrics = false;
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    bool available = await passwordService.isFingerprintAvailable();
    setState(() {
      canUseBiometrics = available;
    });
  }

  Future<void> _authenticateBiometric() async {
    setState(() {
      isAuthenticating = true;
    });

    final isValid = await passwordService.authenticateWithFingerprint();

    if (!mounted) return;

    setState(() {
      isAuthenticating = false;
    });

    if (isValid) {
      Navigator.pushReplacementNamed(context, '/site-selection');
    } else {
      _showErrorDialog('Falha na autenticação por impressão digital.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticação')),
      body: Center(
        child: canUseBiometrics
            ? isAuthenticating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _authenticateBiometric,
                    child: const Text('Autenticar com digital'),
                  )
            : const Text(
                'Impressão digital não disponível ou não configurada.'),
      ),
    );
  }
}
