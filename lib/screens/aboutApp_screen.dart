import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o AlertaBucal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'AlertaBucal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'O AlertaBucal é um aplicativo desenvolvido com o objetivo de conscientizar pais e responsáveis '
              'sobre o uso excessivo de chupetas em crianças. A aplicação foi criada a partir da observação '
              'do impacto do uso prolongado da chupeta na formação da arcada dentária e no desenvolvimento da fala.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Funcionamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'O aplicativo utiliza a câmera do dispositivo para identificar, com auxílio de inteligência artificial, '
              'se uma criança está utilizando chupeta. Quando detectado o uso, o aplicativo bloqueia temporariamente '
              'o acesso a sites de entretenimento como YouTube, Pluto TV e Khan Academy, exibindo uma mensagem educativa '
              'e incentivando a retirada da chupeta.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Tecnologias Utilizadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- Flutter\n'
              '- Biblioteca WebView\n'
              '- SharedPreferences\n'
              '- Provider\n'
              '- YOLO (You Only Look Once) para detecção de imagem',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Importância Social',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A proposta do AlertaBucal é não apenas controlar o tempo de uso de chupetas, mas também promover '
              'hábitos saudáveis desde a infância, contribuindo para o desenvolvimento bucal adequado e a saúde geral '
              'das crianças.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            Text(
              'Versão 1.0 - Projeto de Pesquisa 2025',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
