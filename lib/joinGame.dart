import 'package:flutter/material.dart';
import 'package:flutter_example/lobby.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class JoinGameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String username;

  JoinGameScreen({required this.socket, required this.username});

  @override
  _JoinGameState createState() => _JoinGameState();
}

class _JoinGameState extends State<JoinGameScreen> {
  final TextEditingController roomCodeController = TextEditingController();
  String? errorMessage;

  void joinGame() {
    String lobbyId = roomCodeController.text.trim();
    if (lobbyId.isEmpty) {
      setState(() => errorMessage = "Please enter a room code");
      return;
    }

    // Enviar solicitud de unión al servidor a través del socket
    widget.socket.emit('join-lobby', {
      "error": false,
      "errorMsg": "",
      "lobbyId": lobbyId
    });

    // Escuchar la respuesta del servidor
    widget.socket.once('join-lobby', (data) {
      if (data["error"] == false) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingScreen(socket: widget.socket, lobbyId: lobbyId,username: widget.username,)
          ),
        );
      } else {
        setState(() => errorMessage = data["errorMsg"]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text("Join Game")),
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
                if (errorMessage != null) ...[
                  SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.yellow, fontSize: 16),
                  ),
                ],
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


