import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesModel extends ChangeNotifier {
  bool _blockYouTube = false;
  bool _blockPluto = false;
  bool _blockKhan = false;
  bool _blockEscola = false;

  bool get blockYouTube => _blockYouTube;
  bool get blockPluto => _blockPluto;
  bool get blockKhan => _blockKhan;
  bool get blockEscola => _blockEscola;

  PreferencesModel() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _blockYouTube = prefs.getBool('blockYouTube') ?? false;
    _blockPluto = prefs.getBool('blockPluto') ?? false;
    _blockKhan = prefs.getBool('blockKhan') ?? false;
    _blockEscola = prefs.getBool('blockEscola') ?? false;
    notifyListeners();
  }

  Future<void> reloadPreferences() async {
    await _loadPreferences();
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  set blockYouTube(bool value) {
    _blockYouTube = value;
    _savePreference('blockYouTube', value);
  }

  set blockPluto(bool value) {
    _blockPluto = value;
    _savePreference('blockPluto', value);
  }

  set blockKhan(bool value) {
    _blockKhan = value;
    _savePreference('blockKhan', value);
  }

  set blockEscola(bool value) {
    _blockEscola = value;
    _savePreference('blockEscola', value);
  }
}
