import 'package:flutter/material.dart';
import 'package:flutter_example/SessionManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homePage.dart';
import 'login.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignUpScreen extends StatefulWidget {
  SignUpScreen();
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
    SessionManager.removeSessionData();
  }

  @override
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

    // Ver comments en login.dart/login()
    const URL = "http://10.0.2.2:8000/register";

    final response = await http.post(
      Uri.parse(URL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      var errorMessage = data.containsKey('message')
          ? data['message']
          : "Something went wrong. Try later";
      print(errorMessage);
      _showSnackBar(errorMessage);
      return;
    }

    //print("Signup successful: ${data['message']}");
    print("Signup successful");

    Navigator.pushReplacement(
      context,
      //MaterialPageRoute(builder: (context) => MainScreen(username: usernameController.text,)), // Placeholder
      MaterialPageRoute(builder: (context) => LoginScreen()), // Placeholder
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Sign Up')),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
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
      ),
    );
  }
}
