import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_model.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Provider.of<PreferencesModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Bloqueio'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Bloquear YouTube'),
            value: preferences.blockYouTube,
            onChanged: (value) {
              preferences.blockYouTube = value;
            },
          ),
          SwitchListTile(
            title: const Text('Bloquear Pluto Tv'),
            value: preferences.blockPluto,
            onChanged: (value) {
              preferences.blockPluto = value;
            },
          ),
          SwitchListTile(
            title: const Text('Bloquear Khan Academy'),
            value: preferences.blockKhan,
            onChanged: (value) {
              preferences.blockKhan = value;
            },
          ),
          SwitchListTile(
            title: const Text('Bloquear Escola Games'),
            value: preferences.blockEscola,
            onChanged: (value) {
              preferences.blockEscola = value;
            },
          ),
        ],
      ),
    );
  }
}
