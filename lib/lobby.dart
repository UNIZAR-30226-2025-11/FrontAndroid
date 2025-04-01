import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_example/game.dart';

import 'SessionManager.dart';
import 'homePage.dart';
import 'models/models.dart'; // Importa la pantalla de juego
import 'package:http/http.dart' as http;

class WaitingScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId; // Se necesita el ID del lobby

  WaitingScreen(
      {required this.socket, required this.lobbyId});

  @override
  _StartGameScreenState createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<WaitingScreen> {
  String? errorMsg; // Variable para mostrar errores
  List<PlayerLobbyJSON> players = []; // Lista de jugadores en el lobby
  Map<String, dynamic>? initialGameState;

  late Future<String?> _usernameFuture;
  String username = ""; // Valor predeterminado
  int coins=-1;

  @override
  void initState() {
    super.initState();

    // Escuchar actualizaciones del lobby
    widget.socket.on('lobby-state', (data) {
      try {
        final lobbyUpdate = BackendLobbyStateUpdateJSON.fromJson(data);
        if (lobbyUpdate.error) {
          print('Lobby update error: ${lobbyUpdate.errorMsg}');
          return;
        }

        if (lobbyUpdate.disband) {
          print('Disband');
          return;
        }

        setState(() {
          //players = lobbyUpdate.players
          players = (lobbyUpdate.players as List)
              .map((player) => PlayerLobbyJSON.fromJson(player))
              .toList();
        });
      } catch (e) {
        // Handle JSON parsing errors
        print('Error parsing lobby update: $e');
      }
    });

    widget.socket.on('game-state', (data) {
      setState(() {
        initialGameState = data;
      });
    });

    // Escuchar el evento 'start-game' para empezar el juego
    widget.socket.on('start-game', (data) {
      final Map<String, dynamic> responseData = data;

      if (responseData['error'] == false) {
        // Si no hay error, navegar a la pantalla del juego
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GameScreen(
                    socket: widget.socket,
                    lobbyId: widget.lobbyId,
                    initialGameState: initialGameState ?? {},
                    username: username,
                  )),
        );
      } else {
        // Si hay un error, mostrar un mensaje
        setState(() {
          errorMsg = responseData['errorMsg'];
        });
      }
    });
    _usernameFuture = _initializeUsername();
    _initializeCoins();
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
          Uri.parse('http://10.0.2.2:8000/users'),
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
        // Find the user with matching username
        final user = (data as List).firstWhere(
              (user) => user['username'] == username,
          orElse: () => null,
        );

        if (user != null) {
          // Use setState to update the UI
          setState(() {
            coins = int.parse(user['coins'].toString());
          });
          print("Found user, coins: $coins");
        } else {
          print("User not found in the response data");
        }
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

  @override
  void dispose() {
    widget.socket.off(
        'lobby-state'); // Detener la escucha cuando se destruye la pantalla
    widget.socket.off('start-game'); // Detener la escucha del evento start-game
    //widget.socket.off('game-state');
    widget.socket.off('game-state', (data) {
      setState(() {
        initialGameState = data;
      });
    });
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Positioned(
            top: 48,
            right: 30,
            child: Row(
              children: [
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 8),
                Text('$coins',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 30,
            child: Row(
              children: [
                SizedBox(width: 8),
                Icon(Icons.person,
                      size: 30, color: Colors.white), // Botón de perfil
                SizedBox(width: 8),
                Text(username,
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          SizedBox(height: 200),

          // 🏷️ Muestra el lobby ID en la parte superior
          Text(
            'Lobby ID: ${widget.lobbyId}',
            style: TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 80),

          // 📋 Lista de jugadores en el lobby
          Text(
            "Players in Lobby:",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),

          SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    players[index].name,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  leading: Icon(Icons.person, color: Colors.white),
                );
              },
            ),
          ),

          if (errorMsg != null) // Muestra el mensaje de error si existe
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMsg!,
                style: TextStyle(color: Colors.yellow, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              /*widget.socket.emit('leave-lobby', {
                'lobbyId': widget.lobbyId,
                'username': username,
              });*/
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF9D0514),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              'Leave Lobby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}
