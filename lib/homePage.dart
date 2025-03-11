import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_example/editProfile.dart';
import 'game.dart';
import 'statistics.dart';
import 'login.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'shop.dart';
import 'joinGame.dart';

class MainScreen extends StatefulWidget {
  final IO.Socket socket;

  MainScreen({required this.socket});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    socket = widget.socket; // Asigna el socket correctamente
  }

  void _showLogOutBar() {
    Navigator.pop(context); // Close the profile drawer before showing the SnackBar

    var scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text("Are you sure you want to log out?",
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(socket: socket,)), // Redirect to login
                );
              },
              child: Text("YES", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar(); // Dismiss the SnackBar
              },
              child: Text("NO", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        duration: Duration(days: 365), // Keeps it open until user interacts
      ),
    );
  }

  void _openProfileDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Profile Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Statistics"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsScreen()),
                  );
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Edit profile"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  );
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: _showLogOutBar,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Screen"),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      backgroundColor: Color(0xFF9D0514),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                Text('username', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 4),
                Text('5 coins', style: TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.person, size: 30, color: Colors.white), // Profile button
                  onPressed: _openProfileDrawer,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement start new game logic
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameScreen(socket: socket)),
                    );
                  },
                  child: Text("New Game"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinGameScreen()),
                    );
                  },
                  child: Text("Join Game"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ShopScreen()),
                    );
                  },
                  child: Text("Shop"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
