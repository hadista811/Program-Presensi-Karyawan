import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Hapus token dari SharedPreferences
  }
}
