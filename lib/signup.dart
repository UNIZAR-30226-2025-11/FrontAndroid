import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homePage.dart';
import 'login.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignUpScreen extends StatefulWidget {
  final IO.Socket socket;

  SignUpScreen({required this.socket});
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late IO.Socket socket;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rptPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar el socket
    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.on('connect', (_) {
      print('Conectado a Socket.IO en SignUp');
    });

    socket.on('disconnect', (_) {
      print('Desconectado de Socket.IO');
    });

    // Puedes añadir más eventos aquí si necesitas
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
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

  Future<void> signUp() async {
    if (passwordController.text != rptPasswordController.text) {
      _showSnackBar("Passwords must match!");
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print("Signup successful: ${data['message']}");
      print("Signup successful");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(socket: socket,)), // Placeholder
      );
    } else {
      //_showSnackBar("Error: ${response.body}");
      _showSnackBar("Error: failed sign up");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            TextField(
              controller: rptPasswordController,
              decoration: InputDecoration(labelText: "Repeat Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUp,
              child: Text("Sign Up"),
            ),
            SizedBox(height: 20),

            // Mensaje con "Log in" como enlace
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? "), // Texto sin enlace
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen(socket: socket)),
                    );
                  },
                  child: Text(
                    "Log in",
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
    );
  }
}
