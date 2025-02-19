import 'package:flutter/material.dart';
import 'package:flutter_example/game.dart';
import 'login.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to login
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
                leading: Icon(Icons.account_circle),
                title: Text("View Profile"),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Account Settings"),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: _showLogOutBar,
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete account'),
                onTap: () {},
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
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, size: 30),
            onPressed: _openProfileDrawer,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Implement join game logic
              },
              child: Text("Join Game"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement start new game logic
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen()),
                );
              },
              child: Text("Start New Game"),
            ),
          ],
        ),
      ),
    );
  }
}
