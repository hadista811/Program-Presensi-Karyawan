import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/home-page.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/models/login-response.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late Future<String> _name, _token;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
    checkToken();
  }

  void checkToken() async {
    SharedPreferences prefs = await _prefs;
    String? tokenStr = prefs.getString("token");
    String? nameStr = prefs.getString("name");

    if (tokenStr != null && tokenStr.isNotEmpty && nameStr != null && nameStr.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      });
    }
  }

  Future<void> login(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, String> body = {"email": email, "password": password};
      var response = await myHttp.post(
        Uri.parse('http://127.0.0.1:8000/api/login'),
        body: body,
      );

      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau password salah")),
        );
      } else {
        LoginResponseModel loginResponseModel =
            LoginResponseModel.fromJson(json.decode(response.body));
        saveUser(loginResponseModel.data.token, loginResponseModel.data.name);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $error")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveUser(String token, String name) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString("name", name);
    await prefs.setString("token", token);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Image.asset(
                    "assets/office_illustration.png",
                    width: 250,
                    height: 250,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Presensi",
                  style: GoogleFonts.roboto(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Email',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Password',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          login(emailController.text, passwordController.text);
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text("Masuk"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
