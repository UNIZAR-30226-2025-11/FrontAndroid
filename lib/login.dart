import 'package:flutter/material.dart';
import 'package:flutter_example/signup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'homePage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_example/SessionManager.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late IO.Socket socket;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  Future<void> checkSession() async {
    String? token = await SessionManager.getSessionData();
    String? username = await SessionManager.getUsername();

    if (token != null) {
      // Si hay un token guardado, redirige al usuario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkSession();
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
    const URL = "http://10.0.2.2:8000/login";

    final response = await http.post(
      Uri.parse(URL),
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

    final token = await SessionManager.getSessionData();

    print("Login successful");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3D0E40), // Fondo rojo oscuro para contrastar con el signup
      body: Stack(
        children: [
          // Elementos decorativos - círculos e iconos
          ...List.generate(
            15,
                (index) => Positioned(
              left: (index * 67) % MediaQuery.of(context).size.width,
              top: (index * 83) % MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: 0.3,
                child: index % 3 == 0
                    ? Icon(Icons.circle, size: 20, color: Colors.purple[200])
                    : index % 3 == 1
                    ? Icon(Icons.album, size: 25, color: Colors.purple[300])
                    : Icon(Icons.pets, size: 20, color: Colors.red[100]),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85), // Contenedor oscuro
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Iconos en la parte superior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.pets, size: 24, color: Colors.grey[400]),
                      Icon(Icons.pets, size: 24, color: Colors.grey[400]),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Texto de Welcome Back
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF88370), // Color salmón
                    ),
                  ),

                  Divider(
                    color: Color(0xFFF88370).withOpacity(0.5),
                    thickness: 1,
                    height: 32,
                  ),

                  // Campo de usuario
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Username',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your username',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  // Campo de contraseña
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  // Botón de login
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF88370), // Botón color salmón
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Enlace para registrarse
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5EBCD0), // Botón azul
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}