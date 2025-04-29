import 'package:flutter/material.dart';
import 'package:flutter_example/lobby.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'SessionManager.dart';
import 'UserInfo.dart';

class JoinGameScreen extends StatefulWidget {
  final IO.Socket socket;

  JoinGameScreen({required this.socket});

  @override
  _JoinGameState createState() => _JoinGameState();
}

class _JoinGameState extends State<JoinGameScreen> {
  final TextEditingController roomCodeController = TextEditingController();
  String? errorMessage;

  late Future<String?> _usernameFuture;
  String username = ""; // Valor predeterminado
  int coins=-1;
  final UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await userInfo.initialize();
    setState(() {
      username = userInfo.username;
      coins = userInfo.coins;
    });
  }

  void joinGame() {
    String lobbyId = roomCodeController.text.trim();
    if (lobbyId.isEmpty) {
      setState(() => errorMessage = "Please enter a room code");
      return;
    }

    // Enviar solicitud de unión al servidor a través del socket
    widget.socket.emit(
        'join-lobby', {"error": false, "errorMsg": "", "lobbyId": lobbyId});

    // Escuchar la respuesta del servidor
    widget.socket.once('join-lobby', (data) {
      if (data["error"] == false) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WaitingScreen(
                    socket: widget.socket,
                    lobbyId: lobbyId,
                  )),
        );
      } else {
        setState(() => errorMessage = data["errorMsg"]);
      }
    });
  }

  Future<String?> _initializeUsername() async {
    try {
      final String? user = await SessionManager.getUsername();
      setState(() {
        username = user ?? ""; // Actualiza el username cuando esté disponible

      });
      return user;
    } catch (e) {
      print("Error initializing username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username error: $e"))
      );
      return "";
    }
  }

  Future<void> _initializeCoins() async {
    try {
      final String? token = await SessionManager.getSessionData();
      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      print('Current username: $username');
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Something went wrong. Try later";

        print(errorMessage);
        return;
      } else {

        // Use setState to update the UI
        setState(() {
          coins = int.parse(data['coins'].toString());
        });
        print("Found user, coins: $coins");
      }
    } catch (e) {
      print("Error initializing coins: $e");
      if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Coins error: $e"))
        );
      }
    }
  }

  // Método para abrir el drawer de perfil
  void _openProfileDrawer() {
    UserInfo.openProfileDrawer(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text("Join Game")),
      backgroundColor: Color(0xFF9D0514),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0), // Adjust as needed
            child: userInfo.buildProfileBar(context, _openProfileDrawer),
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
