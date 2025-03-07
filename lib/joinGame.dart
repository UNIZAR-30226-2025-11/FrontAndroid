import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JoinGameScreen extends StatefulWidget {
  @override
  _JoinGameState createState() => _JoinGameState();
}

class _JoinGameState extends State<JoinGameScreen> {
  final TextEditingController roomCodeController = TextEditingController();

  Future<void> joinGame() async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:3000/game'), // Replace with actual endpoint
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        //"username": usernameController.text,
        "roomCode": roomCodeController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful response
      print("Joined game successfully");
    } else {
      // Handle error
      print("Failed to join game");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Game")),
      backgroundColor: Color(0xFF9D0514),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 30),
                SizedBox(width: 8),
                Text('username', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 4),
                Text('5 coins', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextField(
                    controller: roomCodeController,
                    decoration: InputDecoration(
                      hintText: "Enter room code",
                      hintStyle: TextStyle(fontSize: 18),
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onSubmitted: (value) => joinGame(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: joinGame,
                  child: Text("Join Game"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
