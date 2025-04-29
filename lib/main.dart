import 'package:flutter/material.dart';
import 'package:flutter_example/SessionManager.dart';
import 'package:flutter_example/homePage.dart';
import 'login.dart';
import 'signup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
  }

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
    // SessionManager.removeSessionData();
    return Scaffold(
      backgroundColor: Color(0xFF3D0E40), // Deep purple background
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

          // Main content
          Center(
            child: Container(
              width: 350,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
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
                      Icon(Icons.pets, size: 24, color: Colors.grey[600]),
                      Icon(Icons.pets, size: 24, color: Colors.grey[600]),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Welcome Text
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF88370), // Salmon color
                    ),
                  ),
                  Text(
                    'KatBoom!',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF88370), // Salmon color
                    ),
                  ),

                  Divider(
                    color: Color(0xFFF88370).withOpacity(0.5),
                    thickness: 1,
                    height: 40,
                  ),

                  // Log In button
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF88370), // Salmon color button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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

                  // Sign Up button
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
                        backgroundColor: Color(0xFF5EBCD0), // Blue color button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Add decorative cat icon at bottom
                  SizedBox(height: 16),
                  Icon(Icons.pets, size: 30, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}