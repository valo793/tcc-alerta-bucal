import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static const String _passwordKey =
      'user_password'; // Chave para armazenar a senha

  // Verifica se já existe uma senha salva
  Future<bool> hasPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordKey);
  }

  // Salva a senha no SharedPreferences
  Future<void> savePassword(String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password); // Salva a senha
  }

  // Valida a senha digitada
  Future<bool> validatePassword(String inputPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPassword = prefs.getString(_passwordKey);
    return savedPassword ==
        inputPassword; // Compara a senha digitada com a salva
  }
}
