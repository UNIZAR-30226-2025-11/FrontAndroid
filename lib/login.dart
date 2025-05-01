import 'package:flutter/material.dart';
import 'package:flutter_example/signup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';
import 'homePage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_example/SessionManager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late IO.Socket socket;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  // FIXME: probar
  Future<void> checkSession() async {
    String? token = await SessionManager.getSessionData();
    String? username = await SessionManager
        .getUsername(); // Esperar el valor del nombre de usuario

    if (token != null) {
      // Si hay un token guardado, redirige al usuario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen()), // Pasar el username de forma segura
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkSession(); // FIXME: probar
  }

  void _showSnackBar(String message) {
    var scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
            ),
          ],
        ),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> login() async {
    final response = await http.post(
      Uri.parse('$BACKEND_URL/login'),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
      }),
    );

    final headers = response.headers;
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      var errorMessage = data.containsKey('message')
          ? data['message']
          : "Something went wrong. Try later";

      print(errorMessage);
      _showSnackBar(errorMessage);
      return;
    }

    // Let's get the header
    Map<String, String> cookies = {};
    String? setCookieHeader = response.headers['set-cookie'];

    if (setCookieHeader != null) {
      setCookieHeader.split(',').forEach((cookie) {
        var parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          cookies[parts[0].trim()] = parts[1].trim();
        }
      });
    }

    if (cookies['access_token'] != null) {
      await SessionManager.saveSessionData(cookies['access_token']!);
      await SessionManager.saveUsername(usernameController.text);
    }

    print("Login successful");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => MainScreen(

              )), // Placeholder
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Log In')),
      backgroundColor: Color(0xFF9D0514),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(12), // Bordes redondeados
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width * 0.85, // Ajuste de ancho
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: login,
                child: Text("Log In"),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
