import 'package:flutter/material.dart';

class PreferencesModel with ChangeNotifier {
  bool _blockYouTube = false;
  bool _blockTikTok = false;

  bool get blockYouTube => _blockYouTube;
  bool get blockTikTok => _blockTikTok;

  void setYouTubeBlock(bool value) {
    _blockYouTube = value;
    notifyListeners(); // Notifica widgets que dependem deste valor
  }

  void setTikTokBlock(bool value) {
    _blockTikTok = value;
    notifyListeners(); // Notifica widgets que dependem deste valor
  }
}
