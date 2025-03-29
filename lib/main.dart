import 'package:flutter/material.dart';
import 'package:flutter_example/homePage.dart';
import 'login.dart';
import 'signup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen(); // Recibimos el socket

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Welcome')),
      backgroundColor: Color(0xFF9D0514),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 300,
              width: 450,
              fit: BoxFit.contain,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text('Sign Up'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Log In'),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
