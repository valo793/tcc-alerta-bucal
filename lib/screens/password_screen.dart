import 'package:flutter/material.dart';
import '../services/password_service.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final PasswordService passwordService = PasswordService();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    bool hasPassword = await passwordService.hasPassword();
    setState(() {
      isFirstTime = !hasPassword;
    });
  }

  Future<void> _createPassword() async {
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password == confirmPassword) {
      await passwordService.savePassword(password);
      Navigator.pushReplacementNamed(context, '/site-selection');
    } else {
      _showErrorDialog('As senhas não correspondem.');
    }
  }

  // Função para autenticar a senha
  Future<void> _authenticatePassword() async {
    String password = _passwordController.text;
    bool isValid = await passwordService.validatePassword(password);

    if (isValid) {
      Navigator.pushReplacementNamed(context, '/site-selection');
    } else {
      _showErrorDialog('Senha incorreta.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      appBar: AppBar(title: const Text('Autenticação de Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isFirstTime) ...[
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Crie uma senha'),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirme a senha'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _createPassword,
                child: const Text('Criar Senha'),
              ),
            ] else ...[
              TextField(
                controller: _passwordController,
                decoration:
                    const InputDecoration(labelText: 'Digite sua senha'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _authenticatePassword,
                child: const Text('Autenticar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/passwordrecovery');
                },
                child: const Text('Esqueceu a senha?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
