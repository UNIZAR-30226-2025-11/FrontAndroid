import 'package:flutter/material.dart';
import 'package:flutter_example/SessionManager.dart';
import 'package:flutter_example/config.dart';
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
      Uri.parse('$BACKEND_URL/register'),
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

    print("Signup successful");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3D0E40), // Deep purple background like the design
      body: Stack(
        children: [
          // Decorative elements - circles and icons
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
                    ? Icon(Icons.album, size: 25, color: Colors.purple[300]) // Bomb-like icon
                    : Icon(Icons.pets, size: 20, color: Colors.purple[100]), // Cat-like icon
              ),
            ),
          ),

          Center(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85), // Dark container
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
                  // Paw icons at top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.pets, size: 24, color: Colors.grey[400]),
                      Icon(Icons.pets, size: 24, color: Colors.grey[400]),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Create an Account text
                  Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF88370), // Salmon color
                    ),
                  ),

                  Divider(
                    color: Color(0xFFF88370).withOpacity(0.5),
                    thickness: 1,
                    height: 32,
                  ),

                  // Username field
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
                      hintText: 'Choose a username',
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

                  // Password field
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
                      hintText: 'Create a password',
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

                  // Confirm Password field
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Confirm Password',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: rptPasswordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
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

                  // Create Account button
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF88370), // Salmon color button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Already have an account link
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5EBCD0), // Blue color button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Already have an account? Log In',
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