import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sobre o AlertaBucal',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cabeçalho
                Column(
                  children: [
                    const Icon(Icons.child_care,
                        size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 12),
                    Text(
                      'AlertaBucal',
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Um app para promover hábitos saudáveis desde cedo 🍼',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

                // Seção 1
                _buildSection(
                  icon: Icons.info_outline,
                  title: 'Propósito',
                  text:
                      'O AlertaBucal foi desenvolvido para conscientizar pais e responsáveis sobre o uso excessivo de chupetas em crianças. Ele ajuda a reduzir o impacto desse hábito no desenvolvimento da fala e na formação dentária.',
                ),

                // Seção 2
                _buildSection(
                  icon: Icons.psychology,
                  title: 'Funcionamento',
                  text:
                      'Com o auxílio de inteligência artificial, o aplicativo usa a câmera do dispositivo para detectar se uma criança está utilizando chupeta. Quando detectado o uso, o app bloqueia temporariamente sites de entretenimento como YouTube, Pluto TV e Khan Academy, exibindo uma mensagem educativa.',
                ),

                // Seção 3
                _buildSection(
                  icon: Icons.developer_mode,
                  title: 'Tecnologias Utilizadas',
                  text: '- Flutter\n'
                      '- Biblioteca WebView\n'
                      '- SharedPreferences\n'
                      '- Provider\n'
                      '- YOLO (You Only Look Once) para detecção de imagem',
                ),

                // Seção 4
                _buildSection(
                  icon: Icons.favorite,
                  title: 'Importância Social',
                  text:
                      'A proposta do AlertaBucal é promover hábitos saudáveis e reduzir o uso prolongado de chupetas, contribuindo para a saúde bucal e o bem-estar infantil.',
                ),

                // Seção 5
                _buildSection(
                  icon: Icons.tips_and_updates,
                  title: 'Como usar',
                  text:
                      '• Entre nos sites antes de dar acesso ao seu filho, para configurar o ambiente.\n'
                      '• Use as configurações para bloquear ou liberar os sites desejados.\n'
                      '• Prefira chupetas com cores que se destaquem, sem alterar o formato.\n'
                      '• Use chupetas simétricas horizontalmente para melhor reconhecimento.',
                ),

                const SizedBox(height: 24),
                // Rodapé
                Text(
                  'Versão 5.7 - Projeto de Pesquisa 2025',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Widget auxiliar para seções
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
