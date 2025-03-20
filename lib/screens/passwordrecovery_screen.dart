import 'package:flutter/material.dart';
import '../services/password_service.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final PasswordService passwordService = PasswordService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Função para redefinir a senha
  Future<void> _resetPassword() async {
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Os campos não podem estar vazios.');
      return;
    }

    if (newPassword == confirmPassword) {
      await passwordService.savePassword(newPassword);
      Navigator.pushReplacementNamed(context, '/site-selection');
    } else {
      _showErrorDialog('As senhas não correspondem.');
    }
  }

  // Exibe um alerta em caso de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperação de Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Digite sua nova senha:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Nova senha'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirme a senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text('Redefinir Senha'),
            ),
          ],
        ),
      ),
    );
  }
}
