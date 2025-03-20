import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static const String _passwordKey = 'user_password';

  Future<bool> hasPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordKey);
  }

  Future<void> savePassword(String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  Future<bool> validatePassword(String inputPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPassword = prefs.getString(_passwordKey);
    return savedPassword == inputPassword;
  }
}
