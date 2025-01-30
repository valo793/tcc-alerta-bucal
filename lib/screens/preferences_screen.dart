import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_model.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final preferences = Provider.of<PreferencesModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências do Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha as suas preferências:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Switch para bloquear ou permitir YouTube
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bloquear YouTube', style: TextStyle(fontSize: 16)),
                Switch(
                  value: preferences.blockYouTube,
                  onChanged: (value) {
                    preferences.setYouTubeBlock(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Switch para bloquear ou permitir TikTok
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bloquear TikTok', style: TextStyle(fontSize: 16)),
                Switch(
                  value: preferences.blockTikTok,
                  onChanged: (value) {
                    preferences.setTikTokBlock(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Botão para confirmar as preferências
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Salvar e Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
