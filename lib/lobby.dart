import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_example/game.dart';

import 'models/models.dart'; // Importa la pantalla de juego

class WaitingScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId; // Se necesita el ID del lobby
  final String username;

  WaitingScreen({required this.socket, required this.lobbyId, required this.username});

  @override
  _StartGameScreenState createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<WaitingScreen> {
  String? errorMsg; // Variable para mostrar errores
  List<PlayerLobbyJSON> players = []; // Lista de jugadores en el lobby
  Map<String, dynamic>? initialGameState;

  late String username;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    // Escuchar actualizaciones del lobby
    widget.socket.on('update-lobby', (data) {
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
              .where((player) => player.name != username) //FIXME mostrarme como miembro del lobby?
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
          MaterialPageRoute(builder: (context) => GameScreen(socket:
          widget.socket,lobbyId: widget.lobbyId,initialGameState: initialGameState ?? {},username: username,)),
        );
      } else {
        // Si hay un error, mostrar un mensaje
        setState(() {
          errorMsg = responseData['errorMsg'];
        });
      }
    });
  }

  @override
  void dispose() {
    widget.socket.off('update-lobby'); // Detener la escucha cuando se destruye la pantalla
    widget.socket.off('start-game');  // Detener la escucha del evento start-game
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 200),

          // 🏷️ Muestra el lobby ID en la parte superior
          Text(
            'Lobby ID: ${widget.lobbyId}',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }
}
